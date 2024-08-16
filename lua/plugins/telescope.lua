return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.6",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")
			vim.keymap.set({ "n", "t", "v", "i" }, "<C-f>", builtin.find_files, {})
			vim.keymap.set({ "n", "t", "v", "i" }, "<C-g>", builtin.live_grep, {})
			-- Key mapping to search files in a specific directory
			vim.keymap.set({"n","t","v","i"}, "<C-e>", function()
				builtin.find_files({ cwd = vim.fn.input("Directory: ", "~/", "dir") })
			end, { noremap = true, silent = true })
			vim.keymap.set({ "n", "t", "v" }, "<leader>h", builtin.help_tags, {})
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
