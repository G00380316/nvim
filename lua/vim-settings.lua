vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=3")
vim.cmd("set cursorline")
vim.cmd("set background=dark")
vim.cmd("set relativenumber")
vim.cmd("syntax on")
-- Enable file type detection and related plugins
vim.cmd("filetype plugin indent on")

-- Adding clipboard func with wl-clipboard
vim.opt.clipboard = 'unnamedplus'

vim.opt.autoindent = true -- Enable auto-indentation
vim.g.mapleader = ","
vim.wo.number = true

vim.opt.swapfile = false
vim.opt.updatetime = 1

local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
--local auto_dir_group = vim.api.nvim_create_augroup("Dir", { clear = true })
--local auto_refresh_neotree = vim.api.nvim_create_augroup("Update", { clear = true })

-- Auto-save on buffer leave
--vim.api.nvim_create_autocmd("BufLeave", {
--  group = auto_save_group,
--  pattern = "*",
-- command = "silent! write",
--})

-- Auto-save on ModeChange
vim.api.nvim_create_autocmd('ModeChanged', {
   group = auto_save_group,
   pattern = '*',
   command = 'silent! write',
})

-- Auto-save on CursorHold
--vim.api.nvim_create_autocmd('CursorHold', {
--  group = auto_save_group,
--  pattern = '*',
--  command = 'silent! write',
--})

-- Auto-Refresh Neo-tree on ModeChange
--vim.api.nvim_create_autocmd('ModeChanged', {
--   group = auto_refresh_neotree,
--   pattern = "*",
--   callback = function()
--      local current_win = vim.api.nvim_get_current_win()
--     local mode = vim.fn.mode()
--
--      for _, win in ipairs(vim.api.nvim_list_wins()) do
--         local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
--         -- Check if the buffer name contains 'neo-tree'
--         if bufname:match("neo%-tree") then
--           if mode == 'i' or mode == 'n'then
--              -- Switch to the Neo-tree window
--               vim.cmd('Neotree')
--               -- Restore the original window
--               vim.api.nvim_set_current_win(current_win)
--               return
--            end
--         end
--      end
--   end,
--})

-- Auto-change directory to the file's directory on buffer enter
--vim.api.nvim_create_autocmd("BufEnter", {
--   group = auto_dir_group,
--   pattern = "*",
--   command = "silent! :cd %:p:h",
--})

-- Function to find the nearest directory containing package.json or .git
local function find_project_root()
  local path = vim.fn.expand('%:p:h')

  -- First, look for the nearest package.json
  local package_json_dir = vim.fn.findfile('package.json', path .. ';')
  if package_json_dir ~= "" then
    return vim.fn.fnamemodify(package_json_dir, ":p:h")
  end

  -- If no package.json is found, look for the nearest .git directory
  local git_dir = vim.fn.finddir('.git', path .. ';')
  if git_dir ~= "" then
    -- Return the parent directory of the .git directory
    return vim.fn.fnamemodify(git_dir, ":p:h:h")
  end

  -- If neither is found, fall back to the current file's directory
  return path
end

-- Auto-change directory to the nearest package.json, .git's parent directory, or current file's directory
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local project_root = find_project_root()
    if project_root then
      vim.cmd("silent! cd " .. project_root)
    end
  end,
})

-- Open compiler
vim.api.nvim_set_keymap('n', '<F6>', "<cmd>CompilerOpen<cr>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("t", "<C-v>", "<C-c>", { noremap = true })
vim.api.nvim_set_keymap("t", "<C-c>", "<C-\\><C-n>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-s>", "<C-w>w", { noremap = true, silent = true })            -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap("i", "<C-s>", "<Esc><C-w>w", { noremap = true, silent = true })       -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap("v", "<C-s>", "<Esc><C-w>w", { noremap = true, silent = true })       -- Remaps the switch window in nvim to (ctrl and s)
vim.api.nvim_set_keymap("t", "<C-s>", "<C-\\><C-n><C-w>w", { noremap = true, silent = true }) -- Remaps the switch window in nvim to (ctrl and s)

-- Indent selected block of text to use this by using shift and then arrow key
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })

-- Outdent selected block of text
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })

-- This is remapping of Keys to use system clipboard in Neovim more easily

vim.api.nvim_set_keymap("v", "<leader>c", '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>c", '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>v", '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<leader>v", '<Esc>"+pa', { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>v", '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>x", '"+d', { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>x", '"+d', { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>d", ":nohlsearch<CR>", { noremap = true, silent = true })

-- Remap Shift + R to r
vim.api.nvim_set_keymap("n", "r", "R", { noremap = true, silent = true })

-- Command to navigate out of Commandline faster when searching for text
vim.api.nvim_set_keymap("c", "<C-n>", "<CR>n", { noremap = true, silent = true })

--vim.o.shell = '"C:\\Program Files\\Git\\bin\\bash.exe"'
--vim.opt.shell='"C:\\Program Files\\WSL\\wsl.exe"'

-- For Windows
--vim.opt.shell = "powershell"
--vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
--vim.opt.shellquote = '"'
--vim.opt.shellpipe = "| Out-File -Encoding UTF8"
--vim.opt.shellredir = "| Out-File -Encoding UTF8"
--vim.opt.shellxquote = ""
