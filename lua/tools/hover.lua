-- LSP hover docs in a bordered float.
-- Used by K and <leader>ck (see LspAttach in lua/config/plugins.lua).
-- (No q-to-close: the float is not focusable, so buffer-local keys
-- can't fire. It dismisses on cursor move / Esc / switching windows.)
local M = {}

function M.show()
  vim.lsp.buf.hover({ border = "rounded", title = " hover ", title_pos = "center" })
end

return M
