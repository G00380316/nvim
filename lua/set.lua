-- Transparency
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- Disable GUI Cursor
vim.opt.guicursor = ""
vim.o.guicursor = table.concat({
    "n-v-c:block",   -- normal, visual, command: block cursor
    "i-ci-ve:ver25", -- insert, command-insert, visual-exec: vertical bar cursor (25% width)
    "r-cr:hor20",    -- replace, command-replace: horizontal bar (underline)
    "o:hor50",       -- operator-pending: thicker underline
    "a:blinkon100",  -- all modes: blinking speed
}, ",")

-- Line Numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Tab and Indentation Settings
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true -- Smart auto-indenting
vim.opt.autoindent = true  -- Copy indent from current line

vim.opt.wrap = false       -- Disable Line Wrapping
-- vim.opt.wrap = true
-- Stops words from being broken by wrapping
vim.opt.linebreak = true
vim.opt.wrapmargin = 0            -- " Disable margin-based line wrapping
vim.opt.textwidth = 0             -- " Disable hard wrapping at a fixed width
vim.opt.formatoptions:remove("t") -- " Remove the 't' flag to stop automatic text wrapping

-- Undo History Configuration
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
-- Search Behavior
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true  -- Case sensitive if uppercase in search
vim.opt.hlsearch = false  -- `hlsearch = false`: Disables the highlighting of search results after searching.
vim.opt.incsearch = true  -- `incsearch = true`: Shows incremental search results as you type.
vim.o.cursorline = true   -- Enabling Cursor line
-- Scrolloff and Signcolumn
vim.opt.scrolloff = 10    -- `scrolloff = 8`: Keeps 8 lines of context around the cursor when scrolling.
vim.opt.signcolumn =
"yes"                     -- `signcolumn = "yes"`: Always shows the sign column (useful for things like Git markers, diagnostics, etc.).
-- Dim gray background for CursorLine
vim.cmd [[
  highlight CursorLine cterm=NONE ctermbg=236 guibg=#2e2e2e
]]

-- Visual settings
vim.opt.termguicolors = true                      -- Enable 24-bit RGB Colors
vim.opt.signcolumn = "yes"                        -- Always show sign column
vim.opt.colorcolumn = "100"                       -- Show column at 100 characters
vim.opt.showmatch = true                          -- Highlight matching brackets
vim.opt.matchtime = 2                             -- How long to show matching bracket
vim.opt.cmdheight = 1                             -- Command line height
vim.opt.completeopt = "menuone,noinsert,noselect" -- Completion options
vim.opt.showmode = false                          -- Don't show mode in command line
vim.opt.pumheight = 10                            -- Popup menu height
vim.opt.pumblend = 10                             -- Popup menu transparency
vim.opt.winblend = 0                              -- Floating window transparency
vim.opt.conceallevel = 0                          -- Don't hide markup
vim.opt.concealcursor = ""                        -- Don't hide cursor line markup
vim.opt.lazyredraw = true                         -- Don't redraw during macros
vim.opt.synmaxcol = 300                           -- Syntax highlighting limit

-- File handling
vim.opt.backup = false                            -- Don't create backup files
vim.opt.writebackup = false                       -- Don't create backup before writing
vim.opt.swapfile = false                          -- Don't create swap files
vim.opt.undofile = true                           -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir") -- Undo directory
vim.opt.updatetime = 300                          -- Faster completion
vim.opt.timeoutlen = 500                          -- Key timeout duration
vim.opt.ttimeoutlen = 0                           -- Key code timeout
vim.opt.autoread = true                           -- Auto reload files changed outside vim
vim.opt.autowrite = false                         -- Don't auto save
vim.opt.updatetime = 50                           -- Reduces the time (to 50 milliseconds) Vim waits before triggering events like CursorHold. This can improve responsiveness in features like diagnostics.

-- Behavior settings
vim.opt.hidden = true                  -- Allow hidden buffers
vim.opt.errorbells = false             -- No error bells
vim.opt.backspace = "indent,eol,start" -- Better backspace behavior
vim.opt.autochdir = false              -- Don't auto change directory
vim.opt.iskeyword:append("-")          -- Treat dash as part of word
vim.opt.path:append("**")              -- include subdirectories in search
vim.opt.selection = "exclusive"        -- Selection behavior
vim.opt.clipboard = "unnamedplus"      -- Adding clipboard func with wl-clipboard
vim.cmd("set mouse=")                  -- Disables mouse
vim.opt.modifiable = true              -- Allow buffer modifications
vim.opt.encoding = "UTF-8"             -- Set encoding
vim.opt.isfname:append("@-@")          -- Adds `@-@` to the list of valid characters for filenames.
vim.cmd("filetype plugin indent on")   -- Enable file type detection and related plugins

-- Tab display settings
vim.opt.showtabline = 1 -- Always show tabline (0=never, 1=when multiple tabs, 2=always)
vim.opt.tabline = ''    -- Use default tabline (empty string uses built-in)

-- Transparent tabline appearance
vim.cmd([[
  hi TabLineFill guibg=NONE ctermfg=242 ctermbg=NONE
]])

-- Command-line completion
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar" })

-- Better diff options
vim.opt.diffopt:append("linematch:60")

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- Folding settings
-- vim.opt.foldmethod = "expr"                         -- Use expression for folding
-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- Use treesitter for folding
-- vim.o.foldmethod = "marker"
-- vim.o.foldmarker = "# @leet imports start,# @leet imports end"
-- vim.opt.foldlevel = 99                               -- Start with all folds open

-- Split behavior
vim.opt.splitbelow = true -- Horizontal splits go below
vim.opt.splitright = true -- Vertical splits go right

-- Input timeout
vim.o.timeout = true
vim.o.timeoutlen = 500
