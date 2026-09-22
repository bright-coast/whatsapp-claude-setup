#!/usr/bin/env bash
# Delete downloaded media older than N days from the project's media/ folder.
# Only files inside media/ are touched. Messages stored by wacli are not affected.
# Usage: bash scripts/prune-media.sh 30
set -euo pipefail
DAYS="${1:-30}"
case "$DAYS" in
  ''|*[!0-9]*) echo "usage: prune-media.sh <days>" >&2; exit 2 ;;
esac
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEDIA="$ROOT/media"
if [ ! -d "$MEDIA" ]; then
  echo "no media folder yet, nothing to delete"
  exit 0
fi
COUNT="$(find "$MEDIA" -type f -mtime +"$DAYS" | wc -l | tr -d ' ')"
find "$MEDIA" -type f -mtime +"$DAYS" -delete
find "$MEDIA" -mindepth 1 -type d -empty -delete 2>/dev/null || true
echo "deleted $COUNT file(s) older than $DAYS days from media/"
