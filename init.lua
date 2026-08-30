-- 1. Load Plugins
require("config.lazy")

-- 2. General Options
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.clipboard = xclip -- Fixed xclip error

-- 3. Nvim-Tree Setup
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
    sort = { sorter = "case_sensitive" },
    view = { width = 30 }, -- Slightly slimmer for 5'6" laptop screen real estate
    filters = { dotfiles = false }, -- Show dotfiles so you can see .config files
    renderer = {
        group_empty = true,
        highlight_opened_files = "all",
    },
})

-- 4. Telescope Setup
local builtin = require('telescope.builtin')
require('telescope').setup{
    defaults = {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case', '--hidden'
        },
    }
}

-- 5. Key Mappings
vim.keymap.set('n', '<leader>n', ":bn<CR>")
vim.keymap.set('n', '<leader>t', ":NvimTreeToggle<CR>")
vim.keymap.set('n', '<leader>o', "<C-w>p") -- Swaps back to previous window

-- Telescope Mappings
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fp', builtin.current_buffer_fuzzy_find, { desc = 'Search in File' })

-- c format
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(args)
    -- Tell clang-format to use 4 spaces
    local format_cmd = 'clang-format -style="{IndentWidth: 4}"'
    
    vim.bo[args.buf].formatprg = format_cmd
    vim.bo[args.buf].equalprg = format_cmd

    vim.keymap.set("n", "<leader>f", function()
      local view = vim.fn.winsaveview()
      vim.cmd("normal! gg=G")
      vim.fn.winrestview(view)
    end, { buffer = args.buf, desc = "Format C/C++ file" })
  end,
})
