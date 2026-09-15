# Neovim WITHOUT a plugin manager — how this config works (PURE `pack/`)

> New system? Run `./setup.sh` — it checks system deps, clones all plugins
> to their pinned refs, builds blink.cmp, installs treesitter parsers, and
> smoke-tests. `./update.sh` moves tracked plugins forward (snapshots pins
> first); `./rollback.sh` restores pins from `versions.txt` or a snapshot.
> Everything below is the manual behind those scripts.

No `lazy.nvim`, no `vim.pack`, no internet on startup.
Plugins are plain git repos sitting in a folder. Neovim loads them natively.

## 1. The 3 core concepts

1. **`runtimepath` (`rtp`)** — list of dirs Neovim searches for `lua/`, `plugin/`, `doc/`, `queries/`.
   Check yours: `:set rtp?` , `:lua print(vim.o.rtp)`, `:scriptnames` (what actually loaded).

2. **`packpath`** — where Neovim looks for native "packages".
   `:lua print(vim.o.packpath)` includes `~/.config/nvim` and `~/.local/share/nvim/site`.
   That means BOTH of these work:
   ```
   ~/.config/nvim/pack/vendor/start/*   <- versioned with your dotfiles (we use this)
   ~/.local/share/nvim/site/pack/vendor/start/*
   ```

3. **`start/` vs `opt/`**
   ```
   pack/vendor/start/foo   -> loaded automatically at startup
   pack/vendor/opt/foo     -> loaded ONLY when you run :packadd foo
   ```
   Rule: put everything in `start/` except things you want lazy-loaded
   (we only use `opt/` for `lazydev.nvim`, which is lua-only).

Inside a plugin repo, Neovim cares about:
```
plugin/*.vim | plugin/*.lua   -> sourced automatically at startup
lua/*.lua                     -> available via require("..."), NOT auto-run
doc/*.txt                     -> available via :help <plugin>
after/plugin/*                -> sourced after everything else
```

So "installing a plugin" = clone repo to right folder.
"Configuring a plugin" = call `require("foo").setup({...})` in `init.lua`.
"Updating" = `git pull` in that folder. That's it.

## 2. Getting extensions from git

Every plugin's page lists a clone URL. Pattern is always:

```bash
mkdir -p ~/.config/nvim/pack/vendor/start
cd ~/.config/nvim/pack/vendor/start
git clone https://github.com/<author>/<repo>.git
# optional: pin to a tag/branch like lazy did
cd <repo> && git checkout tags/0.1.8   # example: telescope 0.1.8
```

To learn what URL + tag to use, look at:
- GitHub README (install section)
- `:help packages`, `:help runtimepath`, `:help packadd`
- After clone: `:helptags ~/.config/nvim/pack/vendor/start/<repo>/doc` then `:help <repo>`

To update / remove:
```bash
# update one
cd ~/.config/nvim/pack/vendor/start/telescope.nvim && git pull
# update all
for d in ~/.config/nvim/pack/vendor/start/*/; do git -C "$d" pull --ff-only; done
# remove
rm -rf ~/.config/nvim/pack/vendor/start/some-plugin
```

No lockfile. If you want reproducibility, record commits:
```bash
for d in ~/.config/nvim/pack/vendor/start/*/; do
  echo "$(basename $d): $(git -C $d rev-parse --short HEAD) $(git -C $d describe --tags 2>/dev/null)"
done > ~/.config/nvim/pack/versions.txt
```

## 3. Actually adding them (with their specific options)

Cloning is NOT enough for most plugins — you must call `setup()` yourself.
Where lazy did `config = function() ... end` / `opts = {...}`, you write it inline.

Template in `init.lua`:
```lua
-- order matters: dependencies first!
require("plenary")              -- dependency, no setup needed
require("telescope").setup({    -- real setup, options table
  defaults = { ... }
})
```

How to find the options table for any plugin:
1. `README.md` in its repo (always has a `setup({...})` example — copy it).
2. `:help <plugin>` after `:helptags` (authoritative).
3. `lua/<plugin>/config.lua` or `lua/<plugin>/init.lua` in the repo — read the defaults.

Concrete map for THIS config (migrated from `lua/plugins/*.lua`):

