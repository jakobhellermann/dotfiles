-- Format on save configuration
local format_on_save = {
	enabled = true,
	disabled_filetypes = { 'xml' },
}

-- Toggle format on save globally
vim.api.nvim_create_user_command('ToggleFormatOnSave', function()
	format_on_save.enabled = not format_on_save.enabled
	print('Format on save: ' .. (format_on_save.enabled and 'enabled' or 'disabled'))
end, {})

-- Toggle format on save for current buffer
vim.api.nvim_create_user_command('ToggleFormatOnSaveBuffer', function()
	local buf = vim.api.nvim_get_current_buf()
	vim.b[buf].disable_format_on_save = not vim.b[buf].disable_format_on_save
	print('Format on save for buffer: ' .. (vim.b[buf].disable_format_on_save and 'disabled' or 'enabled'))
end, {})

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(event)
		local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

		if not client:supports_method('textDocument/willSaveWaitUntil')
			and client:supports_method('textDocument/formatting') then
			vim.api.nvim_create_autocmd('BufWritePre', {
				group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
				buffer = event.buf,
				callback = function()
					-- Check if globally disabled
					if not format_on_save.enabled then
						return
					end

					-- Check if disabled for current buffer
					if vim.b[event.buf].disable_format_on_save then
						return
					end

					-- Check if filetype is in disabled list
					local filetype = vim.bo[event.buf].filetype
					for _, ft in ipairs(format_on_save.disabled_filetypes) do
						if filetype == ft then
							return
						end
					end

					vim.lsp.buf.format({ bufnr = event.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end
	end
})
