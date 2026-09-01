local M = {}

local function command(value)
    return function() vim.cmd(value) end
end

local function debugger()
    return require("debugger")
end

local function xcode_debug(method)
    return function()
        local ok, integration = pcall(require, "xcodebuild.integrations.dap")
        if not ok or type(integration[method]) ~= "function" then
            error("Xcode debugging is available after SourceKit attaches to a Swift file")
        end
        integration[method]()
    end
end

-- Refine grouped actions here. A menu owns one memorable mapping; adding,
-- removing or renaming an action does not create another global keymap.
local menus = {
    terminal = {
        lhs = "<leader>t",
        title = "Terminal Actions",
        icon = "",
        actions = {
            { label = "Open or focus terminal", detail = "Return to the editor when already there", run = command("FocusTerminal") },
            { label = "New terminal", detail = "Create another project terminal", run = command("TerminalNew") },
            { label = "Split terminal panel", detail = "Add a side-by-side shell in the bottom row", run = command("TerminalSplit") },
            { label = "Choose terminal", detail = "Search the current project's live shells", run = command("TerminalList") },
            { label = "Edit terminal output", detail = "Copy scrollback into an editable buffer", run = command("TerminalEdit") },
        },
    },
    git = {
        lhs = "zg",
        title = "Git Actions",
        icon = "",
        actions = {
            { label = "Open LazyGit", detail = "Use this project's persistent LazyGit buffer", run = command("GitPanel") },
            { label = "Review changed files", detail = "Open the repository Diffview", run = command("DiffviewOpen") },
            { label = "Browse repository history", detail = "Open Diffview file history", run = command("DiffviewFileHistory") },
            { label = "Close Git tools", detail = "Close LazyGit and Diffview", run = command("GitCloseAll") },
        },
    },
    debug = {
        lhs = "zd",
        title = "Debug Actions",
        icon = "",
        actions = {
            { label = "Toggle breakpoint", detail = "Direct key: F9", run = function() debugger().dap.toggle_breakpoint() end },
            { label = "Start or continue", detail = "Direct key: F5", run = function() debugger().dap.continue() end },
            { label = "Run last configuration", detail = "Restart the most recent debug setup", run = function() debugger().dap.run_last() end },
            { label = "Step over", detail = "Direct key: F10", run = function() debugger().dap.step_over() end },
            { label = "Step into", detail = "Direct key: F11", run = function() debugger().dap.step_into() end },
            { label = "Step out", detail = "Direct key: F12", run = function() debugger().dap.step_out() end },
            { label = "Open debug UI", detail = "Show scopes, stacks, watches and console", run = function() debugger().dapui.open() end },
            { label = "Open REPL", detail = "Open the debugger command console", run = function() debugger().dap.repl.open() end },
            { label = "Evaluate under cursor", detail = "Inspect the expression at the cursor", run = function() debugger().dapui.eval() end },
            { label = "Stop debugging", detail = "Terminate and close the debug UI", run = function()
                local debug = debugger()
                debug.dap.terminate()
                debug.dapui.close()
            end },
            { label = "Debug this Neovim", detail = "Launch the Lua adapter on port 8086", run = function()
                local debug = debugger()
                require("osv").launch({ port = 8086 })
                vim.defer_fn(function() debug.dap.run(debug.dap.configurations.lua[1]) end, 100)
            end },
            { label = "Manage debug adapters", detail = "Open Mason after loading debugger support", run = command("DebugAdapters") },
        },
    },
    xcode = {
        lhs = "<leader>x",
        mode = { "n", "x" },
        title = "Xcode Actions",
        icon = "",
        actions = {
            { label = "Open Xcode action picker", detail = "Plugin's complete native action list", run = command("XcodebuildPicker") },
            { label = "Set up project", detail = "Choose or refresh the Xcode project", run = command("XcodebuildSetup") },
            { label = "Select scheme", detail = "Choose the build scheme", run = command("XcodebuildSelectScheme") },
            { label = "Select device", detail = "Choose simulator or device", run = command("XcodebuildSelectDevice") },
            { label = "Select test plan", detail = "Choose the active test plan", run = command("XcodebuildSelectTestPlan") },
            { label = "Show configuration", detail = "Inspect current project settings", run = command("XcodebuildShowConfig") },
            { label = "Build", detail = "Build the active scheme", run = command("XcodebuildBuild") },
            { label = "Clean build", detail = "Clean and rebuild", run = command("XcodebuildCleanBuild") },
            { label = "Build and run", detail = "Build then launch the app", run = command("XcodebuildBuildRun") },
            { label = "Run without building", detail = "Launch the existing build", run = command("XcodebuildRun") },
            { label = "Build for testing", detail = "Prepare test products", run = command("XcodebuildBuildForTesting") },
            { label = "Cancel current action", detail = "Stop the active build or test", run = command("XcodebuildCancel") },
            { label = "Clean DerivedData", detail = "Remove this project's build cache", run = command("XcodebuildCleanDerivedData") },
            { label = "Run all tests", detail = "Test the active scheme", run = command("XcodebuildTest") },
            { label = "Run selected tests", detail = "Test the current visual selection", run = command("XcodebuildTestSelected") },
            { label = "Run nearest test", detail = "Test nearest method or class", run = command("XcodebuildTestNearest") },
            { label = "Run test class", detail = "Test the current class", run = command("XcodebuildTestClass") },
            { label = "Rerun failing tests", detail = "Run only previous failures", run = command("XcodebuildTestFailing") },
            { label = "Repeat last tests", detail = "Repeat the previous test action", run = command("XcodebuildTestRepeat") },
            { label = "Toggle test explorer", detail = "Show or hide discovered tests", run = command("XcodebuildTestExplorerToggle") },
            { label = "Toggle logs", detail = "Show or hide build logs", run = command("XcodebuildToggleLogs") },
            { label = "Toggle code coverage", detail = "Enable or disable coverage", run = command("XcodebuildToggleCodeCoverage") },
            { label = "Show coverage report", detail = "Open the code coverage report", run = command("XcodebuildShowCodeCoverageReport") },
            { label = "Project manager", detail = "Manage project selection and settings", run = command("XcodebuildProjectManager") },
            { label = "Open in Xcode", detail = "Reveal this project in Xcode", run = command("XcodebuildOpenInXcode") },
            { label = "Code actions", detail = "Open Xcodebuild code actions", run = command("XcodebuildCodeActions") },
            { label = "Approve macros", detail = "Approve Swift package macros", run = command("XcodebuildApproveMacros") },
            { label = "Resolve packages", detail = "Fetch Xcode or Swift package dependencies", run = command("XcodebuildResolvePackages") },
            { label = "Update Swift packages", detail = "Update package versions", run = command("SwiftPackageUpdate") },
            { label = "Build and debug", detail = "Build then start the Xcode DAP session", run = xcode_debug("build_and_debug") },
            { label = "Debug without building", detail = "Start from the existing app build", run = xcode_debug("debug_without_build") },
            { label = "Attach debugger", detail = "Attach to a running application", run = xcode_debug("attach_and_debug") },
            { label = "Debug nearest test", detail = "Launch the nearest test under DAP", run = xcode_debug("debug_func_test") },
            { label = "Debug test class", detail = "Launch the test class under DAP", run = xcode_debug("debug_class_tests") },
        },
    },
    leetcode = {
        lhs = "zl",
        title = "LeetCode Actions",
        icon = "󰘦",
        actions = {
            { label = "Open LeetCode", detail = "Open the LeetCode workspace", run = command("Leet") },
            { label = "Run solution", detail = "Test the current solution", run = command("Leet Run") },
            { label = "Submit solution", detail = "Submit the current solution", run = command("Leet Submit") },
            { label = "List problems", detail = "Choose another problem", run = command("Leet List") },
            { label = "Reset solution", detail = "Reset the current problem buffer", run = command("Leet Reset") },
        },
    },
    server = {
        lhs = "zs",
        title = "Live Server Actions",
        icon = "󰖟",
        actions = {
            { label = "Start or stop server", detail = "Toggle this project's live server", run = command("LiveServer toggle") },
            { label = "Open server manager", detail = "Inspect all live-server instances", run = command("LiveServer") },
            { label = "Open page in browser", detail = "Open the current served page", run = command("LiveServer open") },
            { label = "Show server logs", detail = "Tail live-server output", run = command("LiveServer logs") },
            { label = "Restart server", detail = "Restart on the same port", run = command("LiveServer restart") },
        },
    },
}

