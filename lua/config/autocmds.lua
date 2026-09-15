-- Autocmds: filetype-specific behavior.
-- C/C++ (<leader>c Code group): cf formats via clang-format (4-space),
-- cm opens the man page for the word under cursor.

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function(args)
    local format_cmd = 'clang-format -style="{IndentWidth: 4}"'
    vim.bo[args.buf].formatprg = format_cmd
    vim.bo[args.buf].equalprg = format_cmd

    vim.keymap.set("n", "<leader>cf", function()
      local view = vim.fn.winsaveview()
      vim.cmd("normal! gg=G")
      vim.fn.winrestview(view)
    end, { buffer = args.buf, desc = "Format C/C++ file" })

    -- Man page for libc function / syscall under cursor.
    -- Prefers section 2 then 3 (open -> open(2), printf -> printf(3)).
    vim.keymap.set("n", "<leader>cm", function()
      require("tools.man").open_cword()
    end, { buffer = args.buf, desc = "Man page for word" })
  end,
})
