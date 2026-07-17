local M = {}

local function debugger()
    return require("debugger")
end

local function map(mode, lhs, action, desc)
    vim.keymap.set(mode, lhs, function()
        action(debugger())
    end, { silent = true, desc = desc })
end

map("n", "zdb", function(debug) debug.dap.toggle_breakpoint() end, "Debug: Toggle breakpoint")
map("n", "zdc", function(debug) debug.dap.continue() end, "Debug: Start/continue")
map("n", "zdn", function(debug) debug.dap.step_over() end, "Debug: Step over")
map("n", "zdi", function(debug) debug.dap.step_into() end, "Debug: Step into")
map("n", "zdo", function(debug) debug.dap.step_out() end, "Debug: Step out")
map("n", "zdr", function(debug) debug.dap.repl.toggle() end, "Debug: Toggle REPL")
map("n", "zdu", function(debug) debug.dapui.toggle() end, "Debug: Toggle UI")
map("n", "zdl", function(debug) debug.dap.run_last() end, "Debug: Run last")
map("n", "zdx", function(debug)
    debug.dap.terminate()
    debug.dapui.close()
end, "Debug: Stop")
map({ "n", "v" }, "zde", function(debug) debug.dapui.eval() end, "Debug: Evaluate")
map("n", "zdv", function(debug)
    require("osv").launch({ port = 8086 })
    vim.defer_fn(function() debug.dap.run(debug.dap.configurations.lua[1]) end, 100)
end, "Debug: This Neovim Lua")

vim.api.nvim_create_user_command("DebugAdapters", function()
    debugger()
    vim.cmd("Mason")
end, { desc = "Open installed debugger adapters" })

return M
