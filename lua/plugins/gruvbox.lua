return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      terminal_colors = true,
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      invert_intend_guides = false,
      inverse = true,
      contrast = "hard",
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = true, -- MUST be true and only here
    })
    vim.cmd("colorscheme gruvbox")

    -- The "Hammer" to ensure no UI elements have a solid background
    local hl_groups = {
      "Normal",
      "NormalNC",
      "SignColumn",
      "LineNr",
      "Folded",
      "EndOfBuffer",
      "NvimTreeNormal",
    }
    for _, group in ipairs(hl_groups) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end,
}
