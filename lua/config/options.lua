-- Options: leader, UI, indent, clipboard.
-- Edit this when you want Neovim itself to behave differently.
-- Plugin *setup()* calls live in lua/config/plugins.lua, keybinds in keymaps.lua.

-- Must be set before any <leader> mappings or plugins that read it.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.termguicolors = true
vim.opt.number = true

-- Indent: 4-wide, same as your old config.
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Clipboard: "unnamedplus" routes every yank/delete to the system
-- clipboard through the xclip provider (/usr/bin/xclip, DISPLAY=:0).
-- Your old line `vim.opt.clipboard = xclip` assigned a nil global,
-- so it silently did nothing and only "+y worked. This keeps "+y
-- working AND makes plain `y` copy out too. Safe over SSH: if no
-- X server, yanks just stay internal, no error.
vim.opt.clipboard = "unnamedplus"

-- Disable netrw so nvim-tree owns directory browsing.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Key popup timing: which-key shows after 300ms of no typing.
-- Lower = faster popup, higher = less intrusive while coding.
vim.opt.timeout = true
vim.opt.timeoutlen = 300
