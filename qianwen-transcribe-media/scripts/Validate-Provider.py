#!/usr/bin/env python3
"""Enforce the single transcription backend used by this Skill."""
import argparse
import json

EXPECTED = "qianwen-web-audioread"
FORBIDDEN = ("whisper", "whisperx", "vosk", "speechrecognition", "dictation", "local", "offline")

parser = argparse.ArgumentParser()
parser.add_argument("--provider", required=True)
args = parser.parse_args()
provider = args.provider.strip().lower()

if provider != EXPECTED:
    reason = "provider-mismatch"
    if any(term in provider for term in FORBIDDEN):
        reason = "forbidden-local-or-third-party-provider"
    print(json.dumps({
        "schemaVersion": 1,
        "status": "blocked",
        "transcriptionProvider": args.provider,
        "expectedProvider": EXPECTED,
        "reason": reason,
        "message": "This Skill only permits Qianwen web Audio/Video Quick Read; do not switch providers.",
    }, ensure_ascii=False))
    raise SystemExit(20)

print(json.dumps({
    "schemaVersion": 1,
    "status": "ready",
    "transcriptionProvider": EXPECTED,
    "providerSwitching": "forbidden",
    "localTranscriptionFallback": "forbidden",
}, ensure_ascii=False))
