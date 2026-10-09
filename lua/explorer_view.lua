---How the file explorer uses its width. A terminal cannot draw one panel's text
---smaller, so a long name is helped in the two ways that remain: wrap it onto a
---second line, or give the git-marks column back to the name.
---
---Wrapping is automatic by default: the explorer wraps while some name is too
---long for it and goes back to one line per name when none is. ExplorerWrap
---cycles auto -> always -> never, for when you want it your way.
local M = {}

local state = { wrap = "auto", marks = true }

---Whether any name in the explorer is wider than its text area.
local function has_long_name(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local info = vim.fn.getwininfo(win)[1]
    local available = vim.api.nvim_win_get_width(win) - (info and info.textoff or 0)
    -- The icon is drawn as virtual text in front of the name.
    local icon = 2
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        -- Oil prefixes each entry with a hidden "/id " that is concealed.
        local shown = line:gsub("^/%d+ ", "")
        if vim.fn.strdisplaywidth(shown) + icon > available then return true end
    end
    return false
end

local function apply(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "oil" then return end

    local wrap
    if state.wrap == "auto" then
        wrap = has_long_name(win)
    else
        wrap = state.wrap == "always"
    end

    vim.wo[win].wrap = wrap
    vim.wo[win].breakindent = wrap
    vim.wo[win].breakindentopt = "shift:2"
    vim.wo[win].showbreak = wrap and "↪ " or ""
    -- The marks need two columns; hiding them returns that space to the names.
    vim.wo[win].signcolumn = state.marks and "yes:3" or "no"
end

local function apply_all()
    for _, win in ipairs(vim.api.nvim_list_wins()) do apply(win) end
end

local NEXT = { auto = "always", always = "never", never = "auto" }
local MESSAGE = {
    auto = "Explorer wraps long names automatically",
    always = "Explorer always wraps long names",
    never = "Explorer never wraps (one line per name)",
}

function M.toggle_wrap()
    state.wrap = NEXT[state.wrap]
    apply_all()
    vim.notify(MESSAGE[state.wrap], vim.log.levels.INFO, { title = "Explorer" })
end

function M.toggle_marks()
    state.marks = not state.marks
    apply_all()
    vim.notify(state.marks and "Explorer git marks on" or "Explorer git marks off (more room for names)", vim.log.levels.INFO, { title = "Explorer" })
end

function M.state() return vim.deepcopy(state) end

function M.setup()
    local group = vim.api.nvim_create_augroup("ExplorerView", { clear = true })
    -- The listing changes (a folder is entered, a file is made), the panel is
    -- resized, or a window is shown: look again.
    vim.api.nvim_create_autocmd(
        { "BufWinEnter", "FileType", "WinEnter", "WinResized", "VimResized", "TextChanged", "BufReadPost" },
        { group = group, pattern = "*", callback = function() vim.schedule(apply_all) end,
          desc = "Wrap the explorer when a name is too long for it" }
    )
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "OilEnter",
        callback = function() vim.schedule(apply_all) end,
        desc = "Look again when the explorer shows a new folder",
    })
    vim.api.nvim_create_user_command("ExplorerWrap", M.toggle_wrap, {
        desc = "Cycle explorer wrapping: automatic, always, never",
    })
    vim.api.nvim_create_user_command("ExplorerMarks", M.toggle_marks, {
        desc = "Show or hide the git marks column in the file explorer",
    })
end

return M
