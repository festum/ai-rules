#!/usr/bin/env python3
"""POST GraphQL to Wiz. Auto-loads ~/.wiz_session and refreshes cookie via CDP on need/401."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_AUTH_URL = "https://auth.app.wiz.io/oauth/token"
DEFAULT_ENDPOINT = "https://api.eu16.app.wiz.io/graphql"
DEFAULT_SESSION = Path.home() / ".wiz_session"
SCRIPT_DIR = Path(__file__).resolve().parent
CDP_SCRIPT = SCRIPT_DIR / "wiz_cookie_from_cdp.py"


def _strip_header_prefix(value: str, name: str) -> str:
    prefix = f"{name}:"
    if value.lower().startswith(prefix):
        return value[len(prefix) :].strip()
    return value


def _load_env_file(path: Path) -> None:
    """Load export KEY=VALUE lines into os.environ if key not already set."""
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        if key in os.environ and os.environ[key].strip():
            continue
        if (val.startswith("'") and val.endswith("'")) or (val.startswith('"') and val.endswith('"')):
            val = val[1:-1]
        os.environ[key] = val


def _ensure_session_env() -> None:
    _load_env_file(DEFAULT_SESSION)
    # Optional leftovers; do not override ~/.wiz_session
    rc = Path.home() / ".rc_local"
    if rc.is_file():
        # only pull WIZ_* if still missing
        text = rc.read_text(encoding="utf-8", errors="replace")
        for raw in text.splitlines():
            m = re.match(r"^(?:export\s+)?(WIZ_[A-Za-z0-9_]*)=(.*)$", raw.strip())
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            if key in os.environ and os.environ[key].strip():
                continue
            if (val.startswith("'") and val.endswith("'")) or (val.startswith('"') and val.endswith('"')):
                val = val[1:-1]
            os.environ[key] = val


def _refresh_cookie_from_cdp(endpoint: str) -> bool:
    if not CDP_SCRIPT.is_file():
        print(f"CDP helper missing: {CDP_SCRIPT}", file=sys.stderr)
        return False
    cmd = [
        sys.executable,
        str(CDP_SCRIPT),
        "--out",
        str(DEFAULT_SESSION),
        "--endpoint",
        endpoint,
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as exc:
        err = (exc.stderr or exc.stdout or "").strip()
        print("CDP cookie refresh failed.", file=sys.stderr)
        if err:
            print(err[:1500], file=sys.stderr)
        print(
            "Debug Chrome was started/checked automatically. "
            "If wiz-app cookie is missing, complete SSO once in that Chrome window "
            "(profile ~/.chrome-wiz-debug), then retry.",
            file=sys.stderr,
        )
        return False
    # Reload session into this process
    for key in ("WIZ_COOKIE", "WIZ_GQL_ENDPOINT"):
        os.environ.pop(key, None)
    _load_env_file(DEFAULT_SESSION)
    return bool(os.environ.get("WIZ_COOKIE", "").strip())


def _oauth_bearer() -> str | None:
    client_id = os.environ.get("WIZ_CLIENT_ID", "").strip()
    client_secret = os.environ.get("WIZ_CLIENT_SECRET", "").strip()
    if not client_id or not client_secret:
        return None

    auth_url = os.environ.get("WIZ_AUTH_URL", DEFAULT_AUTH_URL).strip() or DEFAULT_AUTH_URL
    body = urllib.parse.urlencode(
        {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
            "audience": "wiz-api",
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        auth_url,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        err = exc.read().decode("utf-8", errors="replace")
        print(f"OAuth HTTP {exc.code}", file=sys.stderr)
        print(err[:2000], file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as exc:
        print(f"OAuth request failed: {exc.reason}", file=sys.stderr)
        sys.exit(1)

    token = payload.get("access_token")
    if not token:
        print("OAuth response missing access_token", file=sys.stderr)
        sys.exit(1)
    return f"Bearer {token}"


def _auth_header() -> dict[str, str]:
    headers: dict[str, str] = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    origin = os.environ.get("WIZ_ORIGIN", "").strip()
    referer = os.environ.get("WIZ_REFERER", "").strip()
    if origin:
        headers["Origin"] = origin
    if referer:
        headers["Referer"] = referer

    bearer = _oauth_bearer()
    if bearer:
        headers["Authorization"] = bearer
        return headers

    token = _strip_header_prefix(os.environ.get("WIZ_TOKEN", "").strip(), "Authorization")
    if token:
        if not token.lower().startswith("bearer "):
            token = f"Bearer {token}"
        headers["Authorization"] = token
        return headers

    cookie = _strip_header_prefix(os.environ.get("WIZ_COOKIE", "").strip(), "Cookie")
    if cookie:
        headers["Cookie"] = cookie
        return headers

    print("Missing auth after session/CDP load", file=sys.stderr)
    sys.exit(2)


def _post(endpoint: str, payload: dict) -> tuple[int, str]:
    headers = _auth_header()
    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return resp.status, resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return exc.code, body


def main() -> int:
    parser = argparse.ArgumentParser(description="Wiz GraphQL helper (auto session/CDP)")
    parser.add_argument("--file", "-f", help="GraphQL query/mutation file (default: stdin)")
    parser.add_argument("--variables", "-V", default=None, help="Variables JSON string")
    parser.add_argument("--variables-file", default=None, help="Variables JSON file")
    parser.add_argument("--endpoint", default=None, help="Override WIZ_GQL_ENDPOINT")
    parser.add_argument(
        "--no-cdp-refresh",
        action="store_true",
        help="Do not auto-refresh cookie via Chrome CDP",
    )
    parser.add_argument(
        "--allow-errors",
        action="store_true",
        help="Exit 0 even when GraphQL errors are present",
    )
    args = parser.parse_args()

    _ensure_session_env()

    endpoint = (args.endpoint or os.environ.get("WIZ_GQL_ENDPOINT", "") or DEFAULT_ENDPOINT).strip()
    os.environ.setdefault("WIZ_GQL_ENDPOINT", endpoint)

    has_sa = bool(os.environ.get("WIZ_CLIENT_ID") and os.environ.get("WIZ_CLIENT_SECRET"))
    has_token = bool(os.environ.get("WIZ_TOKEN", "").strip())
    has_cookie = bool(os.environ.get("WIZ_COOKIE", "").strip())

    if not args.no_cdp_refresh and not has_sa and not has_token:
        # Always refresh from live Chrome when possible so callers need not source env.
        if not _refresh_cookie_from_cdp(endpoint) and not has_cookie:
            return 2

    if args.file:
        with open(args.file, encoding="utf-8") as fh:
            query = fh.read()
    else:
        query = sys.stdin.read()
    query = query.strip()
    if not query:
        print("Empty GraphQL document", file=sys.stderr)
        return 2

    variables = None
    if args.variables_file:
        with open(args.variables_file, encoding="utf-8") as fh:
            variables = json.load(fh)
    elif args.variables:
        variables = json.loads(args.variables)

    payload: dict = {"query": query}
    if variables is not None:
        payload["variables"] = variables

    status, body = _post(endpoint, payload)

    # One automatic CDP retry on unauthorized cookie session
    if status in (401, 403) and not args.no_cdp_refresh and not has_sa:
        print(f"HTTP {status}; refreshing cookie via CDP and retrying once", file=sys.stderr)
        if _refresh_cookie_from_cdp(endpoint):
            status, body = _post(endpoint, payload)

    if status >= 400:
        print(f"HTTP {status}", file=sys.stderr)
        print(body[:4000], file=sys.stderr)
        return 1

    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        print(f"HTTP {status}: non-JSON body", file=sys.stderr)
        print(body[:4000], file=sys.stderr)
        return 1

    # GraphQL-layer unauthorized sometimes returns 200 + errors
    if not args.no_cdp_refresh and not has_sa:
        errs = parsed.get("errors") or []
        if any(
            (e.get("extensions") or {}).get("code") in {"UNAUTHORIZED", "FORBIDDEN"}
            or "unauthorized" in str(e.get("message", "")).lower()
            for e in errs
        ):
            print("GraphQL auth error; refreshing cookie via CDP and retrying once", file=sys.stderr)
            if _refresh_cookie_from_cdp(endpoint):
                status, body = _post(endpoint, payload)
                if status >= 400:
                    print(f"HTTP {status}", file=sys.stderr)
                    print(body[:4000], file=sys.stderr)
                    return 1
                try:
                    parsed = json.loads(body)
                except json.JSONDecodeError:
                    print(f"HTTP {status}: non-JSON body", file=sys.stderr)
                    print(body[:4000], file=sys.stderr)
                    return 1

    print(json.dumps(parsed, indent=2, ensure_ascii=False))

    if parsed.get("errors") and not args.allow_errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
