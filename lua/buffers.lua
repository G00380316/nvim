local M = {}

local excluded_filetypes = {
    alpha = true,
    dashboard = true,
    oil = true,
    snacks_dashboard = true,
}

function M.is_editor(buf)
    return buf
        and vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ""
        and not excluded_filetypes[vim.bo[buf].filetype]
        and (vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified)
end

function M.list()
    local buffers = {}
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if M.is_editor(info.bufnr) then buffers[#buffers + 1] = info.bufnr end
    end
    return buffers
end

function M.cycle(direction)
    pcall(vim.cmd, "EditorFocus")

    local buffers = M.list()
    local count = #buffers
    if count == 0 then
        return
    end

    local current = vim.api.nvim_get_current_buf()
    local current_index

    for index, buf in ipairs(buffers) do
        if buf == current then
            current_index = index
            break
        end
    end

    local target
    if current_index == nil then
        target = direction > 0 and buffers[1] or buffers[count]
    else
        target = buffers[((current_index - 1 + direction) % count) + 1]
    end

    local ok, err = pcall(vim.api.nvim_win_set_buf, 0, target)
    if not ok then
        -- Schedule the notification so it is outside the autocmd call stack.
        vim.schedule(function()
            vim.notify(
                tostring(err),
                vim.log.levels.WARN,
                { title = "Buffer switch failed" }
            )
        end)
    end
end

function M.replacement(current)
    local candidates = vim.tbl_filter(function(info)
        return info.bufnr ~= current and M.is_editor(info.bufnr)
    end, vim.fn.getbufinfo({ buflisted = 1 }))
    table.sort(candidates, function(a, b) return a.lastused > b.lastused end)
    return candidates[1] and candidates[1].bufnr or nil
end

return M
