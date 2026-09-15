#!/usr/bin/env bash
# Roll plugins back to recorded SHAs when something breaks.
# Usage:
#   ./rollback.sh --list        # show available snapshots (newest first)
#   ./rollback.sh               # restore from pack/versions.txt
#   ./rollback.sh <snapshot>    # restore from pack/snapshots/<snapshot>
#
# Typical flows:
#   bad plugin update?  ./update.sh broke things  -> ./rollback.sh <latest-snapshot>
#   bad config edit?    lua files broke           -> git checkout -- lua/ init.lua
#   bad commit?         committed + pushed junk   -> git revert HEAD && git push
#   old machine state?  want last committed pins -> git show HEAD:pack/versions.txt > /tmp/v.txt && ./rollback.sh /tmp/v.txt
#
# Accepts a snapshot name or any versions.txt-format file path.

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_DIR="$CONFIG_DIR/pack/vendor/start"
OPT_DIR="$CONFIG_DIR/pack/vendor/opt"
VERSIONS="$CONFIG_DIR/pack/versions.txt"
SNAP_DIR="$CONFIG_DIR/pack/snapshots"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; exit 1; }

if [ "${1:-}" = "--list" ]; then
  ls -t "$SNAP_DIR"/versions-*.txt 2>/dev/null || echo "no snapshots yet (created by update.sh)"
  exit 0
fi

SRC="$VERSIONS"
if [ $# -ge 1 ]; then
  if [ -f "$SNAP_DIR/$1" ]; then SRC="$SNAP_DIR/$1"
  elif [ -f "$1" ]; then SRC="$1"
  else die "no such snapshot or file: $1 (see ./rollback.sh --list)"
  fi
fi
[ -f "$SRC" ] || die "missing $SRC; run ./setup.sh first"

find_dir() {  # plugin name -> its pack dir (start or opt)
  if [ -d "$START_DIR/$1/.git" ]; then printf '%s' "$START_DIR/$1"
  elif [ -d "$OPT_DIR/$1/.git" ]; then printf '%s' "$OPT_DIR/$1"
  fi
}

log "Restoring plugins from $SRC ..."
TS_CHANGED=0
while read -r name sha _rest; do
  name="${name%:}"; [ -n "${name:-}" ] || continue
  case "$name" in \#*) continue;; esac
  dir="$(find_dir "$name")"
  [ -n "$dir" ] || { warn "$name: not installed, skipping (run ./setup.sh)"; continue; }
  before="$(git -C "$dir" rev-parse --short HEAD)"
  if [ "$before" = "$sha" ]; then
    printf '  %-18s already %s\n' "$name" "$sha"
    continue
  fi
  git -C "$dir" fetch -q origin 2>/dev/null || true
  if git -C "$dir" checkout -q "$sha" 2>/dev/null; then
    printf '  %-18s %s -> %s\n' "$name" "$before" "$sha"
    [ "$name" = "nvim-treesitter" ] && TS_CHANGED=1
    [ "$name" = "blink.cmp" ] && BLINK_CHANGED=1
  else
    warn "$name: cannot checkout $sha (not fetched?). Try ./setup.sh"
  fi
done < "$SRC"

# blink fuzzy binary matches blink source; rebuild if blink moved or .so missing.
if [ "${BLINK_CHANGED:-0}" = 1 ] || [ ! -f "$START_DIR/blink.cmp/target/release/libblink_cmp_fuzzy.so" ]; then
  if command -v cargo >/dev/null 2>&1; then
    log "Rebuilding blink.cmp fuzzy matcher..."
    (cd "$START_DIR/blink.cmp" && cargo build --release) \
      || warn "blink build failed; set fuzzy={implementation=\"lua\"} in lua/config/plugins.lua"
  else
    warn "no cargo: cannot rebuild blink matcher"
  fi
fi

# Treesitter parsers pin to the plugin commit; re-sync if it moved.
if [ "$TS_CHANGED" = 1 ]; then
  log "Treesitter moved, re-syncing parsers (:TSUpdate)..."
  timeout 280 nvim --headless -c "TSUpdate" -c "q" 2>&1 | tail -n 4 \
    || warn "TSUpdate had errors; run :TSUpdate inside nvim"
fi

log "Rebuilding helptags..."
for d in "$START_DIR"/*/ "$OPT_DIR"/*/; do
  [ -d "${d}doc" ] || continue
  nvim --headless -c "helptags ${d}doc" -c "q" >/dev/null 2>&1 || warn "helptags failed for $d"
done

log "Smoke-testing config..."
nvim --headless \
  -c "lua require('config.options'); require('config.plugins'); require('config.keymaps'); print('config OK')" \
  -c "q" 2>&1 || die "config still broken; check :messages inside nvim"

log "Rolled back to $SRC. If lua/ files (not plugins) are the problem:"
echo "  git -C $CONFIG_DIR checkout -- lua/ init.lua     # discard uncommitted config edits"
echo "  git -C $CONFIG_DIR revert HEAD && git push       # undo a committed change"
