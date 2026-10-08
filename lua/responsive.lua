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

---The explorer's width: a third of a narrow window is too much to give it.
function M.sidebar_width()
    local columns = vim.o.columns
    return math.max(18, math.min(30, math.floor(columns * 0.25)))
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

function M.setup()
    -- The dashboard reads its width when it is opened.
    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("Responsive", { clear = true }),
        callback = function()
            local ok, snacks = pcall(require, "snacks")
            if ok and snacks.config and snacks.config.dashboard then
                snacks.config.dashboard.width = M.dashboard_width()
            end
            -- A dashboard keeps the width it was drawn with, so draw it again.
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "snacks_dashboard" and ok then
                        pcall(snacks.dashboard.open, { buf = buf, win = win })
                    end
                end
            end)
            vim.cmd("redrawstatus!")
        end,
    })
end

return M
