local M = {}

local function dashboard_buffers()
    return vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_valid(buf)
            and vim.bo[buf].filetype == "snacks_dashboard"
    end, vim.api.nvim_list_bufs())
end

local function first_dashboard_window(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_is_valid(win) then return win end
    end
end

function M.open(opts)
    opts = opts or {}
    local dashboards = dashboard_buffers()
    local dashboard = dashboards[1]
    local target = opts.win

    if dashboard then
        if target and vim.api.nvim_win_is_valid(target) then
            vim.api.nvim_win_set_buf(target, dashboard)
            vim.api.nvim_set_current_win(target)
        else
            local win = first_dashboard_window(dashboard)
            if win then
                vim.api.nvim_set_current_win(win)
            else
                vim.api.nvim_win_set_buf(0, dashboard)
            end
        end
        return dashboard
    end

    if target and vim.api.nvim_win_is_valid(target) then
        vim.api.nvim_set_current_win(target)
    end
    Snacks.dashboard.open({ win = vim.api.nvim_get_current_win() })
    return vim.api.nvim_get_current_buf()
end

function M.keep_single(buf)
    for _, other in ipairs(dashboard_buffers()) do
        if other ~= buf then
            for _, win in ipairs(vim.fn.win_findbuf(other)) do
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_set_buf(win, buf)
                end
            end
            pcall(vim.api.nvim_buf_delete, other, { force = true })
        end
    end
end

return M
