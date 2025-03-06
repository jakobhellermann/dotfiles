vim.g.mapleader = ","
local keymap = vim.keymap.set

local silent = { silent = true }
keymap("n", "<Leader>w", ":w<CR>", silent)
keymap("n", "<Leader>x", ":x<CR>", silent)
keymap("n", "<Leader>q", ":q<CR>", silent)
keymap("n", "<Leader>r", ":so $MYVIMRC<CR>", silent)
keymap("n", "<Leader><Leader>", "<C-^>", silent)

keymap("v", "<Leader>y", '"+y', silent)

keymap("n", "n", "nzz", silent)
keymap("n", "N", "Nzz", silent)
keymap("n", "*", "*zz", silent)
keymap("n", "#", "#zz", silent)
keymap("n", "g*", "g*zz", silent)

-- gitgutter
vim.cmd [[
nmap 88 <Plug>(GitGutterPrevHunk)
nmap 99 <Plug>(GitGutterNextHunk)
]]

-- skim
keymap("n", "<Leader>f", ":Files<CR>", silent)
keymap("n", "<Leader>g", ":GFiles<CR>", silent)
keymap("n", "<Leader>b", ":Buffers<CR>", silent)

vim.keymap.set("n", "<F8>", function() vim.diagnostic.jump({ count = 1, float = true }) end)
vim.keymap.set("n", "<F20>", function() vim.diagnostic.jump({ count = -1, float = true }) end)


vim.keymap.set('n', '<Esc>', function()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	for _, win in ipairs(wins) do
		if vim.api.nvim_win_get_config(win).relative ~= '' then
			vim.api.nvim_win_close(win, true)
			return
		end
	end
	vim.cmd('stopinsert')
end, silent)

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local bufmap = function(mode, lhs, rhs)
			local opts = { buffer = event.buf }
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		bufmap('i', '<C-Space>', '<C-x><C-o>')
		bufmap('n', 'gd', vim.lsp.buf.definition)
		bufmap('n', 'gD', vim.lsp.buf.declaration)
		bufmap('n', 'cd', vim.lsp.buf.rename)
		bufmap('n', 'K', vim.lsp.buf.hover)
		bufmap('n', 'gi', vim.lsp.buf.implementation)
		bufmap('n', 'go', vim.lsp.buf.type_definition)
		bufmap('n', 'gr', vim.lsp.buf.references)
		bufmap('n', '<C-q>', vim.lsp.buf.signature_help)
		bufmap('n', '<F3>', vim.lsp.buf.format)
		bufmap('n', '<C-.>', vim.lsp.buf.code_action)
		bufmap('n', '<A-Enter>', vim.lsp.buf.code_action)
	end
})

vim.keymap.set("n", "H", "<C-o>", { noremap = true, silent = true })
vim.keymap.set("n", "L", "<C-i>", { noremap = true, silent = true })
