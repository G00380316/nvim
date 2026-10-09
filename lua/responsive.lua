---Sizes that follow the Neovim window. The same config has to be comfortable
---full screen, in half a screen beside another window, and in a kitty split a
---third of a monitor wide, so nothing here is a fixed number of columns.
local M = {}

---@return "wide"|"normal"|"compact"|"tiny"
function M.profile()
    local columns = vim.o.columns
    if columns >= 140 then return "wide" end
    if columns >= 100 then return "normal" end
    if columns >= 70 then return "compact" end
    return "tiny"
end

local sidebar_wide = false

---The explorer's width: a third of a narrow window is too much to give it. When
---widened (ExplorerWiden) it takes up to 45% of the window, 60 columns at most.
function M.sidebar_width()
    local columns = vim.o.columns
    if sidebar_wide then
        return math.max(24, math.min(60, math.floor(columns * 0.45)))
    end
    return math.max(18, math.min(30, math.floor(columns * 0.25)))
end

---Switch the explorer between its normal and wide width, and apply it now.
function M.toggle_sidebar_width()
    sidebar_wide = not sidebar_wide
    local width = M.sidebar_width()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "oil" and vim.w[win].oil_sidebar then
            pcall(vim.api.nvim_win_set_width, win, width)
        end
    end
    vim.notify(sidebar_wide and "Explorer wide" or "Explorer normal width", vim.log.levels.INFO, { title = "Explorer" })
end

---Columns left for the editor beside the explorer.
function M.editor_width()
    return math.max(20, vim.o.columns - M.sidebar_width() - 1)
end

---The dashboard has to fit in the window it is drawn in.
function M.dashboard_width()
    return math.max(24, math.min(48, M.editor_width() - 4))
end

---Whether the logo has room: it is 33 columns wide and 6 tall.
function M.dashboard_header()
    return M.editor_width() >= 40 and vim.o.lines >= 26
end

---The tallest the terminal panel may be: never more than 40% of the window, so a
---short window keeps room to edit, and always at least 5 rows to be usable.
function M.terminal_max_height()
    return math.max(5, math.min(vim.o.lines - 6, math.floor(vim.o.lines * 0.4)))
end

---Statusline parts, in the order they go as the window narrows.
function M.show_statusline_part(name)
    local columns = vim.o.columns
    local from = { lsp = 120, project = 90, terminals = 80, branch = 70 }
    return columns >= (from[name] or 0)
end

local drawn_width, drawn_header
local redraw_timer

---A dashboard keeps the width it was drawn with, so draw it again -- as a new
---buffer. Opening a second dashboard on the same buffer registers a second set
---of cleanup autocmds, and the two then fight over deleting one group when the
---buffer goes ("E367: No such group").
local function redraw_dashboards()
    local ok, snacks = pcall(require, "snacks")
    if not ok then return end

    local width, header = M.dashboard_width(), M.dashboard_header()
    if width == drawn_width and header == drawn_header then return end
    drawn_width, drawn_header = width, header
    snacks.config.dashboard.width = width

    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local old = vim.api.nvim_win_get_buf(win)
        if vim.bo[old].filetype == "snacks_dashboard" then
            local current = vim.api.nvim_get_current_win()
            vim.api.nvim_win_call(win, function()
                if pcall(snacks.dashboard.open, { win = win }) then
                    pcall(vim.api.nvim_buf_delete, old, { force = true })
                end
            end)
            if vim.api.nvim_win_is_valid(current) then pcall(vim.api.nvim_set_current_win, current) end
        end
    end
end

function M.setup()
    drawn_width, drawn_header = M.dashboard_width(), M.dashboard_header()
    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("Responsive", { clear = true }),
        callback = function()
            -- A drag fires this for every step; draw once it settles.
            if redraw_timer then redraw_timer:stop() end
            redraw_timer = vim.defer_fn(function()
                redraw_timer = nil
                redraw_dashboards()
            end, 120)
            vim.cmd("redrawstatus!")
        end,
    })
end

return M
