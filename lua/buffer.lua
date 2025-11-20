-- Create an augroup to ensure commands are not duplicated
local autoclose_group = vim.api.nvim_create_augroup("AutoCloseFloats", { clear = true })

local function limit_buffers(max)
    local bufs = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted")
    end, vim.api.nvim_list_bufs())

    if #bufs > max then
        -- Sort by buffer number (older are usually lower numbers)
        table.sort(bufs)
        for i = 1, #bufs - max do
            vim.api.nvim_buf_delete(bufs[i], { force = true })
        end
    end
end

-- Call this after opening a buffer
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        limit_buffers(7)
    end,
})

-- Removes Empty Buffers
vim.api.nvim_create_autocmd("BufLeave", {
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)
        local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
        local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
        local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

        -- Only remove truly empty, unmodified unnamed buffers
        if name == "" and not modified and listed and buftype == "" then
            vim.schedule(function()
                -- Recheck to avoid closing active buffer too soon
                if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() ~= bufnr then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)
        local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
        local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
        local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

        -- Only remove truly empty, unmodified unnamed buffers
        if name == "" and not modified and listed and buftype == "" then
            vim.schedule(function()
                -- Recheck to avoid closing active buffer too soon
                if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() ~= bufnr then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

-- Define a list of filetypes that should NOT be auto-closed
local exclude_filetypes = {
    "TelescopePrompt",
    "NvimTree",
    "lazy",
    "mason",
    "noice",
    "alpha",
    "trouble",
    "snacks",
    "Leet"
}

vim.api.nvim_create_autocmd("WinLeave", {
    group = autoclose_group,
    pattern = "*",
    callback = function(args)
        local win_id = args.win
        local bufnr = args.buf

        -- First, ensure win_id is a number before using it.
        if type(win_id) ~= "number" then
            return
        end

        -- Then, check if the window is still valid.
        if not vim.api.nvim_win_is_valid(win_id) then
            return
        end

        -- Check if the buffer in the window is listed for exclusion
        local ftype = vim.bo[bufnr].filetype
        if vim.tbl_contains(exclude_filetypes, ftype) then
            return
        end

        -- Get window configuration
        local config = vim.api.nvim_win_get_config(win_id)

        -- Check if the window is a float
        if config.relative ~= "" then
            vim.schedule(function()
                -- check validity again inside the schedule
                if vim.api.nvim_win_is_valid(win_id) then
                    vim.api.nvim_win_close(win_id, true)
                end
            end)
        end
    end,
})

local function enter_insert_if_zsh()
    -- Check if the buffer is a terminal running zsh
    local bufname = vim.fn.expand('%:p')
    if bufname:match("zsh") then
        vim.cmd("startinsert")
    end
end

-- Autocmd for when entering a terminal buffer
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "term://*",
    callback = enter_insert_if_zsh,
})
