-- ============================================================
-- LSP
-- ============================================================


-- ============================================================
-- Enable Language Servers
-- Uses Neovim's native vim.lsp.enable().
-- ============================================================

vim.lsp.enable({
    "lua_ls",                 -- Lua / Neovim config
    "ts_ls",                  -- TypeScript / JavaScript
    "bashls",                 -- Bash / shell scripts
    "cssls",                  -- CSS / SCSS / LESS
    "cssmodules_ls",          -- CSS Modules
    "texlab",                 -- LaTeX
    "markdown_oxide",         -- Markdown
    "oxlint",                 -- JS / TS linter
    "phptools",               -- PHP
    "ruff",                   -- Python linter
    "sourcekit",              -- Swift / Objective-C
    "superhtml",              -- HTML
    "tailwindcss",            -- Tailwind CSS
    "tinymist",               -- Typst
    "clangd",                 -- C / C++ / Objective-C
    "ty",                     -- Python type checker
    "sqruff",                 -- SQL linter / formatter
    "docker_language_server", -- Dockerfile
    "yamlls",                 -- YAML
})


-- ============================================================
-- LSP Inlay Hints
-- Enables native inlay hints per attached LSP buffer.
-- Wrapped in pcall because nightly can throw extmark col errors.
-- ============================================================

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        pcall(function()
            vim.lsp.inlay_hint.enable(true, {
                bufnr = args.buf,
            })
        end)
    end,
})


-- ============================================================
-- Native LSP Completion Experiments
-- Kept commented because blink.cmp handles completion instead.
-- ============================================================

-- vim.api.nvim_create_autocmd("LspAttach", {
--     group = vim.api.nvim_create_augroup("my.lsp", {}),
--     callback = function(args)
--         local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
--
--         if client:supports_method("textDocument/completion") then
--             vim.lsp.completion.enable(true, client.id, args.buf, {
--                 autotrigger = true,
--             })
--         end
--     end,
-- })
--
-- vim.keymap.set("i", "<C-Space>", function()
--     vim.lsp.completion.get()
-- end)


-- ============================================================
-- Completion Edit Helpers
-- Ctrl-Space changes current/next word and opens blink completion.
-- ============================================================

vim.keymap.set("n", "<C-Space>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    local keys
    if char == "" or char:match("%s") then
        keys = 'w"_ciw'
    else
        keys = '"_ciw'
    end

    vim.api.nvim_input(keys)

    vim.schedule(function()
        require("blink.cmp").show()
    end)
end, {
    noremap = true,
    silent = true,
    desc = "Change word or next word and show blink",
})

vim.keymap.set("x", "<C-Space>", function()
    vim.api.nvim_input('"_c')

    vim.schedule(function()
        require("blink.cmp").show()
    end)
end, {
    noremap = true,
    silent = true,
    desc = "Change selection and show blink completion",
})


-- ============================================================
-- Lua Language Server
-- Neovim-aware Lua settings.
-- ============================================================

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = {
                    "vim",
                    "require",
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})


-- ============================================================
-- blink.cmp
-- Main completion engine.
-- ============================================================

require("blink.cmp").setup({
    signature = {
        enabled = true,
    },

    sources = {
        default = {
            "lsp",
            "path",
            "snippets",
        },
    },

    completion = {
        documentation = {
            auto_show = true,
        },

        menu = {
            auto_show = true,
            draw = {
                treesitter = {
                    "lsp",
                },
                columns = {
                    {
                        "kind_icon",
                        "label",
                        "label_description",
                        gap = 1,
                    },
                    {
                        "kind",
                    },
                },
            },
        },
    },

    fuzzy = {
        implementation = "lua",
    },

    keymap = {
        preset = "default",

        ["<C-Space>"] = {
            "show",
            "show_documentation",
            "hide_documentation",
        },

        ["<CR>"] = {
            "accept",
            "fallback",
        },
    },
})


-- ============================================================
-- Xcodebuild / SourceKit
-- Adds Swift-only Xcode mappings when SourceKit attaches.
-- ============================================================

local group = vim.api.nvim_create_augroup("XcodebuildLSP", { clear = true })

