local dap = require("dap")
local dapui = require("dapui")

require("mason").setup({
    ui = {
        border = "rounded",
    },
})

-- Adapter names here are mason-nvim-dap names, not Mason package names.
-- Java is installed here but configured through nvim-jdtls in ftplugin/java.lua.
require("mason-nvim-dap").setup({
    ensure_installed = {
        "python",
        "js",
        "codelldb",
        "bash",
        "php",
        "javadbg",
        "javatest",
    },
    automatic_installation = false,
    handlers = {
        function(config)
            if config.name ~= "javadbg" and config.name ~= "javatest" then
                require("mason-nvim-dap").default_setup(config)
            end
        end,
    },
})

dap.set_log_level("WARN")
dap.defaults.fallback.terminal_win_cmd = "belowright 12new"

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticOk", linehl = "Visual" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })

dapui.setup({
    layouts = {
        {
            position = "right",
            size = 44,
            elements = {
                { id = "scopes", size = 0.35 },
                { id = "stacks", size = 0.25 },
                { id = "breakpoints", size = 0.20 },
                { id = "watches", size = 0.20 },
            },
        },
    },
    floating = { border = "rounded" },
    controls = { enabled = true },
})

require("nvim-dap-virtual-text").setup({
    commented = true,
    clear_on_continue = true,
    virt_text_pos = "eol",
})

dap.listeners.before.attach.dapui = function() dapui.open() end
dap.listeners.before.launch.dapui = function() dapui.open() end
dap.listeners.before.event_terminated.dapui = function() dapui.close() end
dap.listeners.before.event_exited.dapui = function() dapui.close() end
dap.listeners.before.disconnect.dapui = function() dapui.close() end

local workspace = require("workspace")

local function program_path()
    return vim.fn.input("Executable: ", workspace.get() .. "/", "file")
end

-- Xcode's lldb-dap gives Swift and Objective-C first-class support on macOS.
local lldb_dap = vim.fn.systemlist({ "xcrun", "-f", "lldb-dap" })[1]
local native_adapter = "codelldb"
if vim.v.shell_error == 0 and lldb_dap and lldb_dap ~= "" then
    native_adapter = "lldb"
    dap.adapters.lldb = {
        type = "executable",
        command = lldb_dap,
        name = "lldb-dap",
    }
end

local native_configurations = {
    {
        name = "Native: Launch executable",
        type = native_adapter,
        request = "launch",
        program = program_path,
        cwd = function() return workspace.get() end,
        stopOnEntry = false,
        runInTerminal = true,
    },
    {
        name = "Native: Attach to process",
        type = native_adapter,
        request = "attach",
        pid = require("dap.utils").pick_process,
        cwd = function() return workspace.get() end,
    },
}

for _, filetype in ipairs({ "c", "cpp", "objc", "objcpp", "swift" }) do
    dap.configurations[filetype] = native_configurations
end

local function python_path()
    local root = workspace.get()
    for _, candidate in ipairs({
        vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or "",
        root .. "/.venv/bin/python",
        root .. "/venv/bin/python",
        vim.fn.exepath("python3"),
    }) do
        if candidate ~= "" and vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    return "python3"
end

dap.configurations.python = {
    {
        name = "Python: Current file",
        type = "python",
        request = "launch",
        program = "${file}",
        cwd = function() return workspace.get() end,
        pythonPath = python_path,
        console = "integratedTerminal",
        justMyCode = true,
    },
    {
        name = "Python: Module",
        type = "python",
        request = "launch",
        module = function() return vim.fn.input("Module: ") end,
        cwd = function() return workspace.get() end,
        pythonPath = python_path,
        console = "integratedTerminal",
    },
}

local javascript_configurations = {
    {
        name = "Node: Current file",
        type = "pwa-node",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        console = "integratedTerminal",
    },
    {
        name = "Node: Attach to process",
        type = "pwa-node",
        request = "attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
    },
    {
        name = "Browser: localhost:3000",
        type = "pwa-chrome",
        request = "launch",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
    },
}

for _, filetype in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    dap.configurations[filetype] = javascript_configurations
end

local js_debug_server = vim.fn.stdpath("data")
    .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal" }) do
    dap.adapters[adapter] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
            command = vim.fn.exepath("node"),
            args = { js_debug_server, "${port}" },
        },
    }
end

-- Debug Lua running inside Neovim itself.
dap.adapters.nlua = function(callback, config)
    callback({
        type = "server",
        host = config.host or "127.0.0.1",
        port = config.port or 8086,
    })
end

dap.configurations.lua = {
    {
        name = "Lua: Attach to Neovim",
        type = "nlua",
        request = "attach",
        host = "127.0.0.1",
        port = 8086,
    },
}

local launch_filetypes = {
    ["pwa-node"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    ["pwa-chrome"] = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    python = { "python" },
    bash = { "sh" },
    php = { "php" },
    lldb = { "c", "cpp", "objc", "objcpp", "swift" },
    codelldb = { "c", "cpp", "objc", "objcpp", "swift" },
    java = { "java" },
}

local function load_launch_json()
    local path = workspace.get() .. "/.vscode/launch.json"
    if vim.fn.filereadable(path) == 1 then
        require("dap.ext.vscode").load_launchjs(path, launch_filetypes)
    end
end

load_launch_json()
vim.api.nvim_create_autocmd("User", {
    pattern = "WorkspaceChanged",
    callback = load_launch_json,
    desc = "Load workspace debug configurations",
})

-- Debug mappings follow the config's existing z-prefix style.
vim.keymap.set("n", "zdb", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
vim.keymap.set("n", "zdc", dap.continue, { desc = "Debug: Start/continue" })
vim.keymap.set("n", "zdn", dap.step_over, { desc = "Debug: Step over" })
vim.keymap.set("n", "zdi", dap.step_into, { desc = "Debug: Step into" })
vim.keymap.set("n", "zdo", dap.step_out, { desc = "Debug: Step out" })
vim.keymap.set("n", "zdr", dap.repl.toggle, { desc = "Debug: Toggle REPL" })
vim.keymap.set("n", "zdu", dapui.toggle, { desc = "Debug: Toggle UI" })
vim.keymap.set("n", "zdl", dap.run_last, { desc = "Debug: Run last" })
vim.keymap.set("n", "zdx", function()
    dap.terminate()
    dapui.close()
end, { desc = "Debug: Stop" })
vim.keymap.set({ "n", "v" }, "zde", dapui.eval, { desc = "Debug: Evaluate" })
vim.keymap.set("n", "zdv", function()
    require("osv").launch({ port = 8086 })
    vim.defer_fn(function() dap.run(dap.configurations.lua[1]) end, 100)
end, { desc = "Debug: This Neovim Lua" })

return {
    dap = dap,
    dapui = dapui,
}
