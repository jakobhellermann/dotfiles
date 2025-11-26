--[[ local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config.rust_analyzer = { capabilities = capabilities }
vim.lsp.config.lua_ls = {
	capabilities = capabilities
}
--]]


vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

		if not client:supports_method('textDocument/willSaveWaitUntil')
			and client:supports_method('textDocument/formatting') then
			vim.api.nvim_create_autocmd('BufWritePre', {
				group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
				buffer = event.buf,
				callback = function()
					vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end
	end
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			workspace = {
				library = vim.list_extend(vim.api.nvim_get_runtime_file("", true), { "${3rd}/luv/library" }),
				-- vim.env.VIMRUNTIME
				-- Depending on the usage, you might want to add additional paths here.
				-- "${3rd}/luv/library"
				-- "${3rd}/busted/library",
				checkThirdParty = false
			},
		},
	},
})

vim.lsp.enable({
	"fish_lsp",
	"bashls",
	"biome",
	"clangd",
	"cmake",
	"cssls",
	"dockerls",
	"gopls",
	"html",
	"janet_lsp",
	"jsonls",
	"just",
	"kotlin_language_server",
	"leanls",
	"lua_ls",
	"mesonlsp",
	"nixd",
	"nushell",
	"rust_analyzer",
	"taplo",
	"tinymist",
	"wgsl_analyzer",
	"zls",
})
