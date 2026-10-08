---A title bar across the top of each panel -- explorer, terminal, quickfix, and
---the tool windows -- so which one you are in, and what it is showing, never
---has to be worked out from its contents. The focused panel's title is lit and
---the others are dim, which also answers "where is my cursor" at a glance.
---
---It is a window-local winbar: editor windows keep the symbol path from
---nvim-navic, and a window that stops being a panel gets that back.
local M = {}

-- The window id is written into the string: it is this window's own winbar, and
-- g:statusline_winid is not reliably set while the title is being drawn.
local function winbar_for(win)
    return ("%%{%%v:lua.require'panel_titles'.render(%d)%%}"):format(win)
end

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
    local peers = require("workspace").recent(20)
    return require("names").label(path, peers)
end

local function describe(win)
    local kind = require("ide_layout").panel_kind(win)
    local buf = vim.api.nvim_win_get_buf(win)

    if kind == "oil" then
        -- Not nvim_buf_call: a winbar is drawn under a text lock, where
        -- switching buffers is an error.
        local ok, oil = pcall(require, "oil")
        local dir = ok and oil.get_current_dir(buf)
        return "EXPLORER", folder(dir)
    elseif kind == "terminal" then
        return "TERMINAL", require("terminals").name(buf)
    elseif kind == "quickfix" then
        local info = vim.fn.getqflist({ title = 0, size = 0 })
        return "QUICKFIX", ("%s (%d)"):format(info.title or "", info.size or 0)
    end
    return (vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "TOOL"):upper(), ""
end

local function render(win)
    if not (win and vim.api.nvim_win_is_valid(win)) then return "" end

    local label, detail = describe(win)
    local group = win == vim.api.nvim_get_current_win() and "PanelTitle" or "PanelTitleNC"
    -- % in a path would be read as a format code.
    detail = detail:gsub("%%", "%%%%")
    return ("%%#%s# %s%s%%#%s#"):format(group, label, detail ~= "" and ("  " .. detail) or "", group)
end

---A failure here would blank the title bar and, repeated every redraw, flood
---the screen with errors; a title is never worth that.
function M.render(win)
    local ok, text = pcall(render, win)
    return ok and text or ""
end

local function apply(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    -- The dashboard is a tool window to the layout, but it has its own header.
    local buf = vim.api.nvim_win_get_buf(win)
    local panel = vim.bo[buf].filetype ~= "snacks_dashboard"
        and require("ide_layout").is_panel_window(win)
    local current = vim.api.nvim_get_option_value("winbar", { win = win, scope = "local" })
    if panel and current ~= winbar_for(win) then
        vim.api.nvim_set_option_value("winbar", winbar_for(win), { win = win, scope = "local" })
    elseif not panel and current:find("panel_titles", 1, true) then
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
