require("config.lazy")
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {},
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',  -- Add this line to include hidden files
    },
  }
}
-- NVIM TREE
-- disable netrw at the very start of your init.lua
--vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- empty setup using defaults
-- require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 40,
	},
	filters = {
		dotfiles = true,
	},
})
-- LEADER
vim.g.mapleader = " "

-- vim options (index.txt)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.clipboard = xclip
vim.opt.number = true
-- vim commands (index.txt)
vim.cmd.colorscheme("gruvbox")

-- vim functions (builtin.txt)
-- print(vim.fn.printf('Hello from %s', 'Lua'))
x = 0
function nn()
	x = x + 1
	print(string.format("typed nn %d times", x))
end

-- Key mappings
-- vim.keymap.set('n', 'nn', nn)
-- vim.keymap.set('n', 'p', function() vim.cmd('put +') end, {remap =true})
-- vim.keymap.set('v', 'c', '"+y', {remap =true})
-- vim.keymap.set('n', 'c', '"+y', {remap =true})
vim.keymap.set('n', '<leader>n', function() vim.cmd('bn') end, {remap =true})
vim.keymap.set('n', '<leader>t', function() vim.cmd('NvimTreeToggle') end)
vim.keymap.set('n', '<leader>o', function() vim.cmd('wincmd p') end)

-- TELESCOPE


local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fm', builtin.man_pages, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fp', builtin.current_buffer_fuzzy_find, { desc = 'In this file' })

print("No errors")

