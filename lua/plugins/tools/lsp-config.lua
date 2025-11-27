return {
	---------------------------------------------------------------------------
	-- Mason (LSP/DAP/Linter installer)
	---------------------------------------------------------------------------
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = "MasonUpdate",
		opts = {
			ui = {
				border = "rounded",
			},
		},
	},

	---------------------------------------------------------------------------
	-- Base LSP (diagnostics, etc.)
	---------------------------------------------------------------------------
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-------------------------------------------------------------------
			-- Diagnostics
			-------------------------------------------------------------------
			vim.diagnostic.config({
				virtual_text = { prefix = "●", spacing = 4 },
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
			})

			-------------------------------------------------------------------
			-- GLOBAL LSP + LSPSaga STYLE KEYMAPS (old behavior)
			-------------------------------------------------------------------
			local silent = { silent = true }

			-- Peek type definition
			vim.keymap.set(
				"n",
				"gp",
				"<cmd>Lspsaga peek_type_definition<CR>",
				vim.tbl_extend("keep", silent, { desc = "Peek Definition" })
			)
			vim.keymap.set(
				"n",
				"gd",
				"<cmd>Lspsaga peek_definition<CR>",
				vim.tbl_extend("keep", silent, { desc = "Peek Definition" })
			)
			vim.keymap.set(
				"n",
				"gtt",
				"<cmd>Lspsaga goto_type_definition<CR>",
				vim.tbl_extend("keep", silent, { desc = "Go to Type Definition" })
			)
			vim.keymap.set(
				"n",
				"gr",
				vim.lsp.buf.references,
				vim.tbl_extend("keep", silent, { desc = "Find References" })
			)
			vim.keymap.set(
				"n",
				"gtd",
				"<cmd>Lspsaga goto_definition<CR>",
				vim.tbl_extend("keep", silent, { desc = "Find References" })
			)

			vim.keymap.set(
				"n",
				"K",
				"<cmd>Lspsaga hover_doc<CR>",
				vim.tbl_extend("keep", silent, { desc = "Hover Documentation" })
			)

			vim.keymap.set("n", "zf", function()
				vim.lsp.buf.format({ async = true })
			end, vim.tbl_extend("keep", silent, { desc = "Format Document" }))

			vim.keymap.set(
				"n",
				"gR",
				"<cmd>Lspsaga rename<CR>",
				vim.tbl_extend("keep", silent, { desc = "Rename Symbol" })
			)
			vim.keymap.set(
				"n",
				"ga",
				"<cmd>Lspsaga code_action<CR>",
				vim.tbl_extend("keep", silent, { desc = "Code Action" })
			)

			-- Diagnostics
			vim.keymap.set(
				"n",
				"[d",
				vim.diagnostic.goto_prev,
				vim.tbl_extend("keep", silent, { desc = "Prev Diagnostic" })
			)
			vim.keymap.set(
				"n",
				"]d",
				vim.diagnostic.goto_next,
				vim.tbl_extend("keep", silent, { desc = "Next Diagnostic" })
			)
			vim.keymap.set(
				"n",
				"ge",
				"<cmd>Lspsaga show_line_diagnostics<CR>",
				vim.tbl_extend("keep", silent, { desc = "Line Diagnostics" })
			)
		end,
	},

	---------------------------------------------------------------------------
	-- Mason-LSPConfig (bridge Mason ↔ lspconfig)
	---------------------------------------------------------------------------
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")
			local lspconfig = require("lspconfig")

			-------------------------------------------------------------------
			-- Capabilities (nvim-cmp completion)
			-------------------------------------------------------------------
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- Apply globally
			lspconfig.util.default_config = vim.tbl_deep_extend("force", lspconfig.util.default_config, {
				capabilities = capabilities,
			})

			-------------------------------------------------------------------
			-- LSP Server Handlers
			-------------------------------------------------------------------
			local handlers = {
				-- Default handler
				function(server)
					lspconfig[server].setup({})
				end,

				-- lua_ls (special settings)
				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						settings = {
							Lua = {
								diagnostics = { globals = { "vim" } },
								workspace = {
									library = vim.api.nvim_get_runtime_file("", true),
									checkThirdParty = false,
								},
								telemetry = { enable = false },
							},
						},
					})
				end,
			}

			mason_lspconfig.setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"ts_ls",
					"html",
					"clangd",
					"vimls",
					"tailwindcss",
					"jsonls",
					"angularls",
					"rust_analyzer",
					"cssls",
				},
				automatic_installation = true,
				handlers = handlers,
			})
		end,
	},
	-------------------------------------------------------------------------------
	-- Mason + Null-LS (formatters & linters)
	-------------------------------------------------------------------------------
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup()

			-- 2. Setup mason-null-ls (this registers formatters/linters automatically)
			require("mason-null-ls").setup({
				ensure_installed = {
					"stylua",
					"prettier",
					"black",
					"clang-format",
					"shfmt",
					"ruff",
					"shellcheck",
					"eslint",
				},
				automatic_installation = true,
				handlers = {}, -- ← REQUIRED or nothing will load
			})
		end,
	},

	---------------------------------------------------------------------------
	-- LuaSnip (snippets)
	---------------------------------------------------------------------------
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		event = "InsertEnter",
		build = "make install_jsregexp",
		config = function()
			local luasnip = require("luasnip")

			luasnip.setup({
				history = true,
				updateevents = "TextChanged,TextChangedI",
			})

			vim.keymap.set({ "i", "s" }, "<C-l>", function()
				luasnip.jump(1)
			end, { silent = true, desc = "Snippet Jump Forward" })

			vim.keymap.set({ "i", "s" }, "<C-h>", function()
				luasnip.jump(-1)
			end, { silent = true, desc = "Snippet Jump Backward" })
		end,
	},

	---------------------------------------------------------------------------
	-- nvim-cmp (completion)
	---------------------------------------------------------------------------
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-signature-help",

			"onsails/lspkind.nvim",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				window = {
					completion = cmp.config.window.bordered({ border = "rounded" }),
					documentation = cmp.config.window.bordered({ border = "rounded" }),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),

					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				formatting = {
					format = lspkind.cmp_format({
						mode = "symbol_text",
						maxwidth = 50,
						ellipsis_char = "…",
						menu = {
							nvim_lsp = "[LSP]",
							luasnip = "[Snip]",
							buffer = "[Buf]",
							path = "[Path]",
						},
					}),
				},
				sources = cmp.config.sources({
					{
						name = "nvim_lsp",
						entry_filter = function(entry)
							return entry:get_kind() ~= cmp.lsp.CompletionItemKind.Snippet
						end,
					},
					{ name = "nvim_lsp_signature_help", max_item_count = 1 },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer", max_item_count = 5 },
				}),
			})
		end,
	},

	---------------------------------------------------------------------------
	-- Fidget (LSP progress / status)
	---------------------------------------------------------------------------
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	---------------------------------------------------------------------------
	-- LSPSaga (LSP UI)
	---------------------------------------------------------------------------
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			ui = {
				border = "rounded",
				title = true,
			},
			lightbulb = {
				enable = true,
				sign = false,
				virtual_text = true,
			},
			symbol_in_winbar = {
				enable = false,
			},
			finder = {
				max_height = 0.5,
				border = "rounded",
			},
		},
	},
}
