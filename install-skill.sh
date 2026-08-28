#!/usr/bin/env bash
set -euo pipefail

client="Auto"
destination_root=""

usage() {
  printf '%s\n' "Usage: $0 [--client Auto|TraeWork|WorkBuddy|Codex|Claude|Cursor|Agents|Custom] [--destination-root PATH]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --client)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      client="$2"
      shift 2
      ;;
    --destination-root)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      destination_root="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$client" in
  Auto|TraeWork|WorkBuddy|Codex|Claude|Cursor|Agents|Custom) ;;
  *) printf 'Unsupported client: %s\n' "$client" >&2; exit 2 ;;
esac

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$script_dir/qianwen-transcribe-media"
[ -f "$source_dir/SKILL.md" ] || { printf 'Package is incomplete: qianwen-transcribe-media/SKILL.md was not found.\n' >&2; exit 3; }

root_for_client() {
  case "$1" in
    TraeWork) printf '%s' "$HOME/.trae/skills" ;;
    WorkBuddy) printf '%s' "$HOME/.workbuddy/skills" ;;
    Codex) printf '%s' "$HOME/.codex/skills" ;;
    Claude) printf '%s' "$HOME/.claude/skills" ;;
    Cursor) printf '%s' "$HOME/.cursor/skills" ;;
    Agents) printf '%s' "$HOME/.agents/skills" ;;
  esac
}

if [ "$client" = "Custom" ]; then
  [ -n "$destination_root" ] || { printf 'Custom installation requires --destination-root.\n' >&2; exit 4; }
elif [ -n "$destination_root" ]; then
  :
elif [ "$client" = "Auto" ]; then
  detected_count=0
  detected_client=""
  for candidate in TraeWork WorkBuddy Codex Claude Cursor Agents; do
    candidate_root="$(root_for_client "$candidate")"
    if [ -d "$(dirname -- "$candidate_root")" ]; then
      detected_count=$((detected_count + 1))
      detected_client="$candidate"
      destination_root="$candidate_root"
    fi
  done
  [ "$detected_count" -gt 0 ] || { printf 'No supported AI client directory was detected. Use --client Custom --destination-root PATH.\n' >&2; exit 5; }
  [ "$detected_count" -eq 1 ] || { printf 'Multiple AI clients were detected. Select one with --client or pass --destination-root.\n' >&2; exit 6; }
  client="$detected_client"
else
  destination_root="$(root_for_client "$client")"
fi

case "$destination_root" in
  "~/"*) destination_root="$HOME/${destination_root#\~/}" ;;
esac
case "$destination_root" in
  ""|/|"$HOME")
    printf 'Refusing unsafe destination root: %s\n' "$destination_root" >&2
    exit 4
    ;;
esac
mkdir -p "$destination_root"
destination_root="$(CDPATH= cd -- "$destination_root" && pwd)"
destination="$destination_root/qianwen-transcribe-media"
if [ -e "$destination" ]; then
  backup="$destination.backup-$(date '+%Y%m%d-%H%M%S')"
  cp -R "$destination" "$backup"
  printf 'Existing skill backed up to: %s\n' "$backup"
  rm -rf "$destination"
fi

cp -R "$source_dir" "$destination"
[ -f "$destination/SKILL.md" ] || { printf 'Installation verification failed.\n' >&2; exit 7; }

printf 'Installed for client: %s\n' "$client"
printf 'Installed skill: %s\n' "$destination"
printf 'Restart or reload the AI client, then run the environment initialization template.\n'
