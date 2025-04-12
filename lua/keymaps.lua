-- Set the leader key to comma
--vim.g.mapleader = ","
--vim.g.maplocalleader = ","

-- Move Selected Text Up/Down in Visual Mode

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Disable "K" normal mode which seems to spit out memory info and sometimes errors

vim.keymap.set("n", "K", "<nop>")

-- Keep Cursor Position When Joining Lines
vim.keymap.set("n", "J", "mzJ`z")
-- Join current line and the next two
vim.keymap.set("n", "K", "mz2J`z")

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

-- Map to Manually Format file
vim.keymap.set({ "n", "v" }, "F", vim.lsp.buf.format, { noremap = true, silent = true })
-- Remap F to `Alt-F`
vim.keymap.set({ "n", "v" }, "<A-f>", "F", { noremap = true, silent = true })

-- Disable `Q` (which used to start Ex mode)

vim.keymap.set("n", "Q", "<nop>")

-- Search and Replace Current Word

vim.keymap.set("n", "R", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Search the next Occurence of the current word (oops apparently this is inbuilt to neovim but I will leave this here just incase)

--vim.keymap.set("n", "N", [[:let @/ = '\<' . expand('<cword>') . '\>' | execute 'normal! n'<CR>]])

-- Open compiler
vim.keymap.set("n", "<A-c>", "<cmd>CompilerOpen<CR>", { noremap = true, silent = true })

-- Custom key mappings to navigate wrapped lines
vim.keymap.set("n", "j", "gj", { noremap = true })   -- Use 'gj' to move down visually wrapped lines
vim.keymap.set("n", "k", "gk", { noremap = true })   -- Use 'gk' to move up visually wrapped lines
vim.keymap.set("n", "<CR>", "o", { noremap = true }) -- Pressing Enter creates a new line without jumping

-- For canceling terminal mode in floating terminal
vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true })

-- Indent selected block of text
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })

-- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })

-- Remap Shift + R to r
vim.keymap.set("n", "r", "R", { noremap = true, silent = true })

-- Command to start practicing Leetcode
vim.keymap.set("n", "zl", "<cmd>Leet<CR>", { noremap = true, silent = true })

-- Command to cd into correct dir Manually
vim.keymap.set({ "n", "v", "t", "i" }, "<C-a>", "<cmd>silent! :cd %:p:h<CR>", { noremap = true, silent = true })

-- Command to allow for selection and search of buffer with dressing
vim.keymap.set({ "n", "v", "t", "i" }, "zb", "<cmd>Telescope buffers<CR>", { desc = "Pick a buffer" })

-- CommandT Keybind to Open the file explorer
vim.keymap.set({ "n", "v", "t", "i" }, 'zt', '<cmd>CommandT<CR>')

-- Snacks Keybind to Opem dashboard
vim.keymap.set({ "n", "v", "t", "i" }, "zd", function()
    Snacks.dashboard.open(opts)
end)

-- Buffer Navigation
vim.keymap.set({ "n", "v", "i", "t" }, "<C-]>", "<cmd>bn<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-[>", "<cmd>bp<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", "<cmd>bd!<CR>", { noremap = true, silent = true })

-- Lua Configuration for Neovim
vim.api.nvim_set_keymap('n', '<A-l>',
    'a<cmd>lua vim.schedule(function() require("cmp").complete() end)<CR>',
    { noremap = true, silent = true })

-- Term
-- vim.keymap.set({ "n", "v", "i", "t" }, "<C-t>", "<cmd>term<CR>", { noremap = true, silent = true })
