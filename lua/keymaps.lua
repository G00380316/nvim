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

-- Search and Replace Current Word

vim.keymap.set("n", "R", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Open compiler
vim.keymap.set("n", "<C-n>", "<cmd>CompilerOpen<CR>", { noremap = true, silent = true })

-- For canceling terminal mode in floating terminal
vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true })

-- Indent selected block of text
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })

-- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })

-- Remap Shift + R to r
vim.keymap.set("n", "r", "R", { noremap = true, silent = true })

-- Command to start practicing Leetcode
vim.keymap.set("n", "<C-l>", "<cmd>Leet<CR>", { noremap = true, silent = true })
