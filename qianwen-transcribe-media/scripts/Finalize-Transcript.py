#!/usr/bin/env python3
import argparse
import datetime
import json
import pathlib
import re
import shutil
import time

def emit(value, code):
    print(json.dumps(value, ensure_ascii=False))
    raise SystemExit(code)

parser = argparse.ArgumentParser()
parser.add_argument("--source-file", required=True)
parser.add_argument("--output-directory", required=True)
parser.add_argument("--not-before", required=True, help="ISO 8601 timestamp")
parser.add_argument("--download-directory", default=str(pathlib.Path.home() / "Downloads"))
parser.add_argument("--downloaded-file")
parser.add_argument("--wait-seconds", type=int, default=120)
args = parser.parse_args()

try:
    source = pathlib.Path(args.source_file).expanduser().resolve(strict=True)
    if not source.is_file():
        raise ValueError("source-file must be a file")
    downloads = None if args.downloaded_file else pathlib.Path(args.download_directory).expanduser().resolve(strict=True)
    downloaded_file = pathlib.Path(args.downloaded_file).expanduser().resolve() if args.downloaded_file else None
    output = pathlib.Path(args.output_directory).expanduser()
    output.mkdir(parents=True, exist_ok=True)
    output = output.resolve(strict=True)
    not_before = datetime.datetime.fromisoformat(args.not_before.replace("Z", "+00:00"))
    if not_before.tzinfo is None:
        not_before = not_before.astimezone()
    threshold = not_before.timestamp()
except (OSError, ValueError) as exc:
    emit({"status": "error", "reason": "invalid-argument", "detail": str(exc)}, 2)

pattern = re.compile(rf"^{re.escape(source.stem)}(?:\s*\(\d+\))?_原文(?:\s*\(\d+\))?\.md$")
if downloaded_file:
    if not downloaded_file.is_file():
        emit({"status": "missing-download", "source": str(source), "downloadedFile": str(downloaded_file)}, 4)
    if not pattern.match(downloaded_file.name):
        emit({"status": "invalid-download", "reason": "filename-mismatch", "downloadedFile": str(downloaded_file)}, 7)
    if downloaded_file.stat().st_mtime < threshold:
        emit({"status": "invalid-download", "reason": "file-predates-export", "downloadedFile": str(downloaded_file)}, 7)
    download = downloaded_file
else:
    deadline = time.monotonic() + max(0, args.wait_seconds)
    matches = []
    while True:
        matches = sorted(
            (item for item in downloads.glob("*.md") if pattern.match(item.name) and item.stat().st_mtime >= threshold),
            key=lambda item: item.stat().st_mtime,
            reverse=True,
        )
        if matches or time.monotonic() >= deadline:
            break
        time.sleep(2)

    if not matches:
        emit({"status": "missing-download", "source": str(source), "downloadDirectory": str(downloads)}, 4)
    if len(matches) > 1:
        emit({"status": "ambiguous-download", "candidates": [str(item) for item in matches]}, 5)
    download = matches[0]
destination = output / f"{source.stem}_原文.md"
if destination.is_file():
    emit({"status": "collision", "downloadedFile": str(download), "destination": str(destination)}, 6)
if download.stat().st_size <= 0:
    emit({"status": "invalid-download", "reason": "empty-file", "downloadedFile": str(download)}, 7)

try:
    with download.open("r", encoding="utf-8", errors="strict") as handle:
        handle.read(1)
    shutil.move(str(download), str(destination))
    stat = destination.stat()
    if stat.st_size <= 0:
        raise ValueError("destination file is empty")
except (OSError, UnicodeError, ValueError) as exc:
    emit({"status": "error", "reason": "move-or-verify-failed", "detail": str(exc)}, 8)

emit({
    "status": "completed",
    "source": str(source),
    "finalPath": str(destination),
    "bytes": stat.st_size,
    "modifiedAt": datetime.datetime.fromtimestamp(stat.st_mtime, datetime.timezone.utc).astimezone().isoformat(),
}, 0)
