return {
	---------------------------------------------------------------------------
	-- Mason (LSP/DAP/Linter installer)
	---------------------------------------------------------------------------
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			log_level = vim.log.levels.INFO,
		},
	},

	---------------------------------------------------------------------------
	-- LSPSaga (LSP UI) - Moved up so keymaps can use it
	---------------------------------------------------------------------------
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			ui = {
				border = "rounded",
				title = true,
				devicon = true,
			},
			lightbulb = {
				enable = true,
				sign = true,
				sign_priority = 40,
				virtual_text = false,
			},
			symbol_in_winbar = {
				enable = true,
				separator = "  ",
				show_file = true,
			},
			finder = {
				max_height = 0.5,
				min_width = 30,
				keys = {
					jump_to = "p",
					expand_or_jump = "o",
					vsplit = "s",
					split = "i",
					tab = "t",
					tabnew = "r",
					quit = { "q", "<ESC>" },
					close_in_preview = "<ESC>",
				},
			},
		},
		init = function()
			-- Disable default LSPSaga keymaps since we define our own
			vim.g.lspsaga_disable_keymaps = true
		end,
	},

	---------------------------------------------------------------------------
	-- Base LSP (diagnostics, etc.)
	---------------------------------------------------------------------------
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"nvimdev/lspsaga.nvim",
		},
		config = function()
			-------------------------------------------------------------------
			-- Diagnostics
			-------------------------------------------------------------------
			local signs = {
				Error = "󰅚 ",
				Warn = "󰀪 ",
				Hint = "󰌶 ",
				Info = " ",
			}

			-- Define diagnostic signs for gutter
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
			end

			vim.diagnostic.config({
				virtual_text = {
					prefix = "●",
					spacing = 4,
					-- Fixed: Use correct severity mapping
					format = function(diagnostic)
						local severity = diagnostic.severity
						local severity_map = {
							[vim.diagnostic.severity.ERROR] = signs.Error,
							[vim.diagnostic.severity.WARN] = signs.Warn,
							[vim.diagnostic.severity.INFO] = signs.Info,
							[vim.diagnostic.severity.HINT] = signs.Hint,
						}
						local icon = severity_map[severity] or "● "
						return icon .. diagnostic.message
					end,
				},
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "if_many",
					header = "",
					prefix = "",
				},
			})

			-------------------------------------------------------------------
			-- LSP Keymaps (buffer-local when LSP attaches)
			-------------------------------------------------------------------
			local on_attach = function(client, bufnr)
				-- Buffer local keymaps
				local bufopts = { noremap = true, silent = true, buffer = bufnr }

				-- Peek type definition
				vim.keymap.set(
					"n",
					"gp",
					"<cmd>Lspsaga peek_type_definition<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Peek Type Definition" })
				)

				vim.keymap.set(
					"n",
					"gd",
					"<cmd>Lspsaga peek_definition<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Peek Definition" })
				)

				vim.keymap.set(
					"n",
					"gtt",
					"<cmd>Lspsaga goto_type_definition<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Go to Type Definition" })
				)

				vim.keymap.set(
					"n",
					"gR",
					vim.lsp.buf.references,
					vim.tbl_extend("force", bufopts, { desc = "Find References" })
				)

				vim.keymap.set(
					"n",
					"gtd",
					"<cmd>Lspsaga goto_definition<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Go to Definition" })
				)

				vim.keymap.set(
					"n",
					"K",
					"<cmd>Lspsaga hover_doc<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Hover Documentation" })
				)

				vim.keymap.set("n", "zf", function()
					vim.lsp.buf.format({ async = true })
				end, vim.tbl_extend("force", bufopts, { desc = "Format Document" }))

				vim.keymap.set(
					"n",
					"gr",
					"<cmd>Lspsaga rename ++project<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Rename Symbol" })
				)

				vim.keymap.set(
					"n",
					"ga",
					"<cmd>Lspsaga code_action<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Code Action" })
				)

				-- Diagnostics
				vim.keymap.set(
					"n",
					"[d",
					vim.diagnostic.goto_prev,
					vim.tbl_extend("force", bufopts, { desc = "Prev Diagnostic" })
				)

				vim.keymap.set(
					"n",
					"]d",
					vim.diagnostic.goto_next,
					vim.tbl_extend("force", bufopts, { desc = "Next Diagnostic" })
				)

				vim.keymap.set(
					"n",
					"ge",
					"<cmd>Lspsaga show_line_diagnostics<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Line Diagnostics" })
				)

				-- Show diagnostic in float
				vim.keymap.set(
					"n",
					"gE",
					vim.diagnostic.open_float,
					vim.tbl_extend("force", bufopts, { desc = "Show Diagnostic" })
				)

				-- Signature help (useful for function parameters)
				vim.keymap.set(
					"n",
					"gs",
					vim.lsp.buf.signature_help,
					vim.tbl_extend("force", bufopts, { desc = "Signature Help" })
				)

				-- Implementation
				vim.keymap.set(
					"n",
					"gi",
					vim.lsp.buf.implementation,
					vim.tbl_extend("force", bufopts, { desc = "Go to Implementation" })
				)

				-- Document symbols
				vim.keymap.set(
					"n",
					"go",
					"<cmd>Lspsaga outline<CR>",
					vim.tbl_extend("force", bufopts, { desc = "Document Symbols" })
				)

				-- Add null-ls formatting support if available
				if client.name == "null-ls" then
					vim.keymap.set("n", "zf", function()
						vim.lsp.buf.format({
							filter = function(cl)
								return cl.name == "null-ls"
							end,
							async = true,
						})
					end, vim.tbl_extend("force", bufopts, { desc = "Format with null-ls" }))
				end

				-- Highlight references on hover
				if client.server_capabilities.documentHighlightProvider then
					vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
					vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_document_highlight" })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = bufnr,
						group = "lsp_document_highlight",
						callback = vim.lsp.buf.document_highlight,
					})
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = bufnr,
						group = "lsp_document_highlight",
						callback = vim.lsp.buf.clear_references,
					})
				end
			end

			-- Store for use in mason-lspconfig
			_G.lsp_on_attach = on_attach
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
			local util = require("lspconfig.util")

			-- Try to find sourcekit-lsp
			local sourcekit_cmd = nil
			local possible_paths = {
				"sourcekit-lsp",
				"/opt/homebrew/bin/sourcekit-lsp",
				"/usr/local/bin/sourcekit-lsp",
				"/usr/bin/sourcekit-lsp",
			}

			for _, path in ipairs(possible_paths) do
				if vim.fn.executable(path) == 1 then
					sourcekit_cmd = path
					break
				end
			end

			-- Also try xcrun if not found
			if not sourcekit_cmd and vim.fn.executable("xcrun") == 1 then
				sourcekit_cmd = "xcrun sourcekit-lsp"
			end

			if sourcekit_cmd then
				lspconfig.sourcekit.setup({
					cmd = sourcekit_cmd:find("xcrun") and vim.split(sourcekit_cmd, " ") or { sourcekit_cmd },
					filetypes = { "swift", "objective-c", "objective-cpp" },
					root_dir = util.root_pattern("Package.swift", ".git"),
					on_attach = _G.lsp_on_attach,
					capabilities = require("cmp_nvim_lsp").default_capabilities(),
				})
			else
				vim.notify("Swift LSP not found. Install with: brew install sourcekit-lsp", vim.log.levels.WARN)
			end

			-------------------------------------------------------------------
			-- Capabilities (nvim-cmp completion)
			-------------------------------------------------------------------
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- Enhanced completion capabilities
			capabilities.textDocument.completion.completionItem = {
				documentationFormat = { "markdown", "plaintext" },
				snippetSupport = true,
				preselectSupport = true,
				insertReplaceSupport = true,
				labelDetailsSupport = true,
				deprecatedSupport = true,
				commitCharactersSupport = true,
				tagSupport = { valueSet = { 1 } }, -- 1 = Deprecated
				resolveSupport = {
					properties = {
						"documentation",
						"detail",
						"additionalTextEdits",
					},
				},
			}

			-------------------------------------------------------------------
			-- LSP Server Handlers
			-------------------------------------------------------------------
			local handlers = {
				-- Default handler
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
						on_attach = _G.lsp_on_attach,
					})
				end,

				-- lua_ls (special settings)
				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						capabilities = capabilities,
						on_attach = _G.lsp_on_attach,
						settings = {
							Lua = {
								runtime = {
									version = "LuaJIT",
								},
								diagnostics = {
									globals = { "vim" },
								},
								workspace = {
									library = vim.api.nvim_get_runtime_file("", true),
									checkThirdParty = false,
								},
								telemetry = {
									enable = false,
								},
							},
						},
					})
				end,

				-- ts_ls (TypeScript/JavaScript)
				["ts_ls"] = function()
					lspconfig.tsserver.setup({
						capabilities = capabilities,
						on_attach = _G.lsp_on_attach,
						init_options = {
							preferences = {
								includeCompletionsForImportStatements = true,
								includeCompletionsForModuleExports = true,
								includeAutomaticOptionalChainCompletions = true,
							},
						},
					})
				end,

				-- pyright (Python)
				["pyright"] = function()
					lspconfig.pyright.setup({
						capabilities = capabilities,
						on_attach = _G.lsp_on_attach,
						settings = {
							python = {
								analysis = {
									autoSearchPaths = true,
									useLibraryCodeForTypes = true,
									diagnosticMode = "workspace",
									typeCheckingMode = "basic",
								},
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
					"cssls",
					"tailwindcss",
					"jsonls",
					"angularls",
					"clangd",
					"rust_analyzer",
					"vimls",
				},
				automatic_installation = true,
				handlers = handlers,
			})
		end,
	},

	-------------------------------------------------------------------------------
	-- Mason + Null-LS (formatters & linters) - UPDATED for new plugin name
	-------------------------------------------------------------------------------
	{
		"nvimtools/none-ls.nvim", -- This is correct - it's the renamed null-ls
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"jay-babu/mason-null-ls.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			local formatting = null_ls.builtins.formatting
			local diagnostics = null_ls.builtins.diagnostics

			null_ls.setup({
				sources = {
					-- Formatters
					formatting.stylua, -- Lua
					formatting.black, -- Python
					formatting.prettier.with({ -- JS/TS/HTML/CSS
						extra_filetypes = { "astro", "svelte", "vue" },
					}),
					formatting.shfmt, -- Shell
					formatting.clang_format, -- C/C++
					formatting.swiftformat, -- Swift

					-- Linters
					diagnostics.swiftlint, -- Swift
				},
				on_attach = _G.lsp_on_attach,
			})

			-- Setup mason-null-ls
			require("mason-null-ls").setup({
				ensure_installed = {
					"stylua",
					"black",
					"ruff",
					"prettier",
					"eslint_d",
					"shfmt",
					"shellcheck",
					"clang-format",
					"swiftformat",
					"swiftlint",
					"typos",
				},
				automatic_installation = true,
				handlers = {}, -- Use default handlers
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
		dependencies = {
			"rafamadriz/friendly-snippets",
			config = function()
				require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},
		config = function()
			local luasnip = require("luasnip")

			luasnip.setup({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				delete_check_events = "TextChanged",
			})

			vim.keymap.set({ "i", "s" }, "<C-l>", function()
				if luasnip.jumpable(1) then
					luasnip.jump(1)
				end
			end, { silent = true, desc = "Snippet Jump Forward" })

			vim.keymap.set({ "i", "s" }, "<C-h>", function()
				if luasnip.jumpable(-1) then
					luasnip.jump(-1)
				end
			end, { silent = true, desc = "Snippet Jump Backward" })

			vim.keymap.set({ "i" }, "<C-s>", function()
				if luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				end
			end, { silent = true, desc = "Expand or jump snippet" })
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
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
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

			-- Also set up cmp for command line
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
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
		opts = {
			text = {
				spinner = "dots",
				done = "✓",
			},
		},
	},
}
