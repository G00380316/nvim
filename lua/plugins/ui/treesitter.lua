return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"lua",
					"python",
					"javascript",
					"typescript",
					"html",
					"css",
					"json",
					"c",
					"cpp",
					"rust",
					"vim",
					"bash", -- Add Swift only if fixed
				},
				highlight = { enable = true },
				-- Add this to handle Swift parser issues
				parser_install_dir = vim.fn.stdpath("data") .. "/treesitter",
			})

			-- Try to install Swift parser with a workaround
			local install_parsers = require("nvim-treesitter.install")
			install_parsers.command_extra_args = {
				swift = { "--no-bindings" }, -- This might be causing the issue
			}
		end,
	},
}
