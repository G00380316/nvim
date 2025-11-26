local auto_dir_group = vim.api.nvim_create_augroup("Dir", { clear = true })

-- Auto-Format on "BufWrite"
vim.api.nvim_create_autocmd("BufWritePre", {
    group = auto_dir_group,
    pattern = "*",
    callback = function()
        local clients = vim.lsp.get_active_clients({ bufnr = 0 })
        for _, c in ipairs(clients) do
            if c.server_capabilities.documentFormattingProvider then
                vim.lsp.buf.format({ async = false })
                return
            end
        end
    end,
})
