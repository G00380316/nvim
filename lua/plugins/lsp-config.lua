return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "pyright",
                    "ts_ls",
                    "jdtls",
                    "html",
                    "clangd",
                    "vimls",
                    "tailwindcss",
                    "jsonls",
                    "angularls",
                    "arduino_language_server",
                    "rust_analyzer",
                    "cssls",
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/nvim-cmp",
            "j-hui/fidget.nvim",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "ray-x/cmp-treesitter",
        },
        config = function()
            local cmp = require("cmp")
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            -- Setup fidget for LSP progress indicators
            require("fidget").setup({})

            -- Function to setup LSP servers
            local lspconfig = require("lspconfig")
            local servers = {
                "lua_ls",
                "pyright",
                "ts_ls",
                "jdtls",
                "html",
                "clangd",
                "vimls",
                "tailwindcss",
                "jsonls",
                "angularls",
                "arduino_language_server",
                "rust_analyzer",
                "cssls",
            }

            for _, server in ipairs(servers) do
                lspconfig[server].setup({
                    capabilities = capabilities,
                })
            end

            -- Setting keybindings for LSP functionality
            vim.keymap.set({ "n", "v" }, "<C-i>", vim.lsp.buf.hover, {})
            vim.keymap.set({ "n", "v" }, "<C-v>", vim.lsp.buf.definition, {})

            -- Autocompletion setup
            cmp.setup({
                completion = {
                    completeopt = "menu,menuone,noinsert",
                    -- Show the menu with one item without auto-inserting
                },
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-y>"] = cmp.mapping.confirm({ select = false }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp",                max_item_count = 3 },
                    { name = "nvim-lsp-signature-help", max_item_count = 1 },
                    { name = "rg" },
                    { name = "treesitter",              max_item_count = 1 },
                    { name = "path" },
                }, {
                    { name = "buffer", max_item_count = 1 },
                }),
            })

            -- For command line completion
            --[[            cmp.setup.cmdline(':', {
                sources = cmp.config.sources({
                    { name = "path",    max_item_count = 2 },
                    { name = "cmdline", max_item_count = 3 },
                }),
            })
]]
            -- Diagnostics to quickfix keymap
            vim.keymap.set({ "n", "v" }, "<C-l>", function()
                -- Function to show diagnostics grouped by severity
                local function show_diagnostics_by_severity()
                    local diagnostics = vim.diagnostic.get(0)
                    local grouped = {
                        [vim.diagnostic.severity.ERROR] = {},
                        [vim.diagnostic.severity.WARN] = {},
                        [vim.diagnostic.severity.INFO] = {},
                        [vim.diagnostic.severity.HINT] = {},
                    }

                    -- Group diagnostics by severity
                    for _, diag in ipairs(diagnostics) do
                        table.insert(grouped[diag.severity], diag)
                    end

                    -- Create a list for the UI select that includes header separators
                    local menu_items = {}

                    -- Add headers and diagnostics under each severity
                    local function add_group(severity, header, icon)
                        if #grouped[severity] > 0 then
                            table.insert(menu_items,
                                { header = icon .. "  " .. header, is_header = true, severity = severity, icon = icon }) -- Add severity as header
                            for _, diag in ipairs(grouped[severity]) do
                                table.insert(menu_items,
                                    string.format("Line %d, Col %d: %s", diag.lnum + 1, diag.col + 1, diag.message))
                            end
                        end
                    end

                    add_group(vim.diagnostic.severity.ERROR, "Errors", " ")
                    add_group(vim.diagnostic.severity.WARN, "Warnings", " ")
                    add_group(vim.diagnostic.severity.INFO, "Info", " ")
                    add_group(vim.diagnostic.severity.HINT, "Hints", " ")

                    -- Use dressing.nvim's `vim.ui.select` to display the diagnostics with severity headers
                    vim.ui.select(menu_items, {
                        prompt = "Select Diagnostic",
                        format_item = function(item)
                            -- If it's a header, just return it as is (non-clickable)
                            if item.is_header then
                                return item.header
                            else
                                -- If it's a diagnostic, return the formatted message
                                return item
                            end
                        end,
                    }, function(selected)
                        if selected then
                            -- If it's a header, just re-call the function to display the group again
                            if selected.is_header then
                                -- Re-call the function to show the group again
                                show_diagnostics_by_severity()
                                return
                            end

                            -- If it's a diagnostic message, go to the line and column
                            if not selected:match("Errors") and not selected:match("Warnings") and not selected:match("Info") and not selected:match("Hints") then
                                local line, col = selected:match("Line (%d+), Col (%d+)")
                                vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) })
                            end
                        end
                    end)
                end

                -- Call the function to show diagnostics initially
                show_diagnostics_by_severity()
            end, { desc = "Show Grouped Diagnostics with Headers in Dressing" })
            -- Diagnostic settings
            vim.diagnostic.config({
                virtual_text = true,     -- Disable inline diagnostic messages
                signs = true,            -- Enable signs in the sign column
                underline = true,        -- Enable underlining
                update_in_insert = true, -- Update diagnostics while typing
                severity_sort = true,    -- Sort diagnostics by severity
            })
        end,
    },
}
