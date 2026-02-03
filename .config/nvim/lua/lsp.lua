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
	"bashls",
	"biome",
	"clangd",
	"cmake",
	"cssls",
	"dockerls",
	"fish_lsp",
	"gopls",
	"html",
	"janet_lsp",
	"jsonls",
	"just",
	"kotlin_language_server",
	"leanls",
	"lemminx",
	"lua_ls",
	"mesonlsp",
	"nixd",
	"nushell",
	"rust_analyzer",
	"taplo",
	"tinymist",
	"ty",
	"vtsls",
	"wgsl_analyzer",
	"zls",
})
