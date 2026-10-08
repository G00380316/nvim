---A title bar across the top of each panel -- explorer, terminal, quickfix, and
---the tool windows -- so which one you are in, and what it is showing, never
---has to be worked out from its contents. The focused panel's title is lit and
---the others are dim, which also answers "where is my cursor" at a glance.
---
---It is a window-local winbar: editor windows keep the symbol path from
---nvim-navic, and a window that stops being a panel gets that back.
local M = {}

local WINBAR = "%{%v:lua.require'panel_titles'.render()%}"

local function hl_attr(name, attr)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    return ok and hl[attr] or nil
end

local function define_highlights()
    vim.api.nvim_set_hl(0, "PanelTitle", {
        fg = hl_attr("Title", "fg") or hl_attr("Normal", "fg"),
        bg = hl_attr("CursorLine", "bg"),
        bold = true,
    })
    vim.api.nvim_set_hl(0, "PanelTitleNC", {
        fg = hl_attr("Comment", "fg"),
        bg = hl_attr("NormalFloat", "bg") or hl_attr("Normal", "bg"),
    })
end

local function folder(path)
    if not path or path == "" then return "" end
    return vim.fn.fnamemodify(path:gsub("/$", ""), ":~")
end

local function describe(win)
    local kind = require("ide_layout").panel_kind(win)
    local buf = vim.api.nvim_win_get_buf(win)

    if kind == "oil" then
        local ok, oil = pcall(require, "oil")
        local dir = ok and vim.api.nvim_buf_call(buf, function() return oil.get_current_dir() end)
        return "EXPLORER", folder(dir)
    elseif kind == "terminal" then
        return "TERMINAL", require("terminals").name(buf)
    elseif kind == "quickfix" then
        local info = vim.fn.getqflist({ title = 0, size = 0 })
        return "QUICKFIX", ("%s (%d)"):format(info.title or "", info.size or 0)
    end
    return (vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "TOOL"):upper(), ""
end

function M.render()
    local win = vim.g.statusline_winid
    if not (win and vim.api.nvim_win_is_valid(win)) then return "" end

    local label, detail = describe(win)
    local group = win == vim.api.nvim_get_current_win() and "PanelTitle" or "PanelTitleNC"
    -- % in a path would be read as a format code.
    detail = detail:gsub("%%", "%%%%")
    return ("%%#%s# %s%s%%#%s#"):format(group, label, detail ~= "" and ("  " .. detail) or "", group)
end

local function apply(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    local panel = require("ide_layout").is_panel_window(win)
    local current = vim.api.nvim_get_option_value("winbar", { win = win, scope = "local" })
    if panel and current ~= WINBAR then
        vim.api.nvim_set_option_value("winbar", WINBAR, { win = win, scope = "local" })
    elseif not panel and current == WINBAR then
        vim.api.nvim_set_option_value("winbar", "", { win = win, scope = "local" })
    end
end

function M.setup()
    define_highlights()
    local group = vim.api.nvim_create_augroup("panel_titles", { clear = true })

    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "FileType", "TermOpen" }, {
        group = group,
        callback = function()
            -- After ide_layout has finished claiming and placing windows.
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do apply(win) end
                vim.cmd("redrawstatus!")
            end)
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", { group = group, command = "redrawstatus!" })
end

return M
