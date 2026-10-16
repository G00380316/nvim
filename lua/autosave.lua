---Whether leaving insert mode saves the file. On by default; AutoSaveToggle (in
---the palette) turns it off and on, and the choice is kept for next time. Saving
---by hand (<C-s>) is always available and unaffected.
local M = {}

local file = vim.fn.stdpath("state") .. "/autosave.json"
local state ---@type boolean?

local function load()
    state = true
    if vim.fn.filereadable(file) ~= 1 then return end
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if ok and type(data) == "table" and data.on == false then state = false end
end

function M.enabled()
    if state == nil then load() end
    return state
end

---@param on boolean
function M.set(on)
    state = on
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode({ on = on }) }, file)
    vim.cmd("redrawstatus")
end

function M.toggle()
    M.set(not M.enabled())
    vim.notify(
        M.enabled() and "Auto-save on: leaving insert mode saves the file"
            or "Auto-save off: save with <C-s>",
        vim.log.levels.INFO,
        { title = "Auto-save" }
    )
end

function M.setup()
    vim.api.nvim_create_user_command("AutoSaveToggle", M.toggle, {
        desc = "Turn saving on leaving insert mode on or off",
    })
end

return M
