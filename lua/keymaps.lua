-- Set the leader key to comma
--vim.g.mapleader = ","
--vim.g.maplocalleader = ","

-- Move Selected Text Up/Down in Visual Mode

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep Cursor Position When Joining Lines

vim.keymap.set("n", "J", "mzJ`z")

-- Scroll Half-Page and Center

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center Search Results

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste Over Selection Without Yanking(prevents the copied text from being overwritten)

vim.keymap.set("x", "P", [["_dP]])

-- Delete Without Affecting Clipboard

vim.keymap.set({ "n", "v" }, "d", [["_d]])

-- Map `Ctrl-C` to Escape in Insert Mode
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Disable `Q` (which used to start Ex mode)

vim.keymap.set("n", "Q", "<nop>")

-- Open New Tmux Window (with script)

vim.keymap.set("n", "<C-t>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Navigate Quickfix List

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")


--    These are mappings to navigate the quickfix and location lists:
--    - `Ctrl-k`: Go to the next item in the quickfix list.
--    - `Ctrl-j`: Go to the previous item in the quickfix list.
--    - `<leader>k`: Go to the next item in the location list.
--    - `<leader>j`: Go to the previous item in the location list.
--    All of these commands keep the cursor centered (`zz`).

-- Search and Replace Current Word

-- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- This mapping opens a search-and-replace for the word under the cursor globally in the file, allowing you to edit it before confirming.

-- Make File Executable

-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Source Current file

--vim.keymap.set("n", "<leader><leader>", function()
--  vim.cmd("so")
--end)

-- Open compiler
vim.keymap.set("n", "<C-1>", "<cmd>CompilerOpen<CR>", { noremap = true, silent = true })

-- For canceling terminal mode in floating terminal
vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true })

-- Remaps the switch window in nvim to (ctrl and s)
vim.keymap.set({ "n", "i", "v", "t" }, "<C-s>", "<C-w>w", { noremap = true, silent = true })

-- Indent selected block of text
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })

-- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })

-- Clear search highlighting
vim.keymap.set({ "n", "i", "t", "v" }, "<C-n>", ":nohlsearch<CR>", { noremap = true, silent = true })

-- Remap Shift + R to r
vim.keymap.set("n", "r", "R", { noremap = true, silent = true })

-- Command to navigate out of Commandline faster when searching for text
vim.keymap.set("c", "<C-n>", "<CR>", { noremap = true, silent = true })

-- Command to start practicing Leetcode
vim.keymap.set("n", "<C-l>", "<cmd>Leet<CR>", { noremap = true, silent = true })
