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
                    ["<Space>"] = cmp.mapping.confirm({ select = true }),
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
            cmp.setup.cmdline(':', {
                sources = cmp.config.sources({
                    { name = "path",    max_item_count = 2 },
                    { name = "cmdline", max_item_count = 3 },
                }),
            })

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
