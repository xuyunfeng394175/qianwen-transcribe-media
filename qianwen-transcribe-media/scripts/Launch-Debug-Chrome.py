#!/usr/bin/env python3
"""Launch an isolated Chromium profile with a verified CDP endpoint."""

import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import time
import urllib.request


def emit(value, code=0):
    print(json.dumps(value, ensure_ascii=False))
    raise SystemExit(code)


def find_browser(explicit):
    if explicit:
        path = pathlib.Path(explicit).expanduser()
        if path.is_file():
            return str(path.resolve())
        emit({"status": "blocked", "reason": "browser-not-found", "browserPath": str(path)}, 2)

    candidates = []
    if sys.platform == "win32":
        local = os.environ.get("LOCALAPPDATA", "")
        program = os.environ.get("PROGRAMFILES", r"C:\Program Files")
        program_x86 = os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)")
        candidates.extend([
            pathlib.Path(local) / "Google/Chrome/Application/chrome.exe",
            pathlib.Path(program) / "Google/Chrome/Application/chrome.exe",
            pathlib.Path(program_x86) / "Google/Chrome/Application/chrome.exe",
        ])
    elif sys.platform == "darwin":
        candidates.extend([
            pathlib.Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
            pathlib.Path.home() / "Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        ])
    else:
        for name in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser"):
            found = shutil.which(name)
            if found:
                candidates.append(pathlib.Path(found))

    for candidate in candidates:
        if candidate.is_file():
            return str(candidate.resolve())
    emit({"status": "blocked", "reason": "chrome-not-found"}, 2)


def endpoint(port):
    url = f"http://127.0.0.1:{port}/json/version"
    try:
        with urllib.request.urlopen(url, timeout=1.5) as response:
            return json.loads(response.read().decode("utf-8"))
    except (OSError, ValueError, UnicodeError):
        return None


def default_user_data_directories():
    home = pathlib.Path.home().resolve()
    if sys.platform == "win32":
        local = pathlib.Path(os.environ.get("LOCALAPPDATA", home / "AppData/Local"))
        return {(local / "Google/Chrome/User Data").resolve()}
    if sys.platform == "darwin":
        return {(home / "Library/Application Support/Google/Chrome").resolve()}
    return {
        (home / ".config/google-chrome").resolve(),
        (home / ".config/chromium").resolve(),
    }


parser = argparse.ArgumentParser()
parser.add_argument("--browser-path")
parser.add_argument("--user-data-dir", required=True)
parser.add_argument("--debug-port", type=int, default=9222)
parser.add_argument("--url", default="https://www.qianwen.com/discover/audioread")
parser.add_argument("--wait-seconds", type=float, default=10)
args = parser.parse_args()

if not 1024 <= args.debug_port <= 65535:
    emit({"status": "blocked", "reason": "invalid-debug-port"}, 2)

udd = pathlib.Path(args.user_data_dir).expanduser().resolve()
if udd == pathlib.Path.home().resolve() or udd in default_user_data_directories():
    emit({
        "status": "blocked",
        "reason": "unsafe-user-data-directory",
        "detail": "UDD must be a dedicated directory, not a home or everyday Chrome profile.",
        "userDataDirectory": str(udd),
    }, 2)
udd.mkdir(parents=True, exist_ok=True)

existing = endpoint(args.debug_port)
if existing:
    emit({
        "status": "existing-endpoint",
        "debugEndpoint": f"http://127.0.0.1:{args.debug_port}",
        "userDataDirectory": str(udd),
        "browserProcess": "not-started",
        "version": existing,
    })

browser = find_browser(args.browser_path)
command = [
    browser,
    f"--remote-debugging-port={args.debug_port}",
    f"--user-data-dir={udd}",
    "--profile-directory=Default",
    "--no-first-run",
    "--no-default-browser-check",
    args.url,
]
try:
    process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except OSError as exc:
    emit({"status": "blocked", "reason": "browser-launch-failed", "detail": str(exc)}, 3)

deadline = time.monotonic() + max(0, args.wait_seconds)
info = None
while time.monotonic() < deadline:
    info = endpoint(args.debug_port)
    if info:
        break
    if process.poll() is not None:
        emit({"status": "blocked", "reason": "browser-exited-before-cdp", "exitCode": process.returncode}, 4)
    time.sleep(0.25)

if not info:
    emit({"status": "blocked", "reason": "cdp-endpoint-unavailable", "pid": process.pid, "userDataDirectory": str(udd)}, 5)

emit({
    "status": "started",
    "debugEndpoint": f"http://127.0.0.1:{args.debug_port}",
    "userDataDirectory": str(udd),
    "browserProcess": "started-by-script",
    "pid": process.pid,
    "version": info,
})
