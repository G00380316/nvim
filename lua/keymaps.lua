-- Set the leader key to comma
--vim.g.mapleader = ","
--vim.g.maplocalleader = ","


-- Fixes
--
--
-- Disable "K" normal mode which seems to spit out memory info and sometimes errors
vim.keymap.set("n", "K", "<nop>")
-- Disable "C-v" normal mode which seems to spit out memory info and sometimes errors
vim.keymap.set("i", "<C-v>", "<nop>")
-- Keep Cursor Position When Joining Lines
vim.keymap.set("n", "J", "mzJ`z")
-- Scroll Half-Page and Center
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- Center Search Results
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
-- Paste Over Selection Without Yanking(prevents the copied text from being overwritten)
vim.keymap.set("x", "p", [["_dP]])
-- Delete Without Affecting Clipboard
vim.keymap.set({ "n", "v" }, "d", [["_d]])
-- Disable `Q` (which used to start Ex mode)
vim.keymap.set("n", "Q", "<nop>")
-- Custom key mappings to navigate wrapped lines
-- vim.keymap.set("n", "j", "gj", { noremap = true }) -- Use 'gj' to move down visually wrapped lines
-- vim.keymap.set("n", "k", "gk", { noremap = true }) -- Use 'gk' to move up visually wrapped lines


-- Tweaks
--
--
-- Move Selected Text Up/Down in Visual Mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- Join current line and the next two
vim.keymap.set("n", "K", "mz2J`z")
-- Remap F to `Alt-F`
vim.keymap.set({ "n", "v" }, "<A-f>", "F", { noremap = true, silent = true })
-- Remap Shift + R to r
vim.keymap.set("n", "r", "R", { noremap = true, silent = true })


-- Plugin/Extra Functionality
--
--
-- Map to Manually Format file
vim.keymap.set({ "n", "v" }, "F", vim.lsp.buf.format, { noremap = true, silent = true })
-- Map `Ctrl-C` to Escape in Insert Mode
vim.keymap.set("i", "<C-c>", "<Esc>")
-- Search and Replace Current Word
vim.keymap.set("n", "R", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- Open compiler
vim.keymap.set("n", "<A-c>", "<cmd>CompilerOpen<CR>", { noremap = true, silent = true })
-- Pressing Enter creates a new line
vim.keymap.set("n", "<CR>", "o", { noremap = true })
-- For canceling terminal mode in floating terminal
vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true })
-- Indent selected block of text
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })
-- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
-- Disable all mappings that start with Ctrl+w
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<C-w>', '<Nop>', { noremap = true, silent = true })
-- Map Alt+w in normal mode to switch to next window immediately
vim.keymap.set('n', '<A-w>', '<C-w>w', { noremap = true, silent = true, desc = "Switch to next window" })
-- In insert mode, use Alt+w to exit insert mode and switch window
vim.keymap.set('i', '<A-w>', '<Esc><C-w>w',
    { noremap = true, silent = true, desc = "Switch to next window from insert mode" })
-- In visual mode, map Alt+w to switch window
vim.keymap.set('v', '<A-w>', '<C-w>w', { noremap = true, silent = true, desc = "Switch to next window in visual mode" })
-- In terminal mode, map Alt+w to switch window after going to normal mode
vim.keymap.set('t', '<A-w>', [[<C-\><C-n><C-w>w]],
    { noremap = true, silent = true, desc = "Switch to next window in terminal mode" })
-- Command to start practicing Leetcode
vim.keymap.set("n", "zlo", "<cmd>Leet<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zlt", "<cmd>Leet Run<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zls", "<cmd>Leet Submit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zll", "<cmd>Leet List<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zlr", "<cmd>Leet Reset<CR>", { noremap = true, silent = true })
-- Command to cd into correct dir Manually
vim.keymap.set({ "n", "v", "t", "i" }, "<C-a>", "<cmd>silent! :cd %:p:h<CR>", { noremap = true, silent = true })
-- Ssh Plugin
vim.keymap.set({ "n", "v", "t", "i" }, 'zssh', '<cmd>SshLauncher<CR>')
vim.keymap.set({ "n", "v", "t", "i" }, 'zssa', '<cmd>SshAddKey<CR>')
-- SessionManager commands
vim.keymap.set("n", "<A-s>", "<cmd>SessionManager<CR>", { desc = "Save Session" })
vim.keymap.set("n", "zss", "<cmd>SessionManager save_current_session<CR>", { desc = "Save Session" })
vim.keymap.set("n", "zsm", "<cmd>SessionManager load_session<CR>", { desc = "Load Dir Session" })
vim.keymap.set("n", "zsd", "<cmd>SessionManager delete_session<CR>", { desc = "Load Dir Session" })
-- Buffer Navigation
vim.keymap.set({ "n", "v", "i", "t" }, "<C-0>", "<cmd>normal! 0zs<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-]>", "<cmd>bn<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-[>", "<cmd>bp<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", "<cmd>bd!<CR>", { noremap = true, silent = true })
-- Split vertically
vim.keymap.set({ "n", "v", "i", "t" }, '<A-v>', ':vsplit<CR>', { noremap = true, silent = true })
-- Split horizontally
vim.keymap.set({ "n", "v", "i", "t" }, '<A-h>', ':split<CR>', { noremap = true, silent = true })
-- Saving and Exting vim mappings
vim.keymap.set({ "n", "i", "v" }, "<C-s>", function()
    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    end
    vim.cmd("write")
end, { noremap = true, silent = true })
vim.keymap.set({ "n", "i", "v" }, "<A-s>", "<cmd>wq<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "i", "v" }, "<A-q>", "<cmd>q<CR>", { noremap = true, silent = true })
-- Lua Configuration for Neovim
vim.api.nvim_set_keymap('n', '<C-Space>',
    'a<cmd>lua vim.schedule(function() require("cmp").complete() end)<CR>',
    { noremap = true, silent = true })
-- Toggling Live Server on and off
vim.keymap.set({ "n", "v", "i", "t" }, '<A-l>', ':LiveServerToggle<CR>', { noremap = true, silent = true })
-- Open lazygit in floating terminal (main UI)
vim.keymap.set("n", "zg", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })
    vim.fn.termopen("lazygit")
    vim.cmd("startinsert")
end, { desc = "Open Lazygit in floating terminal" })

-- Open lazygit logs view in floating terminal
vim.keymap.set("n", "zsl", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })
    vim.fn.termopen("lazygit log")
    vim.cmd("startinsert")
end, { desc = "Open Git Logs in floating terminal" })

vim.keymap.set("n", "p", function()
    local reg = vim.fn.getreg('"')
    local regtype = vim.fn.getregtype('"')

    -- If linewise, trim newline to force character-wise paste
    if regtype == 'V' then
        -- remove trailing newline if it exists
        reg = reg:gsub('\n$', '')
        vim.fn.setreg('"', reg, 'v') -- 'v' = characterwise
    end

    -- Do normal paste
    vim.api.nvim_feedkeys("p", "n", false)
end, { noremap = true, silent = true, desc = "Paste after cursor (even for linewise)" })
