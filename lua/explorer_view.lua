---How the file explorer uses its width. A terminal cannot draw one panel's text
---smaller, so a long name is helped in the two ways that remain: wrap it onto a
---second line, or give the git-marks column back to the name. Both are toggled
---from the palette, and apply to every explorer window, now and when it reopens.
local M = {}

local state = { wrap = false, marks = true }

local function apply(win)
    if not vim.api.nvim_win_is_valid(win) then return end
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "oil" then return end

    vim.wo[win].wrap = state.wrap
    vim.wo[win].breakindent = state.wrap
    vim.wo[win].breakindentopt = "shift:2"
    vim.wo[win].showbreak = state.wrap and "↪ " or ""
    -- The marks need two columns; hiding them returns that space to the names.
    vim.wo[win].signcolumn = state.marks and "yes:3" or "no"
end

local function apply_all()
    for _, win in ipairs(vim.api.nvim_list_wins()) do apply(win) end
end

function M.toggle_wrap()
    state.wrap = not state.wrap
    apply_all()
    vim.notify(state.wrap and "Explorer wraps long names" or "Explorer shows names on one line", vim.log.levels.INFO, { title = "Explorer" })
end

function M.toggle_marks()
    state.marks = not state.marks
    apply_all()
    vim.notify(state.marks and "Explorer git marks on" or "Explorer git marks off (more room for names)", vim.log.levels.INFO, { title = "Explorer" })
end

function M.state() return vim.deepcopy(state) end

function M.setup()
    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("ExplorerView", { clear = true }),
        pattern = "*",
        callback = function() vim.schedule(apply_all) end,
        desc = "Keep the explorer's wrap and marks settings",
    })
    vim.api.nvim_create_user_command("ExplorerWrap", M.toggle_wrap, { desc = "Wrap or unwrap long names in the file explorer" })
    vim.api.nvim_create_user_command("ExplorerMarks", M.toggle_marks, { desc = "Show or hide the git marks column in the file explorer" })
end

return M
