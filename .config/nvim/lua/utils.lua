local utils = {}

function utils.bufmap(pattern, command)
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		pattern = pattern,
		callback = command,
	})
end

function utils.associate(pattern, filetype)
	utils.bufmap(pattern, function() vim.bo.filetype = filetype end)
end


return utils
