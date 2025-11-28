return {
	cmd = { "lemminx" },
	filetypes = {
		"xml",
	},

	root_markers = { "pom.xml", ".git" },

	settings = {
		typescript = {
			updateImportsOnFileMove = "always",
		},
		javascript = {
			updateImportsOnFileMove = "always",
		},
		vtsls = {
			enableMoveToFileCodeAction = true,
		},
	},
}
