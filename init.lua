-- Lazy config
require("config.lazy")




-- vim options (index.txt)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.clipboard = xclip
vim.opt.number = true
-- vim commands (index.txt)
-- https://github.com/morhetz/gruvbox/blob/master/colors/gruvbox.vim
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
vim.keymap.set('n', 'p', function() vim.cmd('put +') end, {remap =true})
vim.keymap.set('v', 'c', '"+y', {remap =true})
vim.keymap.set('n', 'c', '"+y', {remap =true})

print("No errors")

