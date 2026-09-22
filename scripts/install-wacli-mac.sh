#!/usr/bin/env bash
# install-wacli-mac.sh: install the latest wacli on a Mac, with a SHA-256 check.
#
# STATUS: UNTESTED ON A MAC. Written from wacli's install docs, its Homebrew formula and the
# release's SIGNING-MANIFEST.json. The download, checksum and extract steps were run on Windows
# under Git Bash (with the test overrides below) on 19 Sep 2026. Nothing here was run on a Mac.
#
# Usage:   bash install-wacli-mac.sh
#
# What it does:
#   1. Asks GitHub which wacli release is the latest (it never assumes a version).
#   2. If Homebrew is already installed, runs: brew install openclaw/tap/wacli
#      (the Homebrew formula pins the SHA-256 of the download, and Homebrew checks it).
#      Otherwise downloads the darwin tar.gz for this chip and checks its SHA-256 against the
#      release's checksums.txt. A mismatch deletes the download and stops.
#   3. Checks the code signature (team identifier of the OpenClaw Foundation) if `codesign` exists.
#   4. Prints lines that start with "RESULT:" so the outcome is easy to read.
# It never installs Homebrew and never edits a shell file.
#
# Optional environment overrides (mainly for testing):
#   WACLI_ROUTE=auto|brew|tarball   default auto
#   WACLI_INSTALL_DIR=<folder>      tarball route only, default $HOME/.local/bin
#   WACLI_DOWNLOAD_DIR=<folder>     tarball route only, default $HOME/WhatsAppAgent/downloads
#   WACLI_SKIP_OS_CHECK=1           test hook only: allow running on something that is not a Mac

set -eu

REPO="openclaw/wacli"
EXPECTED_TEAM_ID="FWJYW4S8P8"   # OpenClaw Foundation, from the release's SIGNING-MANIFEST.json
ROUTE="${WACLI_ROUTE:-auto}"
DEST="${WACLI_INSTALL_DIR:-$HOME/.local/bin}"
WORK="${WACLI_DOWNLOAD_DIR:-$HOME/WhatsAppAgent/downloads}"

say() { printf '%s\n' "$*"; }
die() { printf 'STOP: %s\n' "$*" >&2; exit 1; }

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# verify_sha256 <file> <expected hash>: succeeds only if the hash is not empty and matches.
verify_sha256() {
  local file="$1" expected="$2" actual
  [ -n "$expected" ] || return 1
  actual="$(sha256_of "$file")"
  [ "$actual" = "$expected" ]
}

# latest_tag: prints the tag of the latest release, for example v0.18.2
latest_tag() {
  local json
  json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")" || return 1
  printf '%s\n' "$json" | sed -nE 's/.*"tag_name": *"([^"]+)".*/\1/p' | sed -n '1p'
}

route_brew() {
  say "Installing with Homebrew (Homebrew checks the SHA-256 of the download itself)."
  brew install openclaw/tap/wacli
  BIN="$(command -v wacli || true)"
  if [ -z "$BIN" ]; then BIN="$(brew --prefix)/bin/wacli"; fi
  [ -x "$BIN" ] || die "Homebrew finished, but wacli was not found at $BIN."
  CHECKSUM="homebrew-automatic"
}

route_tarball() {
  local arch file base expected
  case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64)        arch="amd64" ;;
    *) die "Unknown chip type: $(uname -m)" ;;
  esac
  file="wacli_${VER}_darwin_${arch}.tar.gz"
  base="https://github.com/$REPO/releases/download/$TAG"
  mkdir -p "$WORK" "$DEST"
  cd "$WORK"
  say "Downloading $file and checksums.txt ..."
  curl -fsSL -o "$file" "$base/$file"
  curl -fsSL -o checksums.txt "$base/checksums.txt"
  expected="$(awk -v f="$file" '$2 == f { print $1 }' checksums.txt)"
  say "expected SHA-256: ${expected:-<none found>}"
  say "actual SHA-256:   $(sha256_of "$file")"
  if ! verify_sha256 "$file" "$expected"; then
    rm -f "$file"
    die "The SHA-256 does not match the release's checksums.txt. The download was deleted and nothing was installed."
  fi
  say "SHA-256 matches."
  rm -rf extract
  mkdir extract
  tar -xzf "$file" -C extract
  [ -f extract/wacli ] || die "The archive did not contain a file called wacli."
  cp extract/wacli "$DEST/wacli"
  chmod 755 "$DEST/wacli"
  BIN="$DEST/wacli"
  CHECKSUM="verified"
}

main() {
  if [ "$(uname -s)" != "Darwin" ] && [ "${WACLI_SKIP_OS_CHECK:-}" != "1" ]; then
    die "This script is for a Mac (uname -s says $(uname -s)). On Windows use install-wacli-windows.ps1."
  fi

  TAG="$(latest_tag)"
  [ -n "$TAG" ] || die "Could not read the latest wacli release from GitHub."
  VER="${TAG#v}"
  say "Latest wacli release: $TAG"

  if [ "$ROUTE" = "auto" ]; then
    if command -v brew >/dev/null 2>&1; then ROUTE="brew"; else ROUTE="tarball"; fi
  fi
  case "$ROUTE" in
    brew)    route_brew ;;
    tarball) route_tarball ;;
    *) die "WACLI_ROUTE must be auto, brew or tarball (got: $ROUTE)" ;;
  esac

  # Code signature (the release's signing manifest names this team identifier).
  if command -v codesign >/dev/null 2>&1; then
    if codesign -dv --verbose=2 "$BIN" 2>&1 | grep -q "TeamIdentifier=$EXPECTED_TEAM_ID"; then
      SIGNATURE="confirmed"
    else
      SIGNATURE="unconfirmed"
    fi
  else
    SIGNATURE="skipped-no-codesign"
  fi

  if [ "$(uname -s)" = "Darwin" ]; then
    INSTALLED="$("$BIN" --version 2>&1 || true)"
  else
    INSTALLED="(not run: this is not a Mac)"
  fi
  case "$INSTALLED" in
    *"$VER"*) MATCH="yes" ;;
    *)        MATCH="no" ;;
  esac
  case ":$PATH:" in
    *":$(dirname "$BIN"):"*) ONPATH="yes" ;;
    *)                       ONPATH="no" ;;
  esac

  say ""
  say "RESULT: route=$ROUTE"
  say "RESULT: latest_release=$TAG"
  say "RESULT: installed_path=$BIN"
  say "RESULT: installed_version=$INSTALLED"
  say "RESULT: installed_matches_latest=$MATCH"
  say "RESULT: checksum=$CHECKSUM"
  say "RESULT: signature=$SIGNATURE"
  say "RESULT: install_folder_on_this_shells_PATH=$ONPATH"
}

# Run main only when executed, not when sourced (so the functions can be tested).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
