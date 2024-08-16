return {
--[[ Remove comments if you want Neo-tree
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"muniftanjim/nui.nvim",
	},

	config = function()
		require("neo-tree").setup({
			use_libuv_file_watcher = true,
		})

		vim.keymap.set("n", "<C-d>", "<cmd>Neotree filesystem reveal left<cr>", { noremap = true, silent = true }) -- <cr> immitates enter so we don't have to press enter after ctrl and e
		vim.keymap.set("v", "<C-d>", "<cmd>Neotree filesystem reveal left<cr>", { noremap = true, silent = true })
		vim.keymap.set("t", "<C-d>", "<cmd>Neotree filesystem reveal left<cr>", { noremap = true, silent = true })
		vim.keymap.set("i", "<C-d>", "<esc><cmd>Neotree filesystem reveal left<cr>", { noremap = true, silent = true })
	end,
]]}
