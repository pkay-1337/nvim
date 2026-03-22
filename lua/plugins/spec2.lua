return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- require("lspconfig").lua_ls.setup {}
			vim.lsp.config('lua_ls', {})

			-- require("lspconfig").pyright.setup {}
			vim.lsp.config('pyright', {})
		end,
	}
}
