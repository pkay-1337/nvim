#!/usr/bin/env bash
# Bootstrap this Neovim config on a fresh system.
# Usage:
#   git clone <your-config-repo> ~/.config/nvim
#   ~/.config/nvim/setup.sh
#
# What it does:
#   1. checks system dependencies (nvim 0.12+, compilers, tools, LSP servers)
#   2. clones/updates every plugin in pack/vendor/{start,opt} to its pinned ref
#   3. builds blink.cmp's fuzzy matcher (needs cargo/rustc)
#   4. rebuilds :helptags for all plugins
#   5. installs treesitter parsers (needs tree-sitter-cli)
#   6. smoke-tests the config headless
# Safe to re-run: it enforces the pinned state instead of duplicating work.

set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_DIR="$CONFIG_DIR/pack/vendor/start"
OPT_DIR="$CONFIG_DIR/pack/vendor/opt"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mXX\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. System dependencies
# ---------------------------------------------------------------------------
log "Checking system dependencies..."

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing '$1'. $2"
}

need git "install git first."
need nvim "needs Neovim 0.12+. On Arch: sudo pacman -S neovim"
need cc "needs a C compiler. On Arch: sudo pacman -S base-devel"
need curl "needed by nvim-treesitter downloads."
need tar "needed by nvim-treesitter downloads."

# Optional-but-expected tools: warn, don't die (config degrades gracefully).
for tool in rg xclip clangd clang-format tree-sitter cargo; do
  case "$tool" in
    rg)           hint="sudo pacman -S ripgrep (telescope live-grep)" ;;
    xclip)        hint="sudo pacman -S xclip (system clipboard; needs X)" ;;
    clangd)       hint="sudo pacman -S clang (C/C++ completions)" ;;
    clang-format) hint="sudo pacman -S clang (C/C++ formatting)" ;;
    tree-sitter)  hint="sudo pacman -S tree-sitter-cli (builds treesitter parsers)" ;;
    cargo)        hint="sudo pacman -S rust (builds blink.cmp fuzzy matcher)" ;;
  esac
  command -v "$tool" >/dev/null 2>&1 || warn "missing '$tool'. $hint"
done
command -v bear >/dev/null 2>&1 || warn "missing 'bear'. Only needed for Makefile projects (compile_commands.json). sudo pacman -S bear"

# Neovim version gate: 0.12+ required (vim.lsp.config API, new treesitter).
NVIM_VER="$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
NVIM_MAJOR="${NVIM_VER%%.*}"; NVIM_MINOR="${NVIM_VER##*.}"
if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
  die "found Neovim $NVIM_VER, need 0.12+. Upgrade neovim first."
fi
log "Neovim $NVIM_VER OK"

# ---------------------------------------------------------------------------
# 2. Plugins (pinned refs from pack/versions.txt)
# ---------------------------------------------------------------------------
mkdir -p "$START_DIR" "$OPT_DIR"

# clone_or_update <name> <url> <ref> <destdir>
# <ref> is a tag, branch, or full commit SHA. Enforces exact state.
clone_or_update() {
  local name="$1" url="$2" ref="$3" dest="$4"
  if [ -d "$dest/.git" ]; then
    log "$name: exists, enforcing $ref"
    git -C "$dest" fetch --tags origin >/dev/null 2>&1 || warn "$name: fetch failed (offline?), keeping current checkout"
    git -C "$dest" checkout -q "$ref" 2>/dev/null || die "$name: cannot checkout $ref"
  else
    log "$name: cloning $url @ $ref"
    git clone -q "$url" "$dest" || die "$name: clone failed"
    git -C "$dest" checkout -q "$ref" || die "$name: cannot checkout $ref"
  fi
  printf '  %-18s %s\n' "$name" "$(git -C "$dest" rev-parse --short HEAD)"
}

