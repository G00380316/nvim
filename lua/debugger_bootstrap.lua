local M = {}

local function debugger()
    return require("debugger")
end

vim.api.nvim_create_user_command("DebugAdapters", function()
    debugger()
    vim.cmd("Mason")
end, { desc = "Open installed debugger adapters" })

return M