local initialized = false
local debugger = {
    dap = nil,
    dapui = nil,
    xcodebuild = nil,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Xcodebuild" })
end

local function run_in_terminal(command, cwd, label, on_success)
    vim.cmd("botright 15new")

    local bufnr = vim.api.nvim_get_current_buf()
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false

    local job_id = vim.fn.jobstart(command, {
        cwd = cwd,
        term = true,
        on_exit = function(_, exit_code)
            vim.schedule(function()
                if exit_code == 0 then
                    if on_success then
                        pcall(on_success)
                    end
                    notify(label .. " finished")
                else
                    notify(
                        string.format("%s failed (exit code %d)", label, exit_code),
                        vim.log.levels.ERROR
                    )
                end
            end)
        end,
    })

    if job_id <= 0 then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        notify("Could not start " .. label, vim.log.levels.ERROR)
        return
    end

    vim.cmd("startinsert")
end

local function nearest_package_root()
    local filename = vim.api.nvim_buf_get_name(0)
    local start = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
    local manifest = vim.fs.find("Package.swift", {
        path = start,
        upward = true,
    })[1]

    return manifest and vim.fs.dirname(manifest) or nil
end

local function refresh_after_package_change()
    vim.cmd("checktime")

    local ok, build_server = pcall(require, "xcodebuild.integrations.xcode-build-server")
    if ok then
        pcall(build_server.run_config_if_enabled)
    end
end

local function project_settings()
    local ok, config = pcall(require, "xcodebuild.project.config")
    return ok and config.settings or {}
end

-- For an Xcode project/workspace this explicitly resolves/fetches its packages.
-- For a standalone Swift package it respects Package.resolved.
local function resolve_packages()
    vim.cmd("silent! wall")

    local settings = project_settings()
    local cwd = settings.workingDirectory or vim.fn.getcwd()

    if settings.swiftPackage then
        run_in_terminal({ "swift", "package", "resolve" }, cwd, "Swift package resolve", refresh_after_package_change)
        return
    end

    if settings.projectFile and settings.projectFile ~= "" then
        local command = { "xcodebuild", "-resolvePackageDependencies" }

        if settings.projectFile:match("%.xcworkspace$") then
            vim.list_extend(command, { "-workspace", settings.projectFile })
        elseif settings.projectFile:match("%.xcodeproj$") then
            vim.list_extend(command, { "-project", settings.projectFile })
        else
            notify("Configured project is not an .xcworkspace or .xcodeproj", vim.log.levels.ERROR)
            return
        end

        if settings.scheme and settings.scheme ~= "" then
            vim.list_extend(command, { "-scheme", settings.scheme })
        end

        run_in_terminal(command, cwd, "Xcode package resolution", refresh_after_package_change)
        return
    end

    local root = nearest_package_root()
    if root then
        run_in_terminal({ "swift", "package", "resolve" }, root, "Swift package resolve", refresh_after_package_change)
    else
        notify("Run :XcodebuildSetup or open a file below Package.swift", vim.log.levels.WARN)
    end
end

-- This is deliberately limited to a real Package.swift project. It updates
-- dependencies to the newest versions allowed by the manifest and rewrites
-- Package.resolved.
local function update_swift_package()
    vim.cmd("silent! wall")

    local settings = project_settings()
    local root

    if settings.swiftPackage then
        root = settings.workingDirectory or vim.fs.dirname(settings.swiftPackage)
    else
        root = nearest_package_root()
    end

    if not root then
        notify(
            "No Package.swift found. Use <leader>x and choose Resolve packages for an Xcode project.",
            vim.log.levels.WARN
        )
        return
    end

    run_in_terminal({ "swift", "package", "update" }, root, "Swift package update", refresh_after_package_change)
end

local function setup_debugger()
    local dap_ok, dap = pcall(require, "dap")
    if not dap_ok then
        notify("nvim-dap is not installed; debugger mappings were skipped", vim.log.levels.WARN)
        return
    end

    debugger.dap = dap

    local dapui_ok, dapui = pcall(require, "dapui")
    if dapui_ok then
        local ui_setup_ok, ui_setup_err = pcall(dapui.setup, {
            layouts = {
                {
                    elements = {
                        { id = "scopes",      size = 0.35 },
                        { id = "stacks",      size = 0.35 },
                        { id = "breakpoints", size = 0.15 },
                        { id = "watches",     size = 0.15 },
                    },
                    position = "left",
                    size = 44,
                },
                {
                    elements = {
                        { id = "repl",    size = 0.45 },
                        { id = "console", size = 0.55 },
                    },
                    position = "bottom",
                    size = 14,
                },
            },
        })

        if ui_setup_ok then
            debugger.dapui = dapui

            dap.listeners.before.attach.xcodebuild_dapui = function()
                dapui.open()
            end
            dap.listeners.before.launch.xcodebuild_dapui = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.xcodebuild_dapui = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.xcodebuild_dapui = function()
                dapui.close()
            end
        else
            notify("dap-ui setup failed: " .. tostring(ui_setup_err), vim.log.levels.WARN)
        end
    else
        notify("nvim-dap-ui is not installed; debugging will use DAP without the UI", vim.log.levels.WARN)
    end

    local xdap_ok, xdap = pcall(require, "xcodebuild.integrations.dap")
    if not xdap_ok then
        notify("Could not load xcodebuild DAP integration", vim.log.levels.ERROR)
        return
    end

    local setup_ok, setup_err = pcall(xdap.setup)
    if not setup_ok then
        notify("Xcodebuild debugger setup failed: " .. tostring(setup_err), vim.log.levels.ERROR)
        return
    end

    debugger.xcodebuild = xdap
end

local function setup_once(sourcekit_client_name)
    if initialized then
        return true
    end

    local ok, err = pcall(function()
        require("xcodebuild").setup({
            restore_on_start = true,
            auto_save = true,
            show_build_progress_bar = true,

            project_config = {
                store_in_project_dir = true,
                search_in_parent_dirs = true,
                reload_on_cwd_change = true,
            },

            test_search = {
                file_matching = "filename_lsp",
                target_matching = true,
                lsp_client = sourcekit_client_name,
                lsp_timeout = 400,
            },

            commands = {
                extra_build_args = { "-parallelizeTargets" },
                extra_test_args = { "-parallelizeTargets" },
                project_search_max_depth = 6,
                focus_simulator_on_app_launch = true,
            },

            logs = {
                auto_open_on_success_tests = false,
                auto_open_on_failed_tests = true,
                auto_open_on_success_build = false,
                auto_open_on_failed_build = true,
                auto_close_on_app_launch = false,
                live_logs = true,
                show_warnings = true,
            },

            console_logs = {
                enabled = true,
            },

            quickfix = {
                show_errors_on_quickfixlist = true,
                show_warnings_on_quickfixlist = true,
            },

            test_explorer = {
                enabled = true,
                auto_open = true,
                auto_focus = false,
                open_expanded = true,
            },

            code_coverage = {
                enabled = true,
                file_pattern = "*.swift",
            },

            integrations = {
                xcode_build_server = {
                    enabled = true,
                    guess_scheme = false,
                },

                -- Native xcrun lldb-dap is used on Xcode 16+.
                codelldb = {
                    enabled = false,
                },

                -- Enable after configuring physical-device debugging.
                pymobiledevice = {
                    enabled = true,
                    remote_debugger_port = 65123,
                },
            },
        })
    end)

    if not ok then
        notify("Xcodebuild setup failed: " .. tostring(err), vim.log.levels.ERROR)
        return false
    end

    if vim.fn.exists(":XcodebuildResolvePackages") == 0 then
        vim.api.nvim_create_user_command("XcodebuildResolvePackages", resolve_packages, {
            desc = "Resolve/fetch Xcode or Swift package dependencies",
        })
    end

    if vim.fn.exists(":SwiftPackageUpdate") == 0 then
        vim.api.nvim_create_user_command("SwiftPackageUpdate", update_swift_package, {
            desc = "Update the nearest standalone Swift package",
        })
    end

    setup_debugger()
    initialized = true
    return true
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local bufnr = args.buf

        if not client or (client.name ~= "sourcekit" and client.name ~= "sourcekit-lsp") then
            return
        end

        if vim.bo[bufnr].filetype ~= "swift" then
            return
        end

        if not setup_once(client.name) then
            return
        end

        -- setup() installs a BufReadPost loader, but this buffer is already
        -- open. Actions themselves live in the searchable <leader>x and zd
        -- selectors instead of creating dozens of buffer-local keymaps.
        if debugger.xcodebuild then pcall(debugger.xcodebuild.load_breakpoints, bufnr) end
    end,
})

-- ============================================================
-- nvim-navic
-- Shows current symbol/function path in winbar/statusline.
-- Attaches globally to any LSP with document symbols.
-- ============================================================

local navic = require("nvim-navic")

navic.setup({
    highlight = true,
    separator = " > ",
    depth_limit = 4,
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client
            and client.server_capabilities
            and client.server_capabilities.documentSymbolProvider
        then
            navic.attach(client, event.buf)
        end
    end,
})
