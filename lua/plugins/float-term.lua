return {
   {
      "voldikss/vim-floaterm",
      config = function()
         vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits
         -- Keymapping to close the current floating terminal
         vim.api.nvim_set_keymap("t", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
         vim.api.nvim_set_keymap("n", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
         vim.api.nvim_set_keymap("v", "<C-q>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
         -- Keymapping to close all floating terminals
         vim.api.nvim_set_keymap("t", "<Leader>qa", ":FloatermKill!<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("n", "<Leader>qa", ":FloatermKill!<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("v", "<Leader>qa", ":FloatermKill!<CR>", { noremap = true, silent = true })

         -- Define a command to open lazygit in a floating terminal
         vim.cmd("command! LazyGitFloaterm FloatermNew lazygit")
         -- Keymapping to open lazygit in a floating terminal
         vim.api.nvim_set_keymap("n", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("v", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("i", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("t", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
         -- Keymapping to go to the previous floating terminal
         vim.api.nvim_set_keymap("n", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("v", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("i", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("t", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
         -- Keymapping to open a floating terminal with <C-z>
         vim.api.nvim_set_keymap("n", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("v", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
         vim.api.nvim_set_keymap("t", "<C-z>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
      end,
   },
}