M.menus = menus

function M.pick(menu)
    local items = {}
    for index, action in ipairs(menu.actions) do
        items[index] = {
            text = table.concat({ action.label, action.detail or "" }, " "),
            label = action.label,
            detail = action.detail or "",
            action = action,
        }
    end

    require("snacks").picker.pick({
        title = menu.title .. "  ·  type to filter  ·  Ctrl-C closes",
        items = items,
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            return {
                { menu.icon .. "  ", "SnacksPickerIcon" },
                { require("snacks").picker.util.align(item.label, 30), "SnacksPickerLabel" },
                { "  " },
                { item.detail, "SnacksPickerDesc" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function()
                local ok, err = pcall(item.action.run)
                if not ok then vim.notify(tostring(err), vim.log.levels.ERROR, { title = menu.title }) end
            end)
        end,
    })
end

function M.open(name)
    local menu = menus[name]
    if not menu then
        vim.notify("Unknown action menu: " .. tostring(name), vim.log.levels.ERROR)
        return
    end
    M.pick(menu)
end

function M.setup()
    -- Also clean mappings left in memory when this config is re-sourced after
    -- switching from per-action shortcuts to selectors.
    local legacy = {
        n = {
            "<leader>v", "zt", "zgd", "zgh",
            "zdb", "zdc", "zdn", "zdi", "zdo", "zdr", "zdu", "zdl", "zdx", "zde", "zdv",
            "zlo", "zlt", "zls", "zll", "zlr",
            "zss", "zsm", "zso", "zsl", "zsr",
        },
        t = { "zg" },
        v = { "zde" },
    }
    for mode, mappings in pairs(legacy) do
        for _, lhs in ipairs(mappings) do pcall(vim.keymap.del, mode, lhs) end
    end

    local legacy_buffer_maps = {
        "<leader>xl", "<leader>xs", "<leader>xp", "<leader>xd", "<leader>xP", "<leader>xi",
        "<leader>xb", "<leader>xB", "<leader>xr", "<leader>xR", "<leader>xf", "<leader>xk", "<leader>xD",
        "<leader>xt", "<leader>xn", "<leader>xT", "<leader>xF", "<leader>x.", "<leader>xe",
        "<leader>xg", "<leader>xc", "<leader>xC", "<leader>xm", "<leader>xo", "<leader>xa", "<leader>xM",
        "<leader>xu", "<leader>xU", "zdd", "zdr", "zda", "zdt", "zdT",
        "<leader>db", "<leader>dB", "<leader>dm", "<leader>dc", "<leader>dn", "<leader>di",
        "<leader>do", "<leader>dp", "<leader>dx", "<leader>du", "<leader>de",
    }
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            for _, lhs in ipairs(legacy_buffer_maps) do
                pcall(vim.keymap.del, "n", lhs, { buffer = buf })
                pcall(vim.keymap.del, "x", lhs, { buffer = buf })
            end
        end
    end

    for name, menu in pairs(menus) do
        vim.keymap.set(menu.mode or "n", menu.lhs, function() M.open(name) end, {
            noremap = true,
            silent = true,
            desc = "Open " .. menu.title,
        })
    end

    -- These are worth keeping direct because they are repeated while stopped
    -- at a breakpoint; reopening a selector for every step would be friction.
    local direct_debug = {
        { "<F5>", function() debugger().dap.continue() end, "Debug: start or continue" },
        { "<F9>", function() debugger().dap.toggle_breakpoint() end, "Debug: toggle breakpoint" },
        { "<F10>", function() debugger().dap.step_over() end, "Debug: step over" },
        { "<F11>", function() debugger().dap.step_into() end, "Debug: step into" },
        { "<F12>", function() debugger().dap.step_out() end, "Debug: step out" },
    }
    for _, mapping in ipairs(direct_debug) do
        vim.keymap.set("n", mapping[1], mapping[2], { silent = true, desc = mapping[3] })
    end

    pcall(vim.api.nvim_del_user_command, "ActionMenu")
    vim.api.nvim_create_user_command("ActionMenu", function(args) M.open(args.args) end, {
        nargs = 1,
        complete = function() return vim.tbl_keys(menus) end,
        desc = "Open a grouped action selector",
    })
end

return M
