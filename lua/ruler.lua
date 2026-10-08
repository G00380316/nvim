---A vertical line at a fixed column in editor windows, so you can see where a
---line gets too long -- and the width that gq and the formatters wrap at. On at 80 to begin with; the width can be switched to 120
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

---Where each language server reads its line length, written as it wants it. The
---ruler is the one place the width is chosen; these follow it, so formatting a
---file wraps where the line on screen says it should.
local server_settings = {
    ruff = function(width) return { lineLength = width } end,
    lua_ls = function(width)
        return { Lua = { format = { defaultConfig = { max_line_length = tostring(width) } } } }
    end,
    tinymist = function(width) return { formatterPrintWidth = width } end,
}

---Tell one language server the width. With the ruler off, servers are put back
---to their own default by being sent nothing for it.
local function push_to_server(client)
    local build = server_settings[client.name]
    if not build then return end

    local width = state.enabled and state.width or nil
    local settings = width and build(width) or {}
    client.settings = vim.tbl_deep_extend("force", client.settings or {}, settings)
    pcall(client.notify, client, "workspace/didChangeConfiguration", { settings = client.settings })
end

local function push_to_servers()
    for _, client in ipairs(vim.lsp.get_clients()) do push_to_server(client) end
end

local function apply(win)
    local wanted = state.enabled and eligible(win)
    local value = wanted and tostring(state.width) or ""
    if vim.wo[win].colorcolumn ~= value then
        vim.api.nvim_set_option_value("colorcolumn", value, { win = win, scope = "local" })
    end

    -- gq, gw and the language servers' formatters wrap where the line is drawn.
    if eligible(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        local width = wanted and state.width or 0
        if vim.bo[buf].textwidth ~= width then vim.bo[buf].textwidth = width end
    end
end

local function apply_all()
    for _, win in ipairs(vim.api.nvim_list_wins()) do apply(win) end
    push_to_servers()
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

---Server settings for a width, exposed for checking.
function M.server_settings(name, width) return server_settings[name] and server_settings[name](width) end

function M.setup()
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType", "TermOpen" }, {
        group = vim.api.nvim_create_augroup("Ruler", { clear = true }),
        callback = function() vim.schedule(apply_all) end,
        desc = "Show the ruler column in editor windows only",
    })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("RulerLsp", { clear = true }),
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client then push_to_server(client) end
        end,
        desc = "Give language servers the ruler's line length",
    })
    vim.api.nvim_create_user_command("RulerToggle", M.toggle, { desc = "Show or hide the 80/120 column ruler" })
    vim.api.nvim_create_user_command("RulerWidth", M.switch_width, { desc = "Switch the ruler between column 80 and 120" })
    apply_all()
end

return M