log "Installing plugins..."
# --- pack/vendor/start ---
clone_or_update blink.cmp          https://github.com/saghen/blink.cmp.git              v1.10.2                                                         "$START_DIR/blink.cmp"
clone_or_update friendly-snippets  https://github.com/rafamadriz/friendly-snippets.git  6cd7280adead7f586db6fccbd15d2cac7e2188b9                      "$START_DIR/friendly-snippets"
clone_or_update gruvbox.nvim       https://github.com/ellisonleao/gruvbox.nvim.git      154eb5ff5b96d0641307113fa385eaf0d36d9796                      "$START_DIR/gruvbox.nvim"
clone_or_update nvim-lspconfig     https://github.com/neovim/nvim-lspconfig.git         16286347bdba1333c7d124d9de9fe6630731b2b2                      "$START_DIR/nvim-lspconfig"
clone_or_update nvim-man           https://github.com/paretje/nvim-man.git              7fe6b3b78c71c9ef834c49e3dcbd955f7ed5c6cb                      "$START_DIR/nvim-man"
clone_or_update nvim-tree.lua      https://github.com/nvim-tree/nvim-tree.lua.git       v1                                                              "$START_DIR/nvim-tree.lua"
clone_or_update nvim-treesitter    https://github.com/nvim-treesitter/nvim-treesitter.git main                                                          "$START_DIR/nvim-treesitter"
clone_or_update nvim-web-devicons  https://github.com/nvim-tree/nvim-web-devicons.git   5f032a85be210cd1c6ac98861eb3b187ff3bd5eb                      "$START_DIR/nvim-web-devicons"
clone_or_update plenary.nvim       https://github.com/nvim-lua/plenary.nvim.git         74b06c6c75e4eeb3108ec01852001636d85a932b                      "$START_DIR/plenary.nvim"
clone_or_update telescope.nvim     https://github.com/nvim-telescope/telescope.nvim.git v0.2.2                                                         "$START_DIR/telescope.nvim"
clone_or_update which-key.nvim     https://github.com/folke/which-key.nvim.git          3aab2147e74890957785941f0c1ad87d0a44c15a                      "$START_DIR/which-key.nvim"
# --- pack/vendor/opt (lazy-loaded) ---
clone_or_update lazydev.nvim       https://github.com/folke/lazydev.nvim.git            ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d                      "$OPT_DIR/lazydev.nvim"

# ---------------------------------------------------------------------------
# 3. blink.cmp fuzzy matcher (gitignored build artifact, not vendored)
# ---------------------------------------------------------------------------
if [ -f "$START_DIR/blink.cmp/target/release/libblink_cmp_fuzzy.so" ]; then
  log "blink.cmp fuzzy binary present, skipping build"
else
  if command -v cargo >/dev/null 2>&1; then
    log "Building blink.cmp fuzzy matcher (cargo build --release)..."
    (cd "$START_DIR/blink.cmp" && cargo build --release) \
      || warn "blink build failed; completion falls back with fuzzy={implementation=\"lua\"} in lua/config/plugins.lua"
  else
    warn "no cargo: skipping blink build. Install rust or set fuzzy={implementation=\"lua\"} in lua/config/plugins.lua"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Help tags
# ---------------------------------------------------------------------------
log "Rebuilding helptags..."
for d in "$START_DIR"/*/ "$OPT_DIR"/*/; do
  [ -d "${d}doc" ] || continue
  nvim --headless -c "helptags ${d}doc" -c "q" >/dev/null 2>&1 || warn "helptags failed for $d"
done

# ---------------------------------------------------------------------------
# 5. Treesitter parsers (-> ~/.local/share/nvim/site/)
# ---------------------------------------------------------------------------
if command -v tree-sitter >/dev/null 2>&1; then
  log "Installing treesitter parsers (c cpp lua python vim vimdoc query)..."
  timeout 280 nvim --headless --clean \
    --cmd "set rtp+=$START_DIR/nvim-treesitter" \
    -c "lua require('nvim-treesitter').install({ 'c', 'cpp', 'lua', 'python', 'vim', 'vimdoc', 'query' }):wait(270000); print('parsers done')" \
    -c "q" 2>&1 | tail -n 8 || warn "parser install had errors; run :TSUpdate inside nvim and see :checkhealth nvim-treesitter"
else
  warn "no tree-sitter CLI: skipping parser install. C/Lua/Vim use Neovim built-ins; run :TSInstall for the rest after installing tree-sitter-cli."
fi

# ---------------------------------------------------------------------------
# 6. Smoke test
# ---------------------------------------------------------------------------
log "Smoke-testing config..."
nvim --headless \
  -c "lua require('config.options'); require('config.plugins'); require('config.keymaps'); print('config OK')" \
  -c "q" 2>&1 || die "config failed to load; run nvim and check :messages"

log "Done. Next steps inside nvim:"
echo "  :checkhealth telescope | :checkhealth which-key | :checkhealth nvim-treesitter"
echo "  Space+f+k lists all keymaps. See PACKAGES.md for the manual behind this script."
