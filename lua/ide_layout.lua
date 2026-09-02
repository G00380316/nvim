local M = {}

local sidebar_opener
local routing_buffer = false
local focus_generation = 0

local function valid_window(win)
    return type(win) == "number" and vim.api.nvim_win_is_valid(win)
end

local function window_filetype(win)
    if not valid_window(win) then return "" end
    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
end

local function normal_window(win)
    return valid_window(win)
        and vim.api.nvim_win_get_config(win).relative == ""
        and not vim.wo[win].previewwindow
end

function M.panel_kind(win)
    if not normal_window(win) then return nil end

    local claimed = vim.w[win].ide_panel_kind
    if claimed == "oil" or claimed == "terminal" then return claimed end
    if vim.w[win].oil_sidebar then return "oil" end
    if vim.w[win].terminal_panel then return "terminal" end

    local filetype = window_filetype(win)
    if filetype == "oil" then return "oil" end
    if filetype == "floaterm" then return "terminal" end
    if filetype == "qf" then return "quickfix" end
end

function M.is_panel_window(win)
    return M.panel_kind(win) ~= nil
end

function M.is_protected_window(win)
    local kind = M.panel_kind(win)
    return kind == "oil" or kind == "terminal"
end

function M.is_editor_window(win)
    return normal_window(win) and not M.is_panel_window(win)
end

function M.claim_panel(kind, win)
    if not valid_window(win) then return end
    vim.w[win].ide_panel_kind = kind
    if kind == "oil" then
        vim.w[win].oil_sidebar = true
    elseif kind == "terminal" then
        vim.w[win].terminal_panel = true
    end
end

function M.mark_panel(kind, win, buf)
    if not valid_window(win) then return end
    M.claim_panel(kind, win)
    buf = buf or vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.w[win].ide_panel_buf = buf
    end
end

function M.clear_panel(win)
    if not valid_window(win) then return end
    vim.w[win].ide_panel_kind = nil
    vim.w[win].ide_panel_buf = nil
    vim.w[win].oil_sidebar = nil
    vim.w[win].terminal_panel = nil
end

function M.find_sidebar()
    local fallback
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if normal_window(win) then
            if vim.w[win].ide_panel_kind == "oil" or vim.w[win].oil_sidebar then
                return win
            end
            if window_filetype(win) == "oil" then fallback = fallback or win end
        end
    end
    return fallback
end

function M.find_editor_window(preferred)
    if M.is_editor_window(preferred) then return preferred end
    local current = vim.api.nvim_get_current_win()
    if M.is_editor_window(current) then return current end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if M.is_editor_window(win) then return win end
    end
end

function M.placeholder(win)
    if not valid_window(win) then return nil end
    M.clear_panel(win)

    local current = vim.api.nvim_win_get_buf(win)
    if vim.b[current].ide_layout_placeholder then return current end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.b[buf].ide_layout_placeholder = true
    vim.bo[buf].filetype = "ide_layout_placeholder"
    vim.api.nvim_win_set_buf(win, buf)
    return buf
end

function M.ensure_editor_window(opts)
    opts = opts or {}
    local existing = M.find_editor_window(opts.win)
    if existing then return existing end

    local base = M.find_sidebar()
    if not base then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if normal_window(win) then
                base = win
                if M.panel_kind(win) == "terminal" then break end
            end
        end
    end
    base = base or vim.api.nvim_get_current_win()
    if not valid_window(base) then return nil end

    local created
    vim.api.nvim_win_call(base, function()
        if M.panel_kind(base) == "oil" then
            vim.cmd("rightbelow vsplit")
        else
            vim.cmd("aboveleft split")
        end
        created = vim.api.nvim_get_current_win()
        M.clear_panel(created)
        M.placeholder(created)
    end)
    return created
end

function M.restore_panel(win)
    if not valid_window(win) then return false end
    local panel_buf = vim.w[win].ide_panel_buf
    if type(panel_buf) ~= "number" or not vim.api.nvim_buf_is_valid(panel_buf) then
        return false
    end
    vim.api.nvim_win_set_buf(win, panel_buf)
    return true
