vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.api.nvim_set_keymap('t', '<C-v>', '<C-\\><C-n>', {noremap = true})
vim.api.nvim_set_keymap({'n','v'}, '<leader>s', ':b#<CR>', { noremap = true, silent = true })

vim.o.shell = '"C:\\Program Files\\Git\\bin\\bash.exe"'

vim.g.mapleader = " "
