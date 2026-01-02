return {
	"LunarVim/bigfile.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		filesize = 5, -- MiB, default is 1.5 MiB
		pattern = { "*" }, -- apply to all filetypes
		features = { -- features to disable
			"indent_blankline",
			"illuminate",
			"lsp",
			"treesitter",
			"syntax",
			"matchparen",
		},
	},
	config = function(_, opts)
		require("bigfile").setup(opts)

		vim.api.nvim_create_autocmd("User", {
			pattern = "BigFile",
			callback = function()
				vim.cmd("syntax on") -- The old-school, lighter highlighting
			end,
		})
	end,
}
