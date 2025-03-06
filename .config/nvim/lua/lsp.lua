local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()


lspconfig.rust_analyzer.setup { capabilities = capabilities}
require('lspconfig').lua_ls.setup {
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
