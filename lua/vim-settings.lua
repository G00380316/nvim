vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.wo.number = true

vim.opt.swapfile = false

vim.api.nvim_set_keymap('t', '<C-v>', '<C-\\><C-n>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-s>', '<C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s) 
vim.api.nvim_set_keymap('i', '<C-s>', '<Esc><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap('v', '<C-s>', '<Esc><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap('t', '<C-s>', '<C-\\><C-n><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)

vim.o.shell = '"C:\\Program Files\\Git\\bin\\bash.exe"'

vim.g.mapleader = " "
