-- Plugins: plain require().setup() calls, no manager.
-- Assumes pack/vendor/start/* (auto-loaded, see PACKAGES.md).
-- Order matters: dependencies first (plenary -> telescope, devicons -> tree).
-- To tune a plugin, edit its setup{...} table; options come from its
-- README or :help <plugin-name>.

-- 1. Colorscheme first so later plugins inherit highlights.
require("gruvbox").setup({
  terminal_colors = true,
  undercurl = true,
  underline = true,
  bold = true,
  italic = { strings = true, emphasis = true, comments = true, operators = false, folds = true },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  invert_intend_guides = false,
  inverse = true,
  contrast = "hard",
  palette_overrides = {},
  overrides = {},
  dim_inactive = false,
  transparent_mode = true,
})
vim.cmd("colorscheme gruvbox")
-- Keep transparent background even after colorscheme reloads.
for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "LineNr", "Folded", "EndOfBuffer", "NvimTreeNormal" }) do
  vim.api.nvim_set_hl(0, group, { bg = "none" })
end

-- 2. Icons before file tree (nvim-tree reads them at setup).
pcall(require, "nvim-web-devicons")

require("nvim-tree").setup({
  sort = { sorter = "case_sensitive" },
  view = { width = 30 },
  filters = { dotfiles = false },
  renderer = { group_empty = true, highlight_opened_files = "all" },
})

-- 3. Plenary before telescope (telescope requires it).
pcall(require, "plenary")
require("telescope").setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
    vimgrep_arguments = {
      "rg", "--color=never", "--no-heading", "--with-filename",
      "--line-number", "--column", "--smart-case", "--hidden",
    },
  },
})

-- 3b. which-key: grouped leader menu.
-- Space + pause -> Find / Buffer / Window / Code / Git groups + singles.
-- Type g, z, ", ', `, <C-w> -> those built-ins too.
require("which-key").setup({
  preset = "modern",
  delay = 300,
  spec = {
    -- Leader families (space popup)
    { "<leader>f", group = "Find (telescope)" },
    { "<leader>b", group = "Buffer" },
    { "<leader>w", group = "Window" },
    { "<leader>c", group = "Code (LSP, per filetype)" },
    { "<leader>g", group = "Git" },
    { "<leader>t", desc = "Floating terminal" },
    { "<leader>e", desc = "File tree" },
    { "<leader>E", desc = "Reveal file in tree" },
    -- Built-in families (organizes the <leader>? full tree)
    { "g", group = "Go to / LSP" },
    { "gr", group = "LSP refactor" },
    { "z", group = "Folds / spelling" },
    { "[", group = "Previous…" },
    { "]", group = "Next…" },
    { "<C-w>", group = "Windows" },
  },
})
-- 4. Treesitter (main branch, Neovim 0.12 API).
-- Parsers/queries install to ~/.local/share/nvim/site/ (not the repo dir).
-- Run :TSUpdate after updating the repo. Needs tree-sitter-cli >= 0.26.1:
--   sudo pacman -S tree-sitter-cli
local ok_ts, ts = pcall(require, "nvim-treesitter")
if ok_ts then
  ts.setup({})
  -- Async no-op if already installed.
  ts.install({ "c", "cpp", "lua", "python", "vim", "vimdoc", "query" })
end

-- Enable built-in highlighting (+ experimental plugin indent) per filetype.
-- This replaces the old nvim-treesitter.configs highlight/indent setup,
-- which used a removed LanguageTree API and caused:
--   attempt to call method 'range' (a nil value)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "lua", "python", "vim" },
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- 5. LSP (Neovim 0.12 style: config + enable).
-- blink.cmp injects extra capabilities (snippet support, etc.).
-- Pass them explicitly so clangd/lua_ls/pyright offer full completion.
local blink_caps = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("lua_ls", {})
vim.lsp.enable("lua_ls")
vim.lsp.config("pyright", {})
vim.lsp.enable("pyright")

-- C/C++: clangd is installed (/usr/bin/clangd 22.1.8).
-- Flags tuned for single-file `gcc main.c` projects WITHOUT
-- compile_commands.json (background index + fallback flags).
-- For larger Makefile/CMake projects, generate it for exact completions:
--   bear -- make            # Makefile projects
--   cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .  # CMake projects
--   ln -s build/compile_commands.json .        # if it lives in build/
vim.lsp.config("clangd", {
  capabilities = vim.tbl_deep_extend("force", {}, blink_caps),
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
  },
  root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", ".git" },
})
vim.lsp.enable("clangd")
-- nvim-lspconfig repo only ships configs; no setup() call needed.

-- Useful LSP keys once a server attaches (clangd included).
-- gd = jump to definition, grr = references, grn = rename,
-- gra = code action, K = hover, [d / ]d = diagnostics,
-- <leader>ch = switch header/source (clangd only, <leader>c Code group).
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "grr", vim.lsp.buf.references, "References")
    map("n", "grn", vim.lsp.buf.rename, "Rename")
    map("n", "gra", vim.lsp.buf.code_action, "Code action")
    map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "clangd" then
      map("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", "Switch header/source")
    end
  end,
})

-- 6. Completion: blink.cmp + friendly-snippets (both in start/).
-- Needs target/release/libblink_cmp_fuzzy.so inside the blink repo;
-- vendored copy keeps it. If completion ever reports missing fuzzy
-- binary, switch implementation to "lua".
-- friendly-snippets (c/c.json, cpp, cmake) auto-loads, no extra call.
require("blink.cmp").setup({
  keymap = {
    preset = "default",
    -- <C-space> = force menu, <C-e> = hide, <CR> = accept,
    -- <Tab>/<S-Tab> = next/prev + snippet jump, <C-k> = docs toggle.
    ["<C-k>"] = { "show_documentation", "hide_documentation" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    -- Show docs (printf signature, man excerpt) without extra keypress.
    documentation = { auto_show = true, auto_show_delay_ms = 250 },
    -- Ghost text previews the top item inline (e.g. `printf(...)`).
    ghost_text = { enabled = true },
    -- Trigger on every keystroke in C (pri, mal, #in...).
    trigger = { show_on_keyword = true, show_on_trigger_character = true },
    menu = { draw = { treesitter = { "lsp" } } },
  },
  signature = { enabled = true }, -- prototype while typing f(a, b)
  snippets = { preset = "default" },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- 7. nvim-man: provides :Man, no setup() needed.

-- 8. lazydev: the ONLY opt/ plugin. Load on lua files to keep
-- startup lean, mirroring old `ft = "lua"`.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  once = false,
  callback = function()
    vim.cmd("packadd lazydev.nvim")
    require("lazydev").setup({
      library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
    })
  end,
})
