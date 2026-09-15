-- Autocmds: filetype-specific behavior.
-- C/C++: format with clang-format (4-space style) via gg=G on <leader>f.

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(args)
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
