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
    "jdtls",                  -- Java
    "markdown_oxide",         -- Markdown
    "oxlint",                 -- JS / TS linter
    "phptools",               -- PHP
    "quick-lint-js",          -- Fast JavaScript syntax linter
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

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("XcodebuildLSP", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client and client.name == "sourcekit" then
            local bufnr = args.buf

            if not _G.xcodebuild_initialized then
                require("xcodebuild").setup({
                    show_build_progress_bar = true,
                    logs = {
                        auto_open_on_success = false,
                        auto_open_on_error = true,
                    },
                })

                _G.xcodebuild_initialized = true
            end

            vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildPicker<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Picker",
            })

            vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Run",
            })

            vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Run Test",
            })

            vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Select Device",
            })

            vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectScheme<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Select Scheme",
            })

            vim.keymap.set("n", "<leader>xs", "<cmd>XcodebuildSetup<CR>", {
                buffer = bufnr,
                silent = true,
                desc = "Xcode Setup",
            })

            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                    local ok, err = pcall(vim.cmd, "XcodebuildBuildRun")

                    if not ok then
                        vim.notify(
                            "XcodebuildBuildRun failed: " .. tostring(err),
                            vim.log.levels.WARN
                        )

                        local setup_ok, setup_err = pcall(vim.cmd, "XcodebuildSetup")
                        if not setup_ok then
                            vim.notify(
                                "XcodebuildSetup failed: " .. tostring(setup_err),
                                vim.log.levels.ERROR
                            )
                        end
                    end
                end,
            })
        end
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
