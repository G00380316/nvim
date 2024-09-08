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
                    "cssls", -- additional server from new config
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
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
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
                "cssls", -- additional server from new config
            }

            for _, server in ipairs(servers) do
                lspconfig[server].setup({
                    capabilities = capabilities,
                })
            end

            -- Setting keybindings for LSP functionality
            vim.keymap.set({ "n", "v" }, "<C-i>", vim.lsp.buf.hover, {})
            vim.keymap.set({ "n", "v" }, "<C-v>", vim.lsp.buf.definition, {})

            -- Autocompletion setup using nvim-cmp and LuaSnip for snippets
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                }),
            })

            -- Diagnostic settings
            vim.diagnostic.config({
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end,
    },
}
