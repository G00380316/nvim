local M = {}

local function layout()
    return require("ide_layout")
end

local function dashboard_buffers()
    return vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_valid(buf)
            and vim.bo[buf].filetype == "snacks_dashboard"
    end, vim.api.nvim_list_bufs())
end

local function first_dashboard_window(buf)
    local tab = vim.api.nvim_get_current_tabpage()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_get_tabpage(win) == tab
            and layout().is_editor_window(win)
        then
            return win
        end
    end
end

local function preserve_focus(previous_win, target, focus)
    if focus ~= false or not vim.api.nvim_win_is_valid(previous_win) then return end
    vim.api.nvim_set_current_win(previous_win)
    -- Dashboard rendering performs some window work on the next tick. If that
    -- briefly re-enters its target, restore the panel the user explicitly
    -- focused, but do not override a later move to a third window.
    vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(previous_win)
            and vim.api.nvim_win_is_valid(target)
            and vim.api.nvim_get_current_win() == target
        then
            vim.api.nvim_set_current_win(previous_win)
        end
    end, 20)
end

function M.open(opts)
    opts = opts or {}
    local previous_win = vim.api.nvim_get_current_win()
    local dashboards = dashboard_buffers()
    local dashboard = dashboards[1]
    local target = layout().find_editor_window(opts.win)
        or layout().ensure_editor_window({ win = opts.win })
    if not target then return nil end

    if dashboard then
        local win = first_dashboard_window(dashboard)
        if win and win ~= target then
            vim.api.nvim_set_current_win(win)
        else
            vim.api.nvim_win_set_buf(target, dashboard)
            vim.api.nvim_set_current_win(target)
        end
        layout().evict_dashboard_from_panels(dashboard)
        preserve_focus(previous_win, target, opts.focus)
        return dashboard
    end

    vim.api.nvim_set_current_win(target)
    Snacks.dashboard.open({ win = vim.api.nvim_get_current_win() })
    local dashboard_buf = vim.api.nvim_get_current_buf()
    layout().evict_dashboard_from_panels(dashboard_buf)
    preserve_focus(previous_win, target, opts.focus)
    return dashboard_buf
end

function M.keep_single(buf)
    layout().evict_dashboard_from_panels(buf)
    for _, other in ipairs(dashboard_buffers()) do
        if other ~= buf then
            for _, win in ipairs(vim.fn.win_findbuf(other)) do
                if vim.api.nvim_win_is_valid(win) then
                    if layout().is_protected_window(win) then
                        layout().restore_panel(win)
                    else
                        vim.api.nvim_win_set_buf(win, buf)
                    end
                end
            end
            pcall(vim.api.nvim_buf_delete, other, { force = true })
        end
    end
end

return M