| plugin | setup call | notes |
|---|---|---|
| `plenary.nvim` | none, dependency only | must load before telescope |
| `telescope.nvim` (tag v0.2.2) | `require("telescope").setup({defaults={...}})` | keep your `vimgrep_arguments` with `rg --hidden`; needs 0.12-compatible release (0.1.8 crashes previews via removed `ft_to_lang`) |
| `nvim-web-devicons` | `require("nvim-web-devicons").setup({})` or none | must load before nvim-tree |
| `nvim-tree.lua` | `require("nvim-tree").setup({sort=..., view=..., ...})` | keep your 30-width + dotfiles block from `init.lua` |
| `gruvbox.nvim` | `require("gruvbox").setup({...}); vim.cmd.colorscheme("gruvbox")` | keep `transparent_mode=true` + bg=none hammer |
| `nvim-treesitter` (branch main, needs Neovim 0.12 + `tree-sitter-cli`) | `require("nvim-treesitter").setup({})` then `require("nvim-treesitter").install({...})`, enable with `vim.treesitter.start()` in a FileType autocmd | parsers/queries live in `~/.local/share/nvim/site/` — run `:TSUpdate` after clone; old `master` branch + `nvim-treesitter.configs` API is archived and breaks on 0.12 (`range` nil error) |
| `nvim-lspconfig` | `vim.lsp.config('lua_ls', {}); vim.lsp.enable('lua_ls')` | 0.12 style, no `require("lspconfig")` needed |
| `blink.cmp` (v1.*) + `friendly-snippets` | `require("blink.cmp").setup({keymap={preset='default'}, ...})` | needs `target/release/libblink_cmp_fuzzy.so` — copy it or download release; if missing use `fuzzy={implementation="lua"}` |
| `nvim-man` | none | provides `:Man` page, no setup |
| `which-key.nvim` | `require("which-key").setup({preset="modern", ...})` | popup for pending keys; needs `timeoutlen=300` in options |
| `lazydev.nvim` (opt only) | `vim.api.nvim_create_autocmd("FileType",{pattern="lua",callback=function() vim.cmd("packadd lazydev.nvim"); require("lazydev").setup({...}) end})` | the ONLY lazy-loaded plugin |

`:checkhealth telescope`, `:checkhealth nvim-treesitter`, `:TSUpdate`, `:scriptnames` verify each step.

## 4. Keybinds (no manager involved)

Keybinds are core Neovim, nothing to do with plugins:

```lua
vim.g.mapleader = " "   -- must be set BEFORE any <leader> maps
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Tree" })
vim.keymap.set({ "n", "t" }, "<leader>t", toggle_floating_terminal, { desc = "Float term" })
```

Learn: `:help keymap`, `:help mapleader`, `:nmap <leader>f` to list, `:verbose nmap <leader>ff` to see where it was defined.

Rules: `require` the plugin first, then bind. Buffer-local maps pass `{buffer=bufnr}`.

## 5. Creating your OWN extension (minimal plugin)

A "plugin" is just a folder with this shape. Create one to prove it:

```bash
mkdir -p ~/.config/nvim/pack/vendor/start/hello/lua/hello
mkdir -p ~/.config/nvim/pack/vendor/start/hello/plugin
mkdir -p ~/.config/nvim/pack/vendor/start/hello/doc
```

`pack/vendor/start/hello/lua/hello/init.lua`:
```lua
local M = {}
function M.greet() print("hello from my own plugin") end
function M.setup(opts) M.config = vim.tbl_extend("force", { prefix = ">> " }, opts or {}) end
return M
```

`pack/vendor/start/hello/plugin/hello.lua` (auto-sourced, creates a command):
```lua
vim.api.nvim_create_user_command("Hello", function() require("hello").greet() end, {})
```

`pack/vendor/start/hello/doc/hello.txt`:
```
*hello.txt*  My first plugin
*Hello*  :Hello  Greets you.
```

Then in `init.lua`:
```lua
require("hello").setup({ prefix = ">>> " })
vim.keymap.set("n", "<leader>H", require("hello").greet, { desc = "Hello" })
```

Reload, run `:helptags ~/.config/nvim/pack/vendor/start/hello/doc`, then `:help hello`, `:Hello`. No git, no manager — same mechanism real plugins use.

## 6. Worked example: adding a plugin from the internet manually

Goal: add `kylechui/nvim-surround` (no deps, easy to verify).

```bash
# 1. clone to start/
mkdir -p ~/.config/nvim/pack/vendor/start
cd ~/.config/nvim/pack/vendor/start
git clone https://github.com/kylechui/nvim-surround.git

# 2. build help tags
nvim --headless -c "helptags ~/.config/nvim/pack/vendor/start/nvim-surround/doc" -c "q"
```

Add to `init.lua` (learn options from its README / `:help nvim-surround`):
```lua
require("nvim-surround").setup({})  -- defaults are fine
```

Restart, test on any word in normal mode: `ysw"` to surround with quotes, `ds"` to delete, `cs"'` to change. Verify with `:scriptnames` (see `nvim-surround` listed) and `:help nvim-surround`.

To pin / remove:
```bash
cd ~/.config/nvim/pack/vendor/start/nvim-surround
git log --oneline -3        # pick a commit
git checkout <sha>          # pin
rm -rf ~/.config/nvim/pack/vendor/start/nvim-surround  # uninstall = delete + remove setup() line
```

That's the whole lifecycle. Repeat for any repo.
