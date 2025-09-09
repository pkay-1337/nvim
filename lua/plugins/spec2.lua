return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("lspconfig").lua_ls.setup {}
			require("lspconfig").pyright.setup {}
		end,
	}
}
