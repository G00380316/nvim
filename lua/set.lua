-- Disable GUI Cursor

vim.opt.guicursor = ""

-- Line Numbers

vim.opt.nu = true
vim.opt.relativenumber = true

-- Tab and Indentation Settings

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Smart Indentation

vim.opt.smartindent = true

-- Disable Line Wrapping

--vim.opt.wrap = false
vim.opt.wrap = true
-- Stops words from being broken by wrapping
vim.opt.linebreak = true
vim.opt.wrapmargin = 0            -- " Disable margin-based line wrapping
vim.opt.textwidth = 0             -- " Disable hard wrapping at a fixed width
vim.opt.formatoptions:remove("t") -- " Remove the 't' flag to stop automatic text wrapping

-- Disable Swap and Backup Files

vim.opt.swapfile = false
vim.opt.backup = false

-- Undo History Configuration

vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Search Behavior

vim.opt.hlsearch = false
vim.opt.incsearch = true

-- `hlsearch = false`: Disables the highlighting of search results after searching.
-- `incsearch = true`: Shows incremental search results as you type.

-- Enable 24-bit RGB Colors

vim.opt.termguicolors = true

-- Scrolloff and Signcolumn

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- `scrolloff = 8`: Keeps 8 lines of context around the cursor when scrolling.
-- `signcolumn = "yes"`: Always shows the sign column (useful for things like Git markers, diagnostics, etc.).

-- Filename Behavior

vim.opt.isfname:append("@-@")

-- Adds `@-@` to the list of valid characters for filenames.

-- Update Time

vim.opt.updatetime = 50

-- Reduces the time (to 50 milliseconds) Vim waits before triggering events like CursorHold. This can improve responsiveness in features like diagnostics.

-- Color Column ( used as a marker not to go past for best coding practice)

vim.opt.colorcolumn = "80"

-- Disables mouse

vim.cmd("set mouse=")

-- Enable file type detection and related plugins
vim.cmd("filetype plugin indent on")

-- Adding clipboard func with wl-clipboard
vim.opt.clipboard = "unnamedplus"

vim.notify = function(msg, level, opts)
    -- Filter out messages containing "LSP" in the content
    if msg:find("LSP") then
        return
    end
end

-- Reduce the timeout for mapped sequences

--vim.opt.timeoutlen = 200

-- You can adjust this to a lower value if needed

--vim.opt.ttimeoutlen = 0

-- Reduce this as well for faster response