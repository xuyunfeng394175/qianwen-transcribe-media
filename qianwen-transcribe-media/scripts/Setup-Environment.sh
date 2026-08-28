#!/usr/bin/env bash
set -euo pipefail

install_python=false
install_ffmpeg=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-python) install_python=true ;;
    --install-ffmpeg) install_ffmpeg=true ;;
    -h|--help)
      printf '%s\n' "Usage: $0 [--install-python] [--install-ffmpeg]"
      exit 0
      ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

system="$(uname -s)"
case "$system" in
  Darwin|Linux) ;;
  *) printf 'Unsupported operating system: %s\n' "$system" >&2; exit 20 ;;
esac

mkdir -p "$HOME/Downloads"

install_with_brew() {
  formula="$1"
  command -v brew >/dev/null 2>&1 || return 1
  brew install "$formula"
}

install_on_linux() {
  package="$1"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "$package"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "$package"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm "$package"
  else
    return 1
  fi
}

install_package() {
  package="$1"
  if [ "$system" = "Darwin" ]; then
    install_with_brew "$package"
  else
    install_on_linux "$package"
  fi
}

python_ready=false
if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' 2>/dev/null; then
  python_ready=true
fi

if $install_python && ! $python_ready; then
  python_package="python3"
  [ "$system" = "Darwin" ] && python_package="python"
  if ! install_package "$python_package"; then
    printf '%s\n' 'Python installation is blocked: no supported package manager is available. Install Python 3.9+ from an official source.' >&2
    exit 10
  fi
fi

if $install_ffmpeg && ! command -v ffprobe >/dev/null 2>&1; then
  if ! install_package ffmpeg; then
    printf '%s\n' 'FFmpeg installation is blocked: no supported package manager is available. Install FFmpeg from an official source.' >&2
    exit 10
  fi
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$script_dir/Test-Environment.sh" "$(dirname -- "$script_dir")"
