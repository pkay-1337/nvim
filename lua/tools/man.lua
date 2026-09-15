-- Man pages for C in a floating window: syscalls (2) and libc (3).
-- Prefers section 2, then 3 (open -> open(2), printf -> printf(3)),
-- falls back to the default section. Close with q or <Esc>.
-- Needs system man pages (man-pages package). No :Man split used.
local M = {}

local SECTIONS = { "2", "3" }

local function pick_section(word)
  for _, sec in ipairs(SECTIONS) do
    vim.fn.system({ "man", "-w", sec, word })
    if vim.v.shell_error == 0 then
      return sec
    end
  end
  return nil -- default section
end

local function open_float(title, lines)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "man"
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal", border = "rounded", title = " " .. title .. " ",
    title_pos = "center",
  })
  local close = function() pcall(vim.api.nvim_win_close, win, true) end
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close man page" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = "Close man page" })
end

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
  local sec = pick_section(word)
  local width = math.floor(vim.o.columns * 0.8)
  local res = vim.system(
    sec and { "man", sec, word } or { "man", word },
    { text = true, env = { MANWIDTH = tostring(width - 4) } }
  ):wait()
  if res.code ~= 0 then
    vim.notify("no manual entry for '" .. word .. "'", vim.log.levels.WARN)
    return
  end
  -- col -b equivalent: strip groff overstrikes (X\bX bold, _\bX underline).
  local lines = {}
  for line in (res.stdout .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line:gsub(".\8", "")
  end
  open_float(word .. (sec and ("(" .. sec .. ")") or ""), lines)
end

return M
