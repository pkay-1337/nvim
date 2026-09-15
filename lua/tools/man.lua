-- Man pages for C: syscalls (2) and libc functions (3).
-- Opens :Man for the word under cursor, preferring section 2, then 3
-- (so `open` -> open(2), `printf` -> printf(3)), falling back to plain
-- :Man which handles section choice itself. Needs nvim-man (:Man) and
-- system man pages (man-pages package).
local M = {}

local SECTIONS = { "2", "3" }

function M.open_cword()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("no word under cursor", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("man") == 0 then
    vim.notify("man not installed", vim.log.levels.ERROR)
    return
  end
  for _, sec in ipairs(SECTIONS) do
    vim.fn.system({ "man", "-w", sec, word })
    if vim.v.shell_error == 0 then
      vim.cmd("Man " .. sec .. " " .. word)
      return
    end
  end
  vim.cmd("Man " .. word)
end

return M
