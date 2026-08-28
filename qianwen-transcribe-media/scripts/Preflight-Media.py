#!/usr/bin/env python3
import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

VIDEO_EXTENSIONS = {".mp4", ".wmv", ".m4v", ".flv", ".rmvb", ".dat", ".mov", ".mkv", ".webm", ".avi", ".mpeg", ".3gp", ".ogg"}
AUDIO_EXTENSIONS = {".mp3", ".wav", ".m4a", ".wma", ".aac", ".ogg", ".amr", ".flac", ".aiff"}

def emit(value, code):
    print(json.dumps(value, ensure_ascii=False))
    raise SystemExit(code)

parser = argparse.ArgumentParser()
parser.add_argument("--source-path", required=True)
parser.add_argument("--output-directory", required=True)
args = parser.parse_args()

source = pathlib.Path(args.source_path).expanduser()
try:
    source = source.resolve(strict=True)
except OSError:
    emit({"status": "error", "reason": "source-not-found", "source": str(source)}, 2)

output = pathlib.Path(args.output_directory).expanduser()
try:
    output.mkdir(parents=True, exist_ok=True)
    output = output.resolve(strict=True)
    with tempfile.NamedTemporaryFile(dir=output, prefix=".write-probe-", delete=True):
        pass
except OSError as exc:
    emit({"status": "error", "reason": "output-not-writable", "detail": str(exc)}, 3)

files = sorted((item for item in source.iterdir() if item.is_file()), key=lambda item: item.name) if source.is_dir() else [source]
ffprobe = shutil.which("ffprobe")
items = []
for media in files:
    extension = media.suffix.lower()
    is_video = extension in VIDEO_EXTENSIONS
    is_audio = extension in AUDIO_EXTENSIONS
    expected = output / f"{media.stem}_原文.md"
    status = "ready"
    reason = None
    duration = None
    size = media.stat().st_size

    if not (is_video or is_audio):
        status, reason = "unsupported", "unsupported-extension"
    elif extension == ".ogg" and size > 500 * 1024 * 1024:
        status, reason = "unsupported", "ogg-over-conservative-500MB-limit"
    elif is_video and size > 6 * 1024 * 1024 * 1024:
        status, reason = "unsupported", "video-over-6GB"
    elif is_audio and not is_video and size > 500 * 1024 * 1024:
        status, reason = "unsupported", "audio-over-500MB"
    elif expected.is_file():
        status, reason = "existing-output", "destination-exists"

    if ffprobe and status == "ready":
        try:
            completed = subprocess.run(
                [ffprobe, "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(media)],
                capture_output=True,
                text=True,
                timeout=30,
                check=True,
            )
            duration = float(completed.stdout.strip())
            if is_video and duration > 21600:
                status, reason = "unsupported", "video-over-6-hours"
        except (OSError, ValueError, subprocess.SubprocessError):
            duration = None

    items.append({
        "source": str(media),
        "fileName": media.name,
        "bytes": size,
        "durationSeconds": duration,
        "expectedOutput": str(expected),
        "status": status,
        "reason": reason,
    })

emit({"status": "ok", "source": str(source), "outputDirectory": str(output), "items": items}, 0)
