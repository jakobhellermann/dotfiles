local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config.rust_analyzer = { capabilities = capabilities }
vim.lsp.config.lua_ls = {
	settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			workspace = {
				library = vim.list_extend(vim.api.nvim_get_runtime_file("", true), { "${3rd}/luv/library" }),
				checkThirdParty = false
			},
		},
	},
	capabilities = capabilities
}
