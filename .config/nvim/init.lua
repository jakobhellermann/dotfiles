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
	'ibhagwan/fzf-lua',
	'neovim/nvim-lspconfig',
	'rstacruz/vim-closer',
	'tpope/vim-surround',
	{ 'mtrajano/tssorter.nvim', config = function()
		require('tssorter').setup({
			sortables = {
				toml = {
					tables = {
						node = 'table'
					}
				}
			}

		})
	end },
	{ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' },
}

require 'nvim-treesitter'.install { 'beancount', 'toml' }

-- Enable treesitter for specific filetypes
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'toml', 'beancount' },
	callback = function() vim.treesitter.start() end,
})

require("autocomplete")
require("format_on_save")
require("keymap")
require("lsp")
require("options")
require("ui")

-- THEME

-- AUTOCMDS
utils.associate(".aliases", "sh")
utils.associate("ModLog.txt", "modlog")
utils.associate("*.log", "log")

-- restore position
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
