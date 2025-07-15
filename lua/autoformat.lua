local auto_dir_group = vim.api.nvim_create_augroup("Dir", { clear = true })

-- Auto-Format on "BufEnter"
vim.api.nvim_create_autocmd("BufEnter", {
    group = auto_dir_group,
    pattern = "*",
    callback = function()
        vim.lsp.buf.format()
    end,
})
