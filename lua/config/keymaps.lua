-- Keymaps: every keybinding in one place.
-- Format: vim.keymap.set(mode, lhs, rhs, { desc = "..." }).
-- <leader> is space (set in options.lua). :nmap <leader>f to audit.

local floatterm = require("tools.floatterm")
local ok_tb, builtin = pcall(require, "telescope.builtin")

-- Buffers
vim.keymap.set("n", "<leader>n", ":bn<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>j", ":bn<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>k", ":bp<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "<leader>bq", ":bd!<CR>", { desc = "Kill buffer" })

-- Windows / tree / terminal
vim.keymap.set("n", "<leader>T", ":NvimTreeToggle<CR>", { desc = "File tree" })
vim.keymap.set("n", "<leader>o", "<C-w>p", { desc = "Prev window" })
vim.keymap.set({ "n", "t" }, "<leader>t", floatterm.toggle, { desc = "Floating terminal" })

-- Windows: move with Ctrl-hjkl (works in terminal too)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })
vim.keymap.set("t", "<C-h>", [[<C-\><C-N><C-w>h]], { desc = "Window left" })
vim.keymap.set("t", "<C-j>", [[<C-\><C-N><C-w>j]], { desc = "Window down" })
vim.keymap.set("t", "<C-k>", [[<C-\><C-N><C-w>k]], { desc = "Window up" })
vim.keymap.set("t", "<C-l>", [[<C-\><C-N><C-w>l]], { desc = "Window right" })
-- Splits: <leader>v = vertical, <leader>S = horizontal
-- (avoids <leader>s prefix, already used by <leader>sh LSP switch)
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>S", "<cmd>split<CR>", { desc = "Split horizontal" })
vim.keymap.set("n", "<leader>X", "<cmd>close<CR>", { desc = "Close window" })
vim.keymap.set("n", "<leader>O", "<cmd>only<CR>", { desc = "Close other windows" })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize windows" })
-- Resize with Ctrl-arrows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Taller window" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Shorter window" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Narrower window" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Wider window" })

-- Escape with kj
vim.keymap.set("i", "kj", [[<C-\><C-N>]], { desc = "Normal mode" })
vim.keymap.set("t", "kj", [[<C-\><C-N>]], { desc = "Normal mode" })

-- Editing essentials
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { desc = "Clear search highlight" })
-- Keep cursor centered on search / half-page jumps
vim.keymap.set("n", "n", "nzzzv", { desc = "Next match centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev match centered" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up centered" })
-- Visual: keep selection when indenting, move lines with J/K
vim.keymap.set("v", "<", "<gv", { desc = "Indent left (keep selection)" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right (keep selection)" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
-- Visual paste without yanking replaced text
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without yanking" })
-- Undo break-points after punctuation in insert mode
vim.keymap.set("i", ",", ",<C-g>u", { desc = "Undo break after ," })
vim.keymap.set("i", ".", ".<C-g>u", { desc = "Undo break after ." })
vim.keymap.set("i", ";", ";<C-g>u", { desc = "Undo break after ;" })

-- Clipboard: explicit "+y still works AND plain y copies out
-- (because clipboard=unnamedplus in options.lua via xclip).
vim.keymap.set("v", "<leader>c", '"+y', { desc = "Copy to system clipboard" })

-- Telescope (only if it loaded)
if ok_tb then
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
  vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
  vim.keymap.set("n", "<leader>fs", builtin.current_buffer_fuzzy_find, { desc = "Search in File" })
  vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find Keymaps" })
  vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
  vim.keymap.set("n", "<leader><leader>", builtin.find_files, { desc = "Find Files" })
  vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Recent files" })
  vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics list" })
  vim.keymap.set("n", "<leader>fr", builtin.registers, { desc = "Registers" })
  vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "Marks" })
  vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
  vim.keymap.set("n", "<leader>fz", builtin.resume, { desc = "Resume last picker" })
  vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
  vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
  vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
end

-- which-key popup on demand (it also auto-pops after 300ms).
vim.keymap.set("n", "<leader>?", function() require("which-key").show() end, { desc = "Show all keymaps" })
