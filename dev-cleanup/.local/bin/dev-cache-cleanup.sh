#!/usr/bin/env bash
# User-level cache cleanup: pip, cargo, npm, and general ~/.cache report.
# Runs as your normal user — no root needed, safe to run unattended.

set -uo pipefail

LOG_TAG="dev-cache-cleanup"
log() { echo "[$LOG_TAG] $*"; }

# --- pip ---
if command -v pip >/dev/null 2>&1; then
  log "purging pip cache"
  pip cache purge 2>/dev/null || log "pip cache purge failed or nothing to purge"
  uv cache purge 2>/dev/null || log "uv cache purge failed or nothing to purge"
fi

# --- cargo ---
if command -v cargo-cache >/dev/null 2>&1; then
  log "running cargo-cache autoclean"
  rm -rf ~/.cargo/registry/cache
  rm -rf ~/.cargo/registry/src
elif [[ -d "$HOME/.cargo/registry" ]]; then
  log "cargo-cache not installed, manually clearing registry cache/src"
  rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src"
fi

# --- npm ---
if command -v npm >/dev/null 2>&1; then
  log "cleaning npm cache"
  npm cache clean --force >/dev/null 2>&1
fi

# --- yarn ---
if command -v yarn >/dev/null 2>&1; then
  log "cleaning yarn cache"
  yarn cache clean >/dev/null 2>&1
fi

log "done"
