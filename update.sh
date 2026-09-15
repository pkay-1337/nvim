#!/usr/bin/env bash
# Smart-update plugins for this Neovim config.
# Usage:
#   ./update.sh --check   # read-only: report what's behind, change nothing
#   ./update.sh           # update branch-tracked plugins, refresh everything else
#
# Policy:
#   TRACKED (fast-forward): nvim-treesitter@main, which-key.nvim@main
#   PINNED (never touched): tags (blink.cmp, nvim-tree, telescope) and frozen
#     SHAs (friendly-snippets, gruvbox, lspconfig, man, devicons, plenary, lazydev).
#     To move a pinned plugin, checkout the ref in its dir manually, test, then
#     run this script to refresh versions.txt + setup.sh.
# After moving anything it: rebuilds helptags, :TSUpdate's parsers, refreshes
# pack/versions.txt, and smoke-tests. Review + commit the result yourself.

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_DIR="$CONFIG_DIR/pack/vendor/start"
OPT_DIR="$CONFIG_DIR/pack/vendor/opt"
VERSIONS="$CONFIG_DIR/pack/versions.txt"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Tracked branches: "name:branch:dir"
TRACKED=(
  "nvim-treesitter:main:$START_DIR/nvim-treesitter"
  "which-key.nvim:main:$START_DIR/which-key.nvim"
)

# Pinned: "name:ref:dir" (ref = tag or SHA, informational in --check)
PINNED=(
  "blink.cmp:v1.10.2:$START_DIR/blink.cmp"
  "friendly-snippets:6cd7280:$START_DIR/friendly-snippets"
  "gruvbox.nvim:154eb5f:$START_DIR/gruvbox.nvim"
  "nvim-lspconfig:16286347:$START_DIR/nvim-lspconfig"
  "nvim-man:7fe6b3b:$START_DIR/nvim-man"
  "nvim-tree.lua:v1:$START_DIR/nvim-tree.lua"
  "nvim-web-devicons:5f032a8:$START_DIR/nvim-web-devicons"
  "plenary.nvim:74b06c6:$START_DIR/plenary.nvim"
  "telescope.nvim:v0.2.2:$START_DIR/telescope.nvim"
  "lazydev.nvim:ff2cbcb:$OPT_DIR/lazydev.nvim"
)

MOVED=0

if [ "$CHECK_ONLY" = 1 ]; then
  log "Check mode: reporting, changing nothing."
  for entry in "${TRACKED[@]}"; do
    IFS=: read -r name branch dir <<< "$entry"
    git -C "$dir" fetch -q origin 2>/dev/null || { warn "$name: fetch failed"; continue; }
    local_sha="$(git -C "$dir" rev-parse --short HEAD)"
    remote_sha="$(git -C "$dir" rev-parse --short "origin/$branch")"
    if [ "$local_sha" = "$remote_sha" ]; then
      printf '  %-18s up to date (%s)\n' "$name" "$local_sha"
    else
      printf '  %-18s BEHIND %s -> %s\n' "$name" "$local_sha" "$remote_sha"
    fi
  done
  for entry in "${PINNED[@]}"; do
    IFS=: read -r name ref dir <<< "$entry"
    git -C "$dir" fetch -q --tags origin 2>/dev/null || true
    latest_tag="$(git -C "$dir" tag --sort=-v:refname 2>/dev/null | head -n1)"
    printf '  %-18s pinned %s (current %s, newest tag %s)\n' \
      "$name" "$ref" "$(git -C "$dir" rev-parse --short HEAD)" "${latest_tag:-n/a}"
  done
  exit 0
fi

log "Fast-forwarding tracked plugins..."
# Snapshot current pins first: rollback.sh can restore this exact state.
# Snapshots are local-only (gitignored), pruned to the newest 10.
SNAP_DIR="$CONFIG_DIR/pack/snapshots"
mkdir -p "$SNAP_DIR"
cp "$VERSIONS" "$SNAP_DIR/versions-$(date +%Y%m%d-%H%M%S).txt"
ls -t "$SNAP_DIR"/versions-*.txt 2>/dev/null | tail -n +11 | xargs -r rm --
for entry in "${TRACKED[@]}"; do
  IFS=: read -r name branch dir <<< "$entry"
  before="$(git -C "$dir" rev-parse --short HEAD)"
  git -C "$dir" fetch -q origin || { warn "$name: fetch failed, skipping"; continue; }
  git -C "$dir" checkout -q "$branch" 2>/dev/null || warn "$name: checkout $branch failed"
  if git -C "$dir" merge -q --ff-only "origin/$branch" 2>/dev/null; then
    after="$(git -C "$dir" rev-parse --short HEAD)"
    if [ "$before" = "$after" ]; then
      printf '  %-18s already current (%s)\n' "$name" "$after"
    else
      printf '  %-18s %s -> %s\n' "$name" "$before" "$after"
      MOVED=1
    fi
  else
    warn "$name: not fast-forwardable (local changes?). Resolve manually in $dir"
  fi
done

log "Rebuilding helptags..."
for d in "$START_DIR"/*/ "$OPT_DIR"/*/; do
  [ -d "${d}doc" ] || continue
  nvim --headless -c "helptags ${d}doc" -c "q" >/dev/null 2>&1 || warn "helptags failed for $d"
done

log "Updating treesitter parsers (:TSUpdate)..."
timeout 280 nvim --headless -c "TSUpdate" -c "q" 2>&1 | tail -n 4 \
  || warn "TSUpdate had errors; run :TSUpdate inside nvim, see :checkhealth nvim-treesitter"

log "Refreshing pack/versions.txt..."
: > "$VERSIONS"
for d in "$START_DIR"/*/ "$OPT_DIR"/*/; do
  [ -d "$d/.git" ] || continue
  n="$(basename "$d")"
  sha="$(git -C "$d" rev-parse --short HEAD)"
  tag="$(git -C "$d" describe --tags 2>/dev/null || echo HEAD)"
  printf '%s: %s %s\n' "$n" "$sha" "$tag" >> "$VERSIONS"
done
cat "$VERSIONS"

log "Smoke-testing config..."
nvim --headless \
  -c "lua require('config.options'); require('config.plugins'); require('config.keymaps'); print('config OK')" \
  -c "q" 2>&1 || warn "config failed to load; run nvim and check :messages"

if [ "$MOVED" = 1 ]; then
  log "Plugins moved. Review, then commit:"
  echo "  git -C $CONFIG_DIR diff --stat; git -C $CONFIG_DIR status --short"
  echo "  git -C $CONFIG_DIR add pack/versions.txt setup.sh && git -C $CONFIG_DIR commit -m \"Update tracked plugins\""
else
  log "Nothing moved. versions.txt refreshed."
fi
