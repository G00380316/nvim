local web_dev_autosave = vim.api.nvim_create_augroup("WebDevAutoSave", { clear = true })
local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = web_dev_autosave,
    pattern = { "*.html", "*.css", "*.js" }, -- File types to target
    callback = function()
        -- Check if the buffer has a file name and has been modified
        if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 and vim.bo.modified then
            vim.cmd("update") -- Use "update" to save only if there are changes
        end
    end,
    desc = "Auto save for html, css, and js files",
})
