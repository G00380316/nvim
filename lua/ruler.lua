---A vertical line at a fixed column in editor windows, so you can see where a
---line gets too long. On at 80 to begin with; the width can be switched to 120
---and the line toggled off, from the View menu or the palette.
local M = {}

local state = { enabled = true, width = 80 }
local WIDTHS = { 80, 120 }

---Only ordinary file windows: the explorer, terminal, dashboard, pickers and
---help have no use for a margin.
local function eligible(win)
    if not vim.api.nvim_win_is_valid(win) then return false end
    if vim.api.nvim_win_get_config(win).relative ~= "" then return false end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype ~= "" then return false end
    local ok, layout = pcall(require, "ide_layout")
    if ok and layout.is_panel_window(win) then return false end
    return vim.bo[buf].filetype ~= "snacks_dashboard"
end

local function apply(win)
    local wanted = state.enabled and eligible(win)
    local value = wanted and tostring(state.width) or ""
    if vim.wo[win].colorcolumn ~= value then
        vim.api.nvim_set_option_value("colorcolumn", value, { win = win, scope = "local" })
    end
end

local function apply_all()
    for _, win in ipairs(vim.api.nvim_list_wins()) do apply(win) end
end

function M.toggle()
    state.enabled = not state.enabled
    apply_all()
    vim.notify(state.enabled and ("Ruler on at column " .. state.width) or "Ruler off", vim.log.levels.INFO, { title = "Ruler" })
end

---Switch between the widths, turning the line on if it was off.
function M.switch_width()
    local index = 1
    for i, w in ipairs(WIDTHS) do
        if w == state.width then index = i end
    end
    state.width = WIDTHS[index % #WIDTHS + 1]
    state.enabled = true
    apply_all()
    vim.notify("Ruler at column " .. state.width, vim.log.levels.INFO, { title = "Ruler" })
end

function M.state() return vim.deepcopy(state) end

function M.setup()
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType", "TermOpen" }, {
        group = vim.api.nvim_create_augroup("Ruler", { clear = true }),
        callback = function() vim.schedule(apply_all) end,
        desc = "Show the ruler column in editor windows only",
    })
    vim.api.nvim_create_user_command("RulerToggle", M.toggle, { desc = "Show or hide the 80/120 column ruler" })
    vim.api.nvim_create_user_command("RulerWidth", M.switch_width, { desc = "Switch the ruler between column 80 and 120" })
    apply_all()
end

return M
