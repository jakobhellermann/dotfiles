local utils = require("utils")

local function bootstrap_pckr()
	local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"
	if not vim.uv.fs_stat(pckr_path) then
		vim.fn.system({ 'git', 'clone', "--filter=blob:none", 'https://github.com/lewis6991/pckr.nvim', pckr_path })
	end

	vim.opt.runtimepath:prepend(pckr_path)
end
bootstrap_pckr()

require('pckr').add {
	'airblade/vim-gitgutter',
	'lotabout/skim.vim',
	'neovim/nvim-lspconfig',
	'rstacruz/vim-closer',
	-- { 'nvim-telescope/telescope.nvim', requires = 'nvim-lua/plenary.nvim' },
	-- { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' },
	'hrsh7th/cmp-buffer',
	'hrsh7th/cmp-cmdline',
	'hrsh7th/cmp-nvim-lsp',
	'hrsh7th/cmp-path',
	'hrsh7th/nvim-cmp',
}

require("options")
require("ui")
require("lsp")
require("keymap")
require("autocomplete")

-- THEME

-- AUTOCMDS
utils.associate(".aliases", "sh")

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		local last_position = vim.api.nvim_buf_get_mark(0, '"')
		local line_count = vim.api.nvim_buf_line_count(0)
		if last_position[1] > 1 and last_position[1] <= line_count then
			pcall(vim.api.nvim_win_set_cursor, 0, { last_position[1], last_position[2] })
		end
	end
})

-- KEYBINDINGS
