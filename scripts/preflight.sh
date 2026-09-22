#!/usr/bin/env bash
# preflight.sh: what is publicly known right now about wacli pairing problems.
# Reads public GitHub pages only (no login) and prints short, filtered output.
#
# Usage: bash preflight.sh
#
# STATUS: the GitHub calls and filters were run on Windows under Git Bash on 19 Sep 2026.
# Not run on a Mac (it only needs curl, sed, grep, which a Mac has).

set -u

api() { curl -fsSL "https://api.github.com/$1" 2>/dev/null; }
keep() { grep -E '"(number|title|state|updated_at)":' | sed -E 's/^ +//'; }

echo "== wacli installed on this computer"
if command -v wacli >/dev/null 2>&1; then wacli --version; else echo "(wacli is not on this shell's PATH)"; fi

echo
echo "== Latest wacli release on GitHub"
REL="$(api repos/openclaw/wacli/releases/latest)"
if [ -z "$REL" ]; then
  echo "(could not reach GitHub)"
else
  printf '%s\n' "$REL" | grep -E '"(tag_name|published_at|prerelease)":' | sed -E 's/^ +//'
  echo
  echo "== Lines of the release notes that mention pairing, auth, passkey, QR or login"
  printf '%s\n' "$REL" | grep '"body":' | sed -e 's/\\r//g' -e 's/\\n/\n/g' | grep -i -E 'auth|pair|passkey|link|qr|login' || echo "(none)"
fi

for term in pair passkey QR; do
  echo
  echo "== Open wacli issues that mention: $term  (number, title, state, last updated)"
  RES="$(api "search/issues?q=repo:openclaw/wacli+is:issue+is:open+$term&per_page=10")"
  if [ -z "$RES" ]; then echo "(could not reach GitHub)"; else printf '%s\n' "$RES" | keep | paste - - - - ; fi
done

echo
echo "== wacli issue 355 (passkey-gated accounts cannot pair)"
api repos/openclaw/wacli/issues/355 | keep | sed -n '1,4p'
echo
echo "== wacli issue 365 (some groups have little or no text after a fresh link)"
api repos/openclaw/wacli/issues/365 | keep | sed -n '1,4p'
echo
echo "== whatsmeow issue 1267 (source of: unsupported QR pairing state)"
api repos/tulir/whatsmeow/issues/1267 | keep | sed -n '1,4p'
