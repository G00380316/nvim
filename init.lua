vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.api.nvim_set_keymap('t', '<C-q>', '<C-\\><C-n>', {noremap = true})
vim.o.shell = '"C:\\Program Files\\Git\\bin\\bash.exe"'
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local opts = {}

require("lazy").setup("plugins", opts)

vim.keymap.set('n', '<C-e>', ':Neotree filesystem reveal left', {})

local config = require("nvim-treesitter.configs")
config.setup({
  ensure_installed = {"c","lua","vim","html","css","java","javascript","cpp","gitignore","php","python","xml","typescript","yaml","ssh_config","sql","csv","dockerfile","json","json5"},
  sync_install = false,
  highlight = { enable = true },
  indent = { enable = true },
})
