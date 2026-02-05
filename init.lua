--- PLUGINS ---

vim.pack.add({
    -- Navigation
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/folke/snacks.nvim" },
    { src = "https://github.com/ibhagwan/fzf-lua" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/voldikss/vim-floaterm" },


    -- UI
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/rebelot/kanagawa.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
    { src = "https://github.com/HiPhish/rainbow-delimiters.nvim" },
    { src = "https://github.com/3rd/image.nvim" },
    { src = "https://github.com/goolord/alpha-nvim" },
    { src = "https://github.com/stevearc/dressing.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },


    -- LSP
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/b0o/SchemaStore.nvim" },


    -- Completion
    { src = "https://github.com/saghen/blink.cmp" },
    { src = "https://github.com/cohama/lexima.vim" },
    { src = "https://github.com/tronikelis/ts-autotag.nvim" },


    -- Snippets
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },


    -- Tools
    { src = "https://github.com/chomosuke/typst-preview.nvim" },
    { src = "https://github.com/lambdalisue/vim-suda" },
    { src = "https://github.com/kawre/leetcode.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/G00380316/ssh-launcher.nvim" },
    { src = "https://github.com/wojciech-kulik/xcodebuild.nvim" },
})


--- VIM SETTINGS ---

vim.cmd([[set mouse=]])
vim.cmd([[set noswapfile]])

vim.cmd([[hi @lsp.type.number gui=italic]])
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.cmd(":hi statusline guibg=NONE")
vim.cmd(":hi signcolumn guibg=NONE")
vim.cmd [[
  highlight CursorLine cterm=NONE ctermbg=236 guibg=#2e2e2e
]]
vim.cmd("set completeopt+=noselect")
vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])

local indent = 4
vim.o.tabstop = indent     -- Visual width of a tab character
vim.o.shiftwidth = indent  -- Width of an indentation level (used for >> and <<)
vim.o.softtabstop = indent -- How many spaces a <Tab> counts for while editing
vim.o.expandtab = true     -- Convert tabs to spaces (set to false if you want actual tabs)
vim.o.smartindent = true   -- Makes indenting "smarter" based on synta
vim.o.matchtime = 2        -- How long to show matching bracket
vim.o.paste = false

vim.o.autoread = true -- Auto reload files changed outside vim

vim.o.winborder = "rounded"

vim.o.smartcase = true -- Case sensitive if uppercase in search
vim.o.hlsearch = true  -- `hlsearch = false`: Disables the highlighting of search results after searching.
vim.o.incsearch = true -- `incsearch = true`: Shows incremental search results as you type.

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.guicursor = "n-v-c-sm:block-blinkon1,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/Cursor"
vim.o.signcolumn = "yes"
vim.o.scrolloff = 10 -- Keeps 10 lines of context around the cursor when scrolling.
vim.o.wrap = true
-- Stops words from being broken by wrapping
vim.o.linebreak = true
vim.o.wrapmargin = 0                 -- " Disable margin-based line wrapping
vim.o.textwidth = 0                  -- " Disable hard wrapping at a fixed width
vim.opt.formatoptions:remove("t")    -- " Remove the 't' flag to stop automatic text wrapping
vim.opt.iskeyword:append("-")        -- Treat dash as part of word
vim.opt.iskeyword:append("_")        -- Treat dash as part of word
vim.o.updatetime = 50
vim.o.hidden = true                  -- Allow hidden buffers
vim.o.errorbells = false             -- No error bells
vim.o.backspace = "indent,eol,start" -- Better backspace behavior

vim.o.termguicolors = true
vim.o.undofile = true
vim.o.clipboard = "unnamedplus" -- Adding clipboard func with wl-clipboard
vim.o.timeoutlen = 500          -- Key timeout duration
vim.o.ttimeoutlen = 0           -- Key code timeout
vim.diagnostic.config({ virtual_text = true })
vim.g.mapleader = " "


require("lsp")
require("plugins")
require("autocmd")
require("mappings")


vim.cmd("colorscheme kanagawa")

local highlight = {
    "RainbowDelimiterRed",
    "RainbowDelimiterYellow",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
}

-- Ensure the highlight groups exist
local hooks = require("ibl.hooks")

hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { link = "Red" })
    vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { link = "Yellow" })
    vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { link = "Blue" })
    vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { link = "Orange" })
    vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { link = "Green" })
    vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { link = "Purple" })
end)

require("rainbow-delimiters.setup").setup({
    highlight = highlight,
})

vim.g.rainbow_delimiters = {
    highlight = highlight,
}

require("ibl").setup({
    indent = { highlight = highlight },
    scope = {
        highlight = highlight,
        show_start = false,
        show_end = false,
    },
})

local lualine = require("lualine")

local function floaterm_tabline()
    local tabs = {}
    local current = vim.api.nvim_get_current_buf()

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].filetype == "floaterm"
        then
            local name = vim.fn.fnamemodify(
                vim.api.nvim_buf_get_name(buf),
                ":t"
            )

            local label = (buf == current and " " or " ")
                .. (name ~= "" and name or "Terminal")

            table.insert(tabs, label)
        end
    end

    return table.concat(tabs, " | ")
end

local kanagawa = require("lualine.themes.auto")

-- for _, m in pairs(kanagawa) do
-- 	if m.x then
-- 		m.x.bg = "none"
-- 	end
-- end

local mode = {
    "mode",
    fmt = function(str)
        return " " .. str
    end,
}

local diff = {
    "diff",
    symbols = {
        added = " ",
        modified = " ",
        removed = " ",
    },
}

local filename = {
    "filename",
    file_status = true,
    path = 0,
}

local branch = {
    "branch",
    icon = "",
}

local lsp_status = {
    'lsp_status',
    icon = '', -- f013
    symbols = {
        -- Standard unicode symbols to cycle through for LSP progress:
        spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
        -- Standard unicode symbol for when LSP is done:
        done = '✓',
        -- Delimiter inserted between LSP names:
        separator = ' ',
    },
    -- List of LSP names to ignore (e.g., `null-ls`):
    ignore_lsp = {},
    -- Display the LSP name
    show_name = true,
}

lualine.setup({
    options = {
        icons_enabled = true,
        theme = kanagawa,
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "|", right = "" },
        disabled_filetypes = {
            statusline = { "oil", "toggleterm", "terminal" },
            winbar = { "oil", "toggleterm", "terminal" },
        },
    },
    sections = {
        lualine_a = { mode },
        lualine_b = { branch },
        lualine_c = { diff, filename },
        lualine_x = {
            {
                floaterm_tabline,
                cond = function()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.bo[buf].filetype == "floaterm" then
                            return true
                        end
                    end
                    return false
                end,
            },
            {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                sections = { "error", "warn", "info", "hint" },
                symbols = {
                    error = " ",
                    warn  = " ",
                    info  = " ",
                    hint  = "󰌵 ",
                },
                update_in_insert = true,
            },
            { "filetype" },
            lsp_status
        },
    },
})
