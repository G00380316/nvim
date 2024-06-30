vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set cursorline")
vim.cmd("set background=dark")
vim.cmd("set relativenumber")

vim.g.mapleader = " "
vim.wo.number = true

vim.opt.swapfile = false
vim.opt.updatetime = 100


vim.api.nvim_set_keymap('t', '<C-v>', '<C-c>', { noremap = true })
vim.api.nvim_set_keymap('t', '<C-c>', '<C-\\><C-n>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-s>', '<C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s) 
vim.api.nvim_set_keymap('i', '<C-s>', '<Esc><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap('v', '<C-s>', '<Esc><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap('t', '<C-s>', '<C-\\><C-n><C-w>w', { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap('n', '<C-z>', ':bot10sp<CR>:term<CR>', { noremap = true, silent = true }) -- Opens the terminal bottom of nvim with 10 lines
vim.api.nvim_set_keymap('v', '<C-z>', ':bot10sp<CR>:term<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-z>', ':bot10sp<CR>:term<CR>', { noremap = true, silent = true })

-- Indent selected block of text to use this by using shift and then arrow key
vim.api.nvim_set_keymap('v', '>', '>gv', { noremap = true, silent = true })

-- Outdent selected block of text
vim.api.nvim_set_keymap('v', '<', '<gv', { noremap = true, silent = true })

-- This is remapping of Keys to use system clipboard in Neovim more easily 

vim.api.nvim_set_keymap('v', '<leader>c', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>c', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>v', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<leader>v', '<Esc>"+pa', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>v', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>x', '"+d', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>x', '"+d', { noremap = true, silent = true })

--vim.o.shell = '"C:\\Program Files\\Git\\bin\\bash.exe"'

vim.opt.shell = "powershell"
vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
vim.opt.shellquote = "\""
vim.opt.shellpipe = "| Out-File -Encoding UTF8"
vim.opt.shellredir = "| Out-File -Encoding UTF8"
vim.opt.shellxquote = ""
