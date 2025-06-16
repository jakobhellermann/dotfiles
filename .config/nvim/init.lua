local function bootstrap_pckr()
	local pckr_path = vim.fn.stdpath("data") .. "/pckr/pckr.nvim"
	if not (vim.uv or vim.loop).fs_stat(pckr_path) then
		vim.fn.system({ 'git', 'clone', "--filter=blob:none", 'https://github.com/lewis6991/pckr.nvim', pckr_path })
	end

	vim.opt.rtp:prepend(pckr_path)
end
bootstrap_pckr()

require('pckr').add {
	'rstacruz/vim-closer',
	'airblade/vim-gitgutter',
	'neovim/nvim-lspconfig',

	{ 'nvim-telescope/telescope.nvim', requires = 'nvim-lua/plenary.nvim' },

	-- { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' },
}

vim.diagnostic.config({ float = { border = "rounded" } })


local lspconfig = require('lspconfig')

lspconfig.rust_analyzer.setup {}
lspconfig.lua_ls.setup {}

-- THEME
vim.cmd [[
" colorscheme wildcharm
" highlight Normal guibg=NONE ctermbg=NONE
" highlight NonText guibg=NONE ctermbg=NONE
]]

-- AUTOCMDS
local function bufmap(pattern, command)
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		pattern = pattern,
		callback = command,
	})
end
local function associate(pattern, filetype)
	bufmap(pattern, function() vim.bo.filetype = filetype end)
end
associate(".aliases", "sh")


-- GENERAL OPTIONS
vim.opt.updatetime = 400
-- vim.opt.ttimeoutlen = 5

vim.opt.undodir = "/tmp/nvim-undo-dir"
vim.opt.undofile = true

vim.opt.autoindent = true
vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.opt.wildmenu = true
vim.opt.wildmode = { "longest:full", "full" }
vim.opt.wildignore = { "*.swp", ".git/*" }

vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.gdefault = true

vim.opt.number = true
vim.opt.ruler = true
vim.opt.wrap = false

vim.opt.signcolumn = "yes"

-- vim.cmd [[highlight LineNr ctermbg=None]]
-- vim.cmd [[highlight CursorLineNr ctermbg=None]]

-- KEYBINDINGS
vim.g.mapleader = ","
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<Leader>w", ":w<CR>", opts)
keymap("n", "<Leader>x", ":x<CR>", opts)
keymap("n", "<Leader>q", ":q<CR>", opts)
keymap("n", "<Leader>r", ":so $MYVIMRC<CR>", opts)

keymap("v", "<Leader>y", '"+y', opts)

keymap("n", "<Leader><Leader>", "<C-^>", opts)

keymap("n", "n", "nzz", { silent = true })
keymap("n", "N", "Nzz", { silent = true })
keymap("n", "*", "*zz", { silent = true })
keymap("n", "#", "#zz", { silent = true })
keymap("n", "g*", "g*zz", { silent = true })

-- PLUGIN KEYBINDINGS
-- gitgutter
vim.cmd [[
nmap 88 <Plug>(GitGutterPrevHunk)
nmap 99 <Plug>(GitGutterNextHunk)
]]

-- skim
-- keymap("n", "<Leader>f", ":Files<CR>", opts)
-- keymap("n", "<Leader>g", ":GFiles<CR>", opts)
-- keymap("n", "<Leader>b", ":Buffers<CR>", opts)
keymap("n", "<Leader>f", vim.lsp.buf.format, opts)

-- lsp



vim.keymap.set("n", "<F8>", vim.diagnostic.goto_next)
vim.keymap.set("n", "<F20>", vim.diagnostic.goto_prev) -- apparently F20

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local bufmap = function(mode, lhs, rhs)
			local opts = { buffer = event.buf }
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		-- vim.api.nvim_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, silent = true })
		-- vim.api.nvim_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = true })

		bufmap('i', '<C-Space>', '<C-x><C-o>')
		bufmap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
		bufmap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>')
		bufmap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>')
		bufmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>')
		bufmap('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>')
		bufmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>')
		bufmap('n', 'cd', '<cmd>lua vim.lsp.buf.rename()<cr>')
		-- Displays a function's signature information
		bufmap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>')
		-- Renames all references to the symbol under the cursor
		-- Format current file
		bufmap('n', '<F3>', '<cmd>lua vim.lsp.buf.format()<cr>')
		-- Selects a code action available at the current cursor position
		bufmap('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>')
	end
})

vim.keymap.set("n", "H", "<C-o>", { noremap = true, silent = true })
vim.keymap.set("n", "L", "<C-i>", { noremap = true, silent = true })
