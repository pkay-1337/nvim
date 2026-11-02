-- IDE-style buffer tabline (no plugin): one clickable tab per listed file buffer.
-- Left-click a tab to switch, "×" closes it (:bdelete refuses modified buffers).
local M = {}

local targets = {}

local function short_name(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(path, ":t")
end

local function truncate(text, max)
  if vim.fn.strdisplaywidth(text) <= max then
    return text
  end
  return vim.fn.strcharpart(text, 0, max - 1) .. "…"
end

local function valid_target(id)
  local buf = targets[id]
  return buf and vim.api.nvim_buf_is_valid(buf) and buf or nil
end

function _G.__tabline_select(id)
  local buf = valid_target(id)
  if buf then
    vim.api.nvim_set_current_buf(buf)
  end
end

function _G.__tabline_close(id)
  local buf = valid_target(id)
  if buf then
    pcall(vim.api.nvim_buf_delete, buf, {})
  end
end

function M.render()
  local current = vim.api.nvim_get_current_buf()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(buf) == 1 and vim.bo[buf].buftype == "" then
      bufs[#bufs + 1] = buf
    end
  end

  local counts = {}
  for _, buf in ipairs(bufs) do
    local name = short_name(buf)
    counts[name] = (counts[name] or 0) + 1
  end

  local parts = {}
  for i, buf in ipairs(bufs) do
    local id = (i - 1) % 50 + 1
    targets[id] = buf

    local full = vim.api.nvim_buf_get_name(buf)
    local name = short_name(buf)
    if counts[name] > 1 and full ~= "" then
      name = vim.fn.fnamemodify(full, ":~:.")
    end

    name = truncate(name, 28):gsub("%%", "%%%%")
    local modified = vim.bo[buf].modified and "+" or ""
    local selected = buf == current
    local base_hl = selected and "%#TabLineSel#" or "%#TabLine#"
    local close_hl = selected and "%#TabLineSel#" or "%#TabLineClose#"
    local label = " " .. name .. modified .. " "

    parts[#parts + 1] = ("%%%d@v:lua.__tabline_select@%s%s%%X"):format(id, base_hl, label)
    parts[#parts + 1] = ("%%%d@v:lua.__tabline_close@%s × %%X"):format(id, close_hl)
  end

  parts[#parts + 1] = "%#TabLineFill#%="
  return table.concat(parts)
end

local function set_highlights()
  vim.api.nvim_set_hl(0, "TabLine", { fg = "#a89984", bg = "#3c3836" })
  vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ebdbb2", bg = "#504945", bold = true })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "#282828" })
  vim.api.nvim_set_hl(0, "TabLineClose", { fg = "#665c54", bg = "#3c3836" })
end

function M.setup()
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'config.tabline'.render()"
end

return M
