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
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")

			local function setup_servers()
				local servers = {
					"ts_ls",
					"jdtls",
					"html",
					"lua_ls",
					"pyright",
					"clangd",
					"vimls",
					"jsonls",
					"angularls",
					"arduino_language_server",
					"tailwindcss",
					"rust_analyzer",
					"cssls",
				}
				for _, server in ipairs(servers) do
					lspconfig[server].setup({
						capabilities = capabilities,
					})
				end
			end

			setup_servers()

			vim.keymap.set({ "n", "v" }, "<C-i>", vim.lsp.buf.hover, {})
			vim.keymap.set({ "n", "v" }, "<C-v>", vim.lsp.buf.definition, {})
		end,
	},
}
