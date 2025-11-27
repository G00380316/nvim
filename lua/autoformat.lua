local auto_fmt_group = vim.api.nvim_create_augroup("AutoFormat", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = auto_fmt_group,
	pattern = "*",
	callback = function()
		vim.lsp.buf.format({
			async = false,
			filter = function(client)
				-- Prefer null-ls for formatting
				if client.name == "null-ls" then
					return true
				end

				-- Otherwise use any LSP that supports formatting
				return client.server_capabilities.documentFormattingProvider
			end,
		})
	end,
})
