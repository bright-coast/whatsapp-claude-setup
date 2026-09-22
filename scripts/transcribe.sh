#!/usr/bin/env bash
# Transcribe one or more audio/video files locally. Works on Mac, Linux and Git Bash on Windows.
# Usage: bash scripts/transcribe.sh media/2026-09-19/<MsgID>.ogg
# Set up once with: bash scripts/setup-transcription.sh
set -euo pipefail
VENV="${WA_VENV:-$HOME/.wa-agent-venv}"
if [ -x "$VENV/bin/python" ]; then
  PY="$VENV/bin/python"
elif [ -x "$VENV/Scripts/python.exe" ]; then
  PY="$VENV/Scripts/python.exe"
else
  echo "Transcription is not set up yet. Run: bash scripts/setup-transcription.sh" >&2
  exit 2
fi
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$PY" "$DIR/transcribe.py" "$@"
