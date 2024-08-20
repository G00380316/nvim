return {
	{
		"voldikss/vim-floaterm",
		config = function()
			vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits

			-- Close the current floating terminal
			vim.api.nvim_set_keymap("t", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-w>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true }) -- Close terminal without killing
			vim.api.nvim_set_keymap("n", "<C-w>", ":q<CR>", { noremap = true, silent = true }) -- Close terminal without killing
			vim.api.nvim_set_keymap("v", "<C-w>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true }) -- Close terminal without killing
			vim.api.nvim_set_keymap("i", "<C-w>", "<C-\\><C-n>:q<CR>", { noremap = true, silent = true }) -- Close terminal without killing

			-- Close all floating terminals
			vim.api.nvim_set_keymap("t", "<Leader>qa", "<cmd>:FloatermKill!<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<Leader>qa", ":FloatermKill!<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<Leader>qa", ":FloatermKill!<CR>", { noremap = true, silent = true })

			-- Open lazygit in a floating terminal
			vim.cmd("command! LazyGitFloaterm FloatermNew lazygit")
			vim.api.nvim_set_keymap("n", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })

			-- Navigate to the previous floating terminal
			vim.api.nvim_set_keymap("n", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-p>", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })

			-- Navigate to the next floating terminal
			vim.api.nvim_set_keymap("n", "<C-n>", ":FloatermNext<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-n>", ":FloatermNext<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-n>", ":FloatermNext<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-n>", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

			-- Open a new floating terminal
			vim.api.nvim_set_keymap("n", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-z>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })

			-- Go to the last used floating terminal
			vim.api.nvim_set_keymap("n", "<C-l>", ":FloatermLast<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("v", "<C-l>", ":FloatermLast<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("i", "<C-l>", "<Esc>:FloatermLast<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("t", "<C-l>", "<cmd>:FloatermLast<CR>", { noremap = true, silent = true })
		end,
	},
}
