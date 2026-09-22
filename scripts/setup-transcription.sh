#!/usr/bin/env bash
# One-time setup of local voice-note transcription. Mac, Linux, or Git Bash on Windows.
# Creates a private Python environment at ~/.wa-agent-venv, installs faster-whisper, and downloads the model.
# Written from the docs for Mac: untested on a Mac until Rob or a client runs it.
set -euo pipefail
VENV="${WA_VENV:-$HOME/.wa-agent-venv}"
MODEL="${WA_WHISPER_MODEL:-small}"

PYBIN="$(command -v python3 || command -v python || true)"
if [ -z "$PYBIN" ]; then
  echo "Python 3 was not found." >&2
  echo "On a Mac: run 'xcode-select --install' (a window will offer to install the Command Line Tools), wait for it to finish, then run this again." >&2
  exit 1
fi
if ! "$PYBIN" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'; then
  echo "Python 3.9 or newer is needed. Found: $("$PYBIN" --version 2>&1)" >&2
  exit 1
fi

if [ ! -d "$VENV" ]; then
  echo "Creating a private Python environment at $VENV ..."
  "$PYBIN" -m venv "$VENV"
fi
if [ -x "$VENV/bin/python" ]; then PY="$VENV/bin/python"; else PY="$VENV/Scripts/python.exe"; fi

echo "Installing faster-whisper (pinned to a version tested on Windows) ..."
"$PY" -m pip install --quiet --upgrade pip
"$PY" -m pip install --quiet "faster-whisper==1.2.1"

echo "Downloading the '$MODEL' speech model the first time (small is about 460 MB) ..."
WA_WHISPER_MODEL="$MODEL" "$PY" - <<'PYEOF'
import os
from faster_whisper import WhisperModel
WhisperModel(os.environ["WA_WHISPER_MODEL"], device="cpu", compute_type="int8")
print("model ready")
PYEOF

echo "Transcription is ready. Test it with: bash scripts/transcribe.sh <audio file>"
