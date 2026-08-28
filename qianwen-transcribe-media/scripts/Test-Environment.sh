#!/usr/bin/env bash
set -u

skill_directory="${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"

if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' '{"schemaVersion":1,"overallStatus":"fixable","checks":[{"name":"python-3.9+","ok":false,"required":true,"fixable":true,"detail":"python3 is unavailable"}],"requiredActions":["python-3.9+"],"note":"Install Python 3.9 or later, then rerun this check. The AI client must separately verify browser and local-file-upload capabilities."}'
  exit 10
fi

python3 - "$skill_directory" <<'PY'
import datetime
import json
import os
import pathlib
import platform
import shutil
import socket
import ssl
import subprocess
import sys

skill_dir = pathlib.Path(sys.argv[1]).expanduser().resolve()
checks = []
actions = []

def add(name, ok, required, detail, fixable=False):
    checks.append({"name": name, "ok": bool(ok), "required": required, "fixable": fixable, "detail": str(detail)})
    if not ok and fixable:
        actions.append(name)

system = platform.system()
supported = system in {"Darwin", "Linux"}
add("supported-os", supported, True, f"{system} {platform.release()}")
py_ok = sys.version_info >= (3, 9)
add("python-3.9+", py_ok, True, platform.python_version(), True)

required_files = [
    "SKILL.md",
    "references/client-capabilities.md",
    "scripts/Test-Environment.sh",
    "scripts/Setup-Environment.sh",
    "scripts/Preflight-Media.py",
    "scripts/Finalize-Transcript.py",
]
missing = [name for name in required_files if not (skill_dir / name).is_file()]
add("skill-files", not missing, True, f"Missing: {', '.join(missing)}" if missing else skill_dir)

downloads = pathlib.Path.home() / "Downloads"
add("downloads-directory", downloads.is_dir(), True, downloads, True)
write_ok = False
if downloads.is_dir():
    probe = downloads / f".ai-client-env-{os.getpid()}.tmp"
    try:
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
        write_ok = True
    except OSError:
        pass
add("downloads-writable", write_ok, True, downloads, True)

network_ok = False
try:
    with socket.create_connection(("www.qianwen.com", 443), timeout=8) as raw:
        with ssl.create_default_context().wrap_socket(raw, server_hostname="www.qianwen.com"):
            network_ok = True
except OSError:
    pass
add("qianwen-https", network_ok, True, "www.qianwen.com:443")

ffprobe = shutil.which("ffprobe")
package_manager = shutil.which("brew") or shutil.which("apt-get") or shutil.which("dnf") or shutil.which("pacman")
add("package-manager", bool(package_manager), False, package_manager or "Optional; needed for assisted dependency installation")
add("ffprobe", bool(ffprobe), False, ffprobe or "Optional; enables local duration validation", bool(package_manager))

process_text = ""
try:
    process_text = subprocess.run(["ps", "-ax", "-o", "comm="], capture_output=True, text=True, timeout=5).stdout.lower()
except (OSError, subprocess.SubprocessError):
    pass
known = [name for name in ("trae", "workbuddy", "codex", "claude", "cursor") if name in process_text]
add("ai-client-diagnostic", bool(known), False, f"Running client candidates: {', '.join(known)}" if known else "No known client process detected; the active AI must report its capabilities")

required_failures = [check for check in checks if check["required"] and not check["ok"]]
status = "ready" if not required_failures else ("fixable" if all(check["fixable"] for check in required_failures) else "blocked")
result = {
    "schemaVersion": 1,
    "checkedAt": datetime.datetime.now(datetime.timezone.utc).astimezone().isoformat(),
    "platform": system,
    "overallStatus": status,
    "checks": checks,
    "requiredActions": actions,
    "note": "The active AI client must separately verify command execution, browser navigation, page inspection and interaction, local file upload, bounded waits, local downloads, and user takeover.",
}
print(json.dumps(result, ensure_ascii=False))
raise SystemExit(0 if status == "ready" else 10 if status == "fixable" else 20)
PY
