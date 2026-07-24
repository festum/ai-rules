#!/usr/bin/env python3
"""Ensure debug Chrome with CDP is running; start it in the background if not."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_CDP = "http://127.0.0.1:9222"
DEFAULT_PORT = 9222
DEFAULT_USER_DATA = Path.home() / ".chrome-wiz-debug"
DEFAULT_URL = "https://app.wiz.io"
CHROME_CANDIDATES = (
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "google-chrome",
    "chromium",
    "chromium-browser",
)


def cdp_ready(cdp: str, timeout: float = 1.5) -> bool:
    try:
        with urllib.request.urlopen(f"{cdp.rstrip('/')}/json/version", timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        return bool(data.get("Browser") or data.get("webSocketDebuggerUrl"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return False


def find_chrome() -> str:
    override = os.environ.get("WIZ_CHROME_BIN", "").strip()
    if override:
        return override
    for path in CHROME_CANDIDATES:
        if "/" in path:
            if Path(path).is_file():
                return path
        else:
            import shutil

            found = shutil.which(path)
            if found:
                return found
    raise RuntimeError(
        "Chrome not found. Set WIZ_CHROME_BIN or install Google Chrome."
    )


def start_chrome(cdp: str, user_data: Path, url: str, port: int) -> None:
    chrome = find_chrome()
    user_data.mkdir(parents=True, exist_ok=True)
    cmd = [
        chrome,
        f"--remote-debugging-port={port}",
        f"--user-data-dir={user_data}",
        "--no-first-run",
        "--no-default-browser-check",
        url,
    ]
    # Detach so caller can continue
    subprocess.Popen(
        cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def wait_cdp(cdp: str, seconds: float = 30.0) -> bool:
    deadline = time.time() + seconds
    while time.time() < deadline:
        if cdp_ready(cdp):
            return True
        time.sleep(0.4)
    return False


def ensure_chrome(
    cdp: str = DEFAULT_CDP,
    user_data: Path = DEFAULT_USER_DATA,
    url: str = DEFAULT_URL,
    port: int = DEFAULT_PORT,
    wait_seconds: float = 30.0,
) -> bool:
    if cdp_ready(cdp):
        print(f"CDP already up: {cdp}", file=sys.stderr)
        return True
    print(f"CDP down; starting Chrome on port {port} ...", file=sys.stderr)
    start_chrome(cdp, user_data, url, port)
    if wait_cdp(cdp, wait_seconds):
        print(f"CDP ready: {cdp}", file=sys.stderr)
        return True
    print(f"CDP still not ready after {wait_seconds:.0f}s: {cdp}", file=sys.stderr)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Ensure Wiz debug Chrome/CDP is running")
    parser.add_argument("--cdp", default=os.environ.get("WIZ_CDP", DEFAULT_CDP))
    parser.add_argument(
        "--user-data-dir",
        type=Path,
        default=Path(os.environ.get("WIZ_CHROME_USER_DATA", DEFAULT_USER_DATA)),
    )
    parser.add_argument("--url", default=os.environ.get("WIZ_CHROME_URL", DEFAULT_URL))
    parser.add_argument("--port", type=int, default=int(os.environ.get("WIZ_CDP_PORT", DEFAULT_PORT)))
    parser.add_argument("--wait", type=float, default=30.0)
    args = parser.parse_args()
    ok = ensure_chrome(args.cdp, args.user_data_dir, args.url, args.port, args.wait)
    return 0 if ok else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
