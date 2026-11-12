---A table is drawn once per buffer, to fit one window. When the same note is
---open in two windows of different widths (a split), whichever was drawn last
---decides, and the other shows a table cut off or with rows missing. So the
---table is drawn for the narrowest window showing it: it fits everywhere.
local M = {}

local timers = {}

local function fit(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local wins = vim.fn.win_findbuf(buf)
    if #wins < 2 then return end
    local narrowest, width = nil, math.huge
    for _, win in ipairs(wins) do
        local w = vim.api.nvim_win_get_width(win)
        if w < width then narrowest, width = win, w end
    end
    local ok, ui = pcall(require, "render-markdown.core.ui")
    if ok and narrowest then pcall(ui.update, buf, narrowest, "TableFit", true) end
end

---Wait for render-markdown's own redraw (it debounces) before correcting it.
local function fit_soon(buf)
    if timers[buf] then timers[buf]:stop() else timers[buf] = vim.uv.new_timer() end
    timers[buf]:start(250, 0, vim.schedule_wrap(function() fit(buf) end))
end

function M.setup()
    vim.api.nvim_create_autocmd({ "WinResized", "WinNew", "WinClosed", "WinEnter", "BufWinEnter" }, {
        group = vim.api.nvim_create_augroup("MarkdownTableFit", { clear = true }),
        callback = function()
            local seen = {}
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local buf = vim.api.nvim_win_get_buf(win)
                local filetype = vim.bo[buf].filetype
                if not seen[buf] and (filetype == "markdown" or filetype == "jupyter") then
                    seen[buf] = true
                    fit_soon(buf)
                end
            end
        end,
    })
end

return M