end

function M.remember_visible_panel_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local filetype = vim.bo[buf].filetype
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if filetype == "oil"
            and (vim.w[win].ide_panel_kind == "oil" or vim.w[win].oil_sidebar)
        then
            M.mark_panel("oil", win, buf)
        elseif filetype == "floaterm" then
            M.mark_panel("terminal", win, buf)
        end
    end
end

function M.register_sidebar_opener(opener)
    sidebar_opener = opener
end

function M.note_explicit_focus()
    focus_generation = focus_generation + 1
end

function M.focus_token()
    return focus_generation
end

function M.focus_unchanged(token)
    return token == focus_generation
end

function M.ensure_sidebar(opts)
    opts = opts or {}
    local sidebar = M.find_sidebar()
    if sidebar then
        if opts.after_open then opts.after_open(sidebar) end
        return sidebar
    end
    if sidebar_opener then return sidebar_opener(opts) end
end

-- Oil is established before the dashboard. A scratch placeholder keeps the
-- editor pane alive while Oil finishes opening, without briefly rendering the
-- dashboard against the wrong full-screen width.
function M.open_filler(opts)
    opts = opts or {}
    local request_focus_generation = focus_generation
    local target = M.find_editor_window(opts.win) or M.ensure_editor_window({ win = opts.win })
    if not target then return nil end

    local function fill(expected)
        if not M.is_editor_window(target) then return end
        if expected and vim.api.nvim_win_get_buf(target) ~= expected then return end
        require("editor_filler").open({
            win = target,
            focus = opts.focus ~= false and request_focus_generation == focus_generation,
        })
    end

    if opts.ensure_sidebar == false or M.find_sidebar() then
        fill()
        return vim.api.nvim_win_get_buf(target)
    end

    local placeholder = M.placeholder(target)
    local sidebar = M.ensure_sidebar({
        focus = false,
        after_open = function() fill(placeholder) end,
    })
    if not sidebar then fill(placeholder) end
    return vim.api.nvim_win_get_buf(target)
end

local function ordinary_editor_buffer(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return false end
    if vim.b[buf].ide_layout_placeholder then return false end
    if vim.bo[buf].buftype ~= "" then return false end
    local filetype = vim.bo[buf].filetype
    return filetype ~= "oil" and filetype ~= "snacks_dashboard"
end

-- A protected window keeps its identity even while :edit temporarily replaces
-- its buffer. Move that editor buffer to the center and restore the panel.
function M.route_editor_buffer(buf)
    if routing_buffer or not ordinary_editor_buffer(buf) then return false end

    local protected = {}
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if M.is_protected_window(win) then protected[#protected + 1] = win end
    end
    if #protected == 0 then return false end

    routing_buffer = true
    local target = M.find_editor_window()
    if not target then target = M.ensure_editor_window() end

    local ok = target and pcall(function()
        vim.api.nvim_win_set_buf(target, buf)
        for _, win in ipairs(protected) do
            M.restore_panel(win)
        end
        -- :edit finishes by restoring the command's source window, and Oil's
        -- follow-file callback also runs on the next scheduler tick. Reclaim
        -- focus after both have settled so it visibly lands in the editor.
        vim.defer_fn(function()
            local current = vim.api.nvim_get_current_win()
            local still_at_source = false
            for _, win in ipairs(protected) do
                if vim.api.nvim_win_is_valid(win)
                    and vim.api.nvim_win_get_buf(win) == buf
                then
                    M.restore_panel(win)
                end
                if win == current then
                    still_at_source = true
                end
            end
            if still_at_source and vim.api.nvim_win_is_valid(target) then
                vim.api.nvim_set_current_win(target)
            end
        end, 20)
    end)
    routing_buffer = false
    return ok == true
end

function M.evict_dashboard_from_panels(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if M.is_protected_window(win) then M.restore_panel(win) end
    end
end

return M
