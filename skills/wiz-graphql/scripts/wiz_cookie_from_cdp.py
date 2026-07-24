#!/usr/bin/env python3
"""Pull Wiz session cookies from a Chrome DevTools (CDP) endpoint and write ~/.wiz_session.

Requires Chrome started with e.g.:
  --remote-debugging-port=9222
  --user-data-dir="$HOME/.chrome-wiz-debug"

Never prints cookie values.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import select
import socket
import struct
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


DEFAULT_CDP = "http://127.0.0.1:9222"
DEFAULT_OUT = Path.home() / ".wiz_session"
DEFAULT_ENDPOINT = "https://api.eu16.app.wiz.io/graphql"
COOKIE_NAMES = ("wiz-app", "wiz-dc")
URL_HINTS = ("wiz.io",)
SCRIPT_DIR = Path(__file__).resolve().parent


class CdpError(RuntimeError):
    pass


class SimpleWs:
    """Minimal RFC6455 client for CDP text frames."""

    def __init__(self, ws_url: str, timeout: float = 10.0) -> None:
        parsed = urlparse(ws_url)
        if parsed.scheme not in {"ws", "wss"}:
            raise CdpError(f"unsupported ws scheme: {parsed.scheme}")
        host = parsed.hostname or "127.0.0.1"
        port = parsed.port or (443 if parsed.scheme == "wss" else 80)
        path = parsed.path or "/"
        if parsed.query:
            path = f"{path}?{parsed.query}"

        if parsed.scheme == "wss":
            import ssl

            raw = socket.create_connection((host, port), timeout=timeout)
            ctx = ssl.create_default_context()
            self.sock = ctx.wrap_socket(raw, server_hostname=host)
        else:
            self.sock = socket.create_connection((host, port), timeout=timeout)

        key = base64.b64encode(os.urandom(16)).decode("ascii")
        req = (
            f"GET {path} HTTP/1.1\r\n"
            f"Host: {host}:{port}\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n"
            "\r\n"
        )
        self.sock.sendall(req.encode("ascii"))
        header = b""
        while b"\r\n\r\n" not in header:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise CdpError("CDP websocket handshake closed early")
            header += chunk
        status_line = header.split(b"\r\n", 1)[0].decode("ascii", errors="replace")
        if "101" not in status_line:
            raise CdpError(f"CDP websocket upgrade failed: {status_line}")
        expected = base64.b64encode(
            hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode("ascii")).digest()
        ).decode("ascii")
        if expected.encode("ascii") not in header:
            raise CdpError("CDP websocket accept mismatch")
        self._buf = header.split(b"\r\n\r\n", 1)[1]
        self._next_id = 1

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass

    def _mask(self, data: bytes) -> bytes:
        mask = os.urandom(4)
        return mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data))

    def send_json(self, payload: dict[str, Any]) -> None:
        data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        header = bytearray([0x81])  # text, FIN
        n = len(data)
        if n < 126:
            header.append(0x80 | n)
        elif n < 65536:
            header.append(0x80 | 126)
            header.extend(struct.pack("!H", n))
        else:
            header.append(0x80 | 127)
            header.extend(struct.pack("!Q", n))
        self.sock.sendall(bytes(header) + self._mask(data))

    def _recv_exact(self, n: int) -> bytes:
        while len(self._buf) < n:
            chunk = self.sock.recv(max(4096, n - len(self._buf)))
            if not chunk:
                raise CdpError("CDP websocket closed")
            self._buf += chunk
        out, self._buf = self._buf[:n], self._buf[n:]
        return out

    def recv_json(self, timeout: float = 10.0) -> dict[str, Any]:
        self.sock.settimeout(timeout)
        while True:
            b0 = self._recv_exact(1)[0]
            b1 = self._recv_exact(1)[0]
            opcode = b0 & 0x0F
            masked = bool(b1 & 0x80)
            length = b1 & 0x7F
            if length == 126:
                length = struct.unpack("!H", self._recv_exact(2))[0]
            elif length == 127:
                length = struct.unpack("!Q", self._recv_exact(8))[0]
            mask = self._recv_exact(4) if masked else b""
            data = self._recv_exact(length)
            if masked:
                data = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
            if opcode == 0x8:  # close
                raise CdpError("CDP websocket closed by peer")
            if opcode == 0x9:  # ping -> pong
                # ignore keepalives
                continue
            if opcode != 0x1:
                continue
            return json.loads(data.decode("utf-8"))

    def call(self, method: str, params: dict[str, Any] | None = None, timeout: float = 10.0) -> Any:
        msg_id = self._next_id
        self._next_id += 1
        payload: dict[str, Any] = {"id": msg_id, "method": method}
        if params is not None:
            payload["params"] = params
        self.send_json(payload)
        deadline = timeout
        while deadline > 0:
            # drain events until matching id
            ready, _, _ = select.select([self.sock], [], [], min(1.0, deadline))
            if not ready and not self._buf:
                deadline -= 1.0
                continue
            msg = self.recv_json(timeout=max(1.0, deadline))
            if msg.get("id") == msg_id:
                if "error" in msg:
                    raise CdpError(f"{method}: {msg['error']}")
                return msg.get("result")
        raise CdpError(f"timeout waiting for {method}")


def _http_json(url: str) -> Any:
    with urllib.request.urlopen(url, timeout=5) as resp:
        return json.loads(resp.read().decode("utf-8"))


def pick_ws_url(cdp_http: str) -> str:
    base = cdp_http.rstrip("/")
    try:
        targets = _http_json(f"{base}/json/list")
    except (urllib.error.URLError, TimeoutError) as exc:
        raise CdpError(
            f"cannot reach CDP at {base} ({exc}). "
            "Start Chrome with --remote-debugging-port=9222"
        ) from exc

    pages = [t for t in targets if t.get("type") == "page" and t.get("webSocketDebuggerUrl")]
    preferred = [
        t
        for t in pages
        if any(h in (t.get("url") or "").lower() for h in URL_HINTS)
    ]
    chosen = preferred[0] if preferred else (pages[0] if pages else None)
    if not chosen:
        raise CdpError("no Chrome page targets found on CDP")
    return chosen["webSocketDebuggerUrl"]


def cookies_to_header(cookies: list[dict[str, Any]]) -> str:
    wanted = []
    by_name = {c.get("name"): c.get("value") for c in cookies if c.get("name")}
    for name in COOKIE_NAMES:
        if name in by_name and by_name[name]:
            wanted.append(f"{name}={by_name[name]}")
    # keep other wiz-related cookies if present
    for c in cookies:
        name = c.get("name") or ""
        if name in COOKIE_NAMES:
            continue
        if "wiz" in name.lower() and c.get("value"):
            wanted.append(f"{name}={c['value']}")
    if "wiz-app" not in by_name:
        raise CdpError(
            "wiz-app cookie not found. Open https://app.wiz.io in the debug Chrome and log in."
        )
    return "; ".join(wanted)


def write_session(path: Path, endpoint: str, cookie_header: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = (
        f"export WIZ_GQL_ENDPOINT={json.dumps(endpoint)}\n"
        f"export WIZ_COOKIE={json.dumps(cookie_header)}\n"
    )
    path.write_text(content, encoding="utf-8")
    os.chmod(path, 0o600)


def _ensure_chrome(cdp: str) -> None:
    ensure_py = SCRIPT_DIR / "wiz_ensure_chrome.py"
    if not ensure_py.is_file():
        return
    # Import sibling module without requiring package install
    import importlib.util

    spec = importlib.util.spec_from_file_location("wiz_ensure_chrome", ensure_py)
    if spec is None or spec.loader is None:
        return
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    ok = mod.ensure_chrome(cdp=cdp)
    if not ok:
        raise CdpError(
            f"cannot start or reach CDP at {cdp}. "
            "Check Chrome install / WIZ_CHROME_BIN."
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Export Wiz cookies from Chrome CDP")
    parser.add_argument("--cdp", default=os.environ.get("WIZ_CDP", DEFAULT_CDP))
    parser.add_argument("--out", type=Path, default=Path(os.environ.get("WIZ_SESSION_FILE", DEFAULT_OUT)))
    parser.add_argument(
        "--endpoint",
        default=os.environ.get("WIZ_GQL_ENDPOINT", DEFAULT_ENDPOINT),
    )
    parser.add_argument(
        "--print-names",
        action="store_true",
        help="Print cookie names + value lengths only",
    )
    parser.add_argument(
        "--no-ensure-chrome",
        action="store_true",
        help="Do not auto-start debug Chrome when CDP is down",
    )
    args = parser.parse_args()

    if not args.no_ensure_chrome:
        _ensure_chrome(args.cdp)

    ws_url = pick_ws_url(args.cdp)
    ws = SimpleWs(ws_url)
    try:
        # Network.getCookies across wiz hosts
        result = ws.call(
            "Network.getCookies",
            {
                "urls": [
                    "https://app.wiz.io",
                    "https://api.eu16.app.wiz.io",
                    "https://api.app.wiz.io",
                ]
            },
        )
        cookies = result.get("cookies") or []
        if args.print_names:
            for c in cookies:
                val = c.get("value") or ""
                print(f"{c.get('name')} len={len(val)} domain={c.get('domain')}")
        header = cookies_to_header(cookies)
        write_session(args.out, args.endpoint, header)
        print(
            f"wrote {args.out} (mode 600); "
            f"cookie_names={sorted({c.get('name') for c in cookies if c.get('name')})}"
        )
        return 0
    finally:
        ws.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CdpError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
