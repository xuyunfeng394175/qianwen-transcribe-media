#!/usr/bin/env python3
"""Client-neutral state manager for low-token serial transcription jobs."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any


STATUSES = {"ready", "processing", "completed", "skipped", "failed", "pending", "blocked"}
TERMINAL = {"completed", "skipped", "failed", "blocked"}
EXTENSIONS = {
    ".mp3", ".wav", ".m4a", ".wma", ".aac", ".amr", ".flac", ".aiff",
    ".mp4", ".wmv", ".m4v", ".flv", ".rmvb", ".dat", ".mov", ".mkv",
    ".webm", ".avi", ".mpeg", ".mpg", ".3gp", ".ogg",
}


def timestamp() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def emit(value: dict[str, Any]) -> None:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))


def fail(reason: str, code: int = 2) -> None:
    emit({"status": "error", "reason": reason})
    raise SystemExit(code)


def atomic_write(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def paths(directory: str) -> tuple[Path, Path, Path]:
    root = Path(directory).expanduser().resolve()
    return root / "manifest.json", root / "state.json", root / "events.jsonl"


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        fail(f"missing-state-file:{path}")
    try:
        with path.open("r", encoding="utf-8") as handle:
            value = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid-state-file:{path}:{exc}")
    if not isinstance(value, dict):
        fail(f"invalid-state-shape:{path}")
    return value


def append_event(path: Path, event: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n")
        handle.flush()
        os.fsync(handle.fileno())


def claim_lock(state_directory: Path) -> Path:
    lock = state_directory / ".claim.lock"
    state_directory.mkdir(parents=True, exist_ok=True)
    try:
        lock.mkdir()
    except FileExistsError:
        try:
            age = dt.datetime.now(dt.timezone.utc).timestamp() - lock.stat().st_mtime
        except OSError:
            fail("claim-busy", 3)
        if age <= 900:
            fail("claim-busy", 3)
        try:
            lock.rmdir()
            lock.mkdir()
        except OSError:
            fail("claim-busy", 3)
    return lock


def media_files(source: Path) -> list[Path]:
    if source.is_file():
        candidates = [source]
    elif source.is_dir():
        candidates = [item for item in source.iterdir() if item.is_file()]
    else:
        fail(f"source-not-found:{source}")
    return sorted(
        (item.resolve() for item in candidates if item.suffix.lower() in EXTENSIONS),
        key=lambda item: (item.name.casefold(), str(item)),
    )


def output_for(source: Path, output_directory: Path) -> Path:
    return output_directory / f"{source.stem}_原文.md"


def create(args: argparse.Namespace) -> None:
    manifest_path, state_path, events_path = paths(args.state_directory)
    source = Path(args.source_path).expanduser().resolve()
    output = Path(args.output_directory).expanduser().resolve()
    state_root = manifest_path.parent
    if state_root == source or state_root in source.parents:
        fail("state-directory-inside-source-directory")
    output.mkdir(parents=True, exist_ok=True)
    files = media_files(source)
    if not files:
        fail("no-supported-media-files")
    if any(path.exists() for path in (manifest_path, state_path, events_path)) and not args.force:
        fail("state-directory-not-empty-use-force-or-new-job")

    job_id = args.job_id or dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    items: list[dict[str, Any]] = []
    counts = {status: 0 for status in STATUSES}
    for index, file_path in enumerate(files):
        expected = output_for(file_path, output)
        status = "skipped" if expected.is_file() and expected.stat().st_size > 0 else "ready"
        reason = "existing-output" if status == "skipped" else None
        counts[status] += 1
        stat = file_path.stat()
        items.append({
            "index": index,
            "source": str(file_path),
            "fileName": file_path.name,
            "bytes": stat.st_size,
            "mtime": dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).replace(microsecond=0).isoformat(),
            "expectedOutput": str(expected),
            "status": status,
            "reason": reason,
            "updatedAt": timestamp(),
        })

    created_at = timestamp()
    manifest = {
        "version": 1,
        "jobId": job_id,
        "createdAt": created_at,
        "sourcePath": str(source),
        "outputDirectory": str(output),
        "items": items,
    }
    state = {
        "version": 1,
        "jobId": job_id,
        "createdAt": created_at,
        "updatedAt": timestamp(),
        "currentFile": None,
        "items": {
            item["source"]: {
                "status": item["status"],
                "updatedAt": item["updatedAt"],
                "reason": item["reason"],
            }
            for item in items
        },
        "counts": counts,
    }
    atomic_write(manifest_path, manifest)
    atomic_write(state_path, state)
    append_event(events_path, {"at": timestamp(), "event": "created", "jobId": job_id, "total": len(items)})
    emit({"status": "created", "jobId": job_id, "total": len(items), "stateDirectory": str(state_root)})


def load_job(directory: str) -> tuple[Path, Path, Path, dict[str, Any], dict[str, Any]]:
    manifest_path, state_path, events_path = paths(directory)
    return manifest_path, state_path, events_path, load_json(manifest_path), load_json(state_path)


def item_map(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {item["source"]: item for item in manifest.get("items", [])}


def next_item(args: argparse.Namespace, claim: bool = False) -> None:
    _, state_path, events_path, manifest, state = load_job(args.state_directory)
    if claim:
        lock = claim_lock(Path(args.state_directory).expanduser().resolve())
        try:
            _, state_path, events_path, manifest, state = load_job(args.state_directory)
            for item in manifest.get("items", []):
                current = state.get("items", {}).get(item["source"], {})
                current_status = current.get("status", item["status"])
                if current_status != "ready" and not (args.include_pending and current_status == "pending"):
                    continue
                entry = {"status": "processing", "updatedAt": timestamp()}
                state.setdefault("items", {})[item["source"]] = entry
                state["currentFile"] = item["source"]
                state["updatedAt"] = timestamp()
                state["counts"] = counts_for(manifest, state)
                atomic_write(state_path, state)
                append_event(events_path, {"at": timestamp(), "event": "claim", "jobId": manifest["jobId"], "source": item["source"], **entry})
                emit({"status": "processing", "jobId": manifest["jobId"], "index": item["index"], "total": len(manifest.get("items", [])), "source": item["source"], "fileName": item["fileName"], "expectedOutput": item["expectedOutput"]})
                return
            emit({"status": "done", "jobId": manifest["jobId"], "total": len(manifest.get("items", []))})
        finally:
            lock.rmdir()
        return
    items = item_map(manifest)
    for item in manifest.get("items", []):
        current = state.get("items", {}).get(item["source"], {})
        if current.get("status", item["status"]) in {"ready", "processing", "pending"}:
            emit({
                "status": current.get("status", item["status"]),
                "jobId": manifest["jobId"],
                "index": item["index"],
                "total": len(items),
                "source": item["source"],
                "fileName": item["fileName"],
                "expectedOutput": item["expectedOutput"],
            })
            return
    emit({"status": "done", "jobId": manifest["jobId"], "total": len(items)})


def counts_for(manifest: dict[str, Any], state: dict[str, Any]) -> dict[str, int]:
    counts = {status: 0 for status in STATUSES}
    for item in manifest.get("items", []):
        status = state.get("items", {}).get(item["source"], {}).get("status", item["status"])
        counts[status if status in STATUSES else "blocked"] += 1
    return counts


def record(args: argparse.Namespace) -> None:
    manifest_path, state_path, events_path, manifest, state = load_job(args.state_directory)
    if args.status not in STATUSES:
        fail(f"invalid-status:{args.status}")
    items = item_map(manifest)
    source = str(Path(args.source_file).expanduser().resolve())
    if source not in items:
        fail(f"source-not-in-manifest:{source}")
    previous = state.setdefault("items", {}).setdefault(source, {})
    if previous.get("status") in TERMINAL and not args.force:
        fail(f"terminal-state-exists:{previous['status']}")
    entry = {"status": args.status, "updatedAt": timestamp()}
    if args.output_path:
        entry["outputPath"] = str(Path(args.output_path).expanduser().resolve())
    if args.reason:
        entry["reason"] = args.reason
    if args.qianwen_status:
        entry["qianwenStatus"] = args.qianwen_status
    state["items"][source] = entry
    state["currentFile"] = None if args.status in TERMINAL else source
    state["updatedAt"] = timestamp()
    state["counts"] = counts_for(manifest, state)
    atomic_write(state_path, state)
    append_event(events_path, {"at": timestamp(), "event": "record", "jobId": manifest["jobId"], "source": source, **entry})
    emit({"status": "recorded", "jobId": manifest["jobId"], "source": source, "newStatus": args.status, "counts": state["counts"]})


def summary(args: argparse.Namespace) -> None:
    _, _, _, manifest, state = load_job(args.state_directory)
    counts = counts_for(manifest, state)
    current_file = state.get("currentFile")
    emit({
        "jobId": manifest["jobId"],
        "total": len(manifest.get("items", [])),
        **{key: counts[key] for key in ("completed", "skipped", "failed", "pending", "blocked", "processing", "ready")},
        "currentFile": current_file,
        "updatedAt": state.get("updatedAt"),
    })


def lease(args: argparse.Namespace) -> None:
    root = Path(args.state_directory).expanduser().resolve()
    lease_path = root / "lease.json"
    if args.action == "clear":
        lease_path.unlink(missing_ok=True)
        emit({"status": "lease-cleared"})
        return
    if args.action == "write":
        if not args.platform or not args.client or not args.browser_debug:
            fail("lease-write-requires-platform-client-browser-debug")
        expires = dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=args.hours)
        value = {
            "version": 1,
            "platform": args.platform,
            "client": args.client,
            "browserDebug": args.browser_debug,
            "debugEndpoint": args.debug_endpoint,
            "userDataDirectory": args.user_data_directory,
            "environmentCheckedAt": timestamp(),
            "capabilitiesCheckedAt": timestamp(),
            "expiresAt": expires.replace(microsecond=0).isoformat(),
        }
        atomic_write(lease_path, value)
        emit({"status": "lease-written", "expiresAt": value["expiresAt"], "path": str(lease_path)})
        return
    if not lease_path.is_file():
        emit({"status": "missing"})
        return
    value = load_json(lease_path)
    try:
        expires = dt.datetime.fromisoformat(value["expiresAt"])
        valid = expires > dt.datetime.now(dt.timezone.utc)
    except (KeyError, ValueError, TypeError):
        valid = False
    emit({"status": "valid" if valid else "expired", "expiresAt": value.get("expiresAt"), "platform": value.get("platform"), "client": value.get("client"), "browserDebug": value.get("browserDebug")})


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description=__doc__)
    sub = root.add_subparsers(dest="command", required=True)
    create_parser = sub.add_parser("create")
    create_parser.add_argument("--source-path", required=True)
    create_parser.add_argument("--output-directory", required=True)
    create_parser.add_argument("--state-directory", required=True)
    create_parser.add_argument("--job-id")
    create_parser.add_argument("--force", action="store_true")
    create_parser.set_defaults(function=create)

    next_parser = sub.add_parser("next")
    next_parser.add_argument("--state-directory", required=True)
    next_parser.set_defaults(function=next_item)

    claim_parser = sub.add_parser("claim")
    claim_parser.add_argument("--state-directory", required=True)
    claim_parser.add_argument("--include-pending", action="store_true")
    claim_parser.set_defaults(function=lambda args: next_item(args, claim=True))

    record_parser = sub.add_parser("record")
    record_parser.add_argument("--state-directory", required=True)
    record_parser.add_argument("--source-file", required=True)
    record_parser.add_argument("--status", required=True)
    record_parser.add_argument("--output-path")
    record_parser.add_argument("--reason")
    record_parser.add_argument("--qianwen-status")
    record_parser.add_argument("--force", action="store_true")
    record_parser.set_defaults(function=record)

    summary_parser = sub.add_parser("status")
    summary_parser.add_argument("--state-directory", required=True)
    summary_parser.set_defaults(function=summary)

    lease_parser = sub.add_parser("lease")
    lease_parser.add_argument("action", choices=("read", "write", "clear"), nargs="?", default="read")
    lease_parser.add_argument("--state-directory", required=True)
    lease_parser.add_argument("--platform")
    lease_parser.add_argument("--client")
    lease_parser.add_argument("--browser-debug")
    lease_parser.add_argument("--debug-endpoint")
    lease_parser.add_argument("--user-data-directory")
    lease_parser.add_argument("--hours", type=float, default=4)
    lease_parser.set_defaults(function=lease)
    return root


def main() -> None:
    args = parser().parse_args()
    try:
        args.function(args)
    except (OSError, KeyError, ValueError) as exc:
        fail(f"operation-failed:{exc}")


if __name__ == "__main__":
    main()
