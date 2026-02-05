
--- PLUGIN CONFIGS ---

require("kanagawa").setup({
    compile = false,  -- enable compiling the colorscheme
    undercurl = true, -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = false },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = true,    -- do not set background color
    dimInactive = false,   -- dim inactive window `:h hl-NormalNC`
    terminalColors = true, -- define vim.g.terminal_color_{0,17}
    colors = {             -- add/modify theme and palette colors
        palette = {},
        theme = {
            wave = {},
            dragon = {},
            all = {
                ui = {
                    bg_gutter = "none",
                    border = "rounded"
                }
            }
        },
    },
    overrides = function(colors) -- add/modify highlights
        local theme = colors.theme
        return {
            NormalFloat = { bg = "none" },
            FloatBorder = { bg = "none" },
            FloatTitle = { bg = "none" },
            Pmenu = { fg = theme.ui.shade0, bg = "NONE", blend = vim.o.pumblend }, -- add `blend = vim.o.pumblend` to enable transparency
            PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = theme.ui.bg_m1 },
            PmenuThumb = { bg = theme.ui.bg_p2 },

            -- Save an hlgroup with dark background and dimmed foreground
            -- so that you can use it where your still want darker windows.
            -- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
            NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

            -- Popular plugins that open floats will link to NormalFloat by default;
            -- set their background accordingly if you wish to keep them dark and borderless
            LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
            MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
            TelescopeTitle = { fg = theme.ui.special, bold = true },
            TelescopePromptBorder = { fg = theme.ui.special, },
            TelescopeResultsNormal = { fg = theme.ui.fg_dim, },
            TelescopeResultsBorder = { fg = theme.ui.special, },
            TelescopePreviewBorder = { fg = theme.ui.special },
        }
    end,
    theme = "wave",    -- Load "wave" theme when 'background' option is not set
    background = {     -- map the value of 'background' option to a theme
        dark = "wave", -- try "dragon" !
    },
})

require("fzf-lua").setup({
    winopts = {
        preview = {
            layout = "vertical",
            vertical = "up:60%",
        },
    },
    lsp = {
        symbols = {
            symbol_icons = true,
        },
    },
})

require("ts-autotag").setup({})
require 'nvim-treesitter'.setup {
    -- Directory to install parsers and queries to (prepended to `runtimepath` to have priority)
    install_dir = vim.fn.stdpath('data') .. '/site'
}
require 'nvim-treesitter'.install { 'javascript' }

require("snacks").setup({
    picker = {
        ui_select = true, -- Replaces telescope-ui-select
        layout = {
            cycle = true,
            style = "modern", -- You can use "ivy", "telescope", or "modern"
        },
        win = {
            input = {
                keys = {
                    ["<C-d>"] = { "bufdelete", mode = { "n", "i" } },
                },
            },
        },
        matcher = {
            frecency = true,
        },
        exclude = {
            "node_modules",
            ".git",
            "dist",
            "build",
            "target",
        },
        sources = {
            files = { hidden = true }
        }
    },
})


require("oil").setup({
    default_file_explorer = true, -- Replaces netrw
    watch_for_changes = true,
    delete_to_trash = true,
    columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
    },
    skip_confirm_for_simple_edits = true,
    use_default_keymaps = false,
    view_options = {
        show_hidden = true,
    },
    float = {
        padding = 2,
        max_width = 80,
        max_height = 20,
        border = "rounded",
    },
    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["zv"] = { "actions.select", opts = { vertical = true } },
        ["zh"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["<BS>"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
    },
    keys = {
        vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            require("oil").toggle_float()
        end, { desc = "Toggle Oil Float" }),
    },
})


require("image").setup({
    backend = "kitty",
    processor = "magick_cli", -- or "magick_rock"
    integrations = {
        markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            only_render_image_at_cursor_mode = "popup",
            floating_windows = false,
            filetypes = { "markdown", "vimwiki" },
        },
        neorg = {
            enabled = true,
            filetypes = { "norg" },
        },
        typst = {
            enabled = true,
            filetypes = { "typst" },
        },
        html = {
            enabled = false,
        },
        css = {
            enabled = false,
        },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = false,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
})


vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits

vim.api.nvim_create_autocmd("FileType", {
    pattern = "floaterm",
    callback = function()
        local opts = { noremap = true, silent = true, buffer = true }

        -- Terminal mode (most important)
        vim.keymap.set("t", "<C-k>", "<C-\\><C-n>:q<CR>", opts)

        -- Normal mode (optional, but useful)
        vim.keymap.set("n", "<C-k>", ":q<CR>", opts)
    end,
})


vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true }) -- Navigate to the previous floating terminal
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true }) -- Open a new floating terminal
vim.api.nvim_set_keymap("v", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-t>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })


require("gitsigns").setup({
    signs = {
        add = { text = "+" }, -- Symbol for added lines
        change = { text = "~" }, -- Symbol for changed lines
        delete = { text = "_" }, -- Symbol for deleted lines
        topdelete = { text = "‾" }, -- Symbol for deleted lines at the top
        changedelete = { text = "~" }, -- Symbol for changed and deleted lines
    },
    update_debounce = 100, -- Debounce time in milliseconds for updates
    status_formatter = nil,
})


require("leetcode").setup({
    -- configuration goes here
    ---@type lc.lang
    lang = "python3",
    ---@type boolean
    image_support = true,
    ---@type lc.storage
    storage = {
        home = "~/Documents/Github/Leetcode",
        cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
})

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
    "                                                 ",
    " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
    " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
    " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
    " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
    " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
    " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
    "                                                 ",
}

dashboard.section.header.opts.position = "center"
dashboard.section.footer.opts.position = "center"
dashboard.section.buttons.val = {
    dashboard.button("o", "  Open Folders", function()
        require("oil").open("~/")
    end),
    dashboard.button("p", "  Open Github Folders", function()
        require("oil").open("~/Documents/Github/")
    end),
    dashboard.button("r", "  Connect to Remote", "<cmd>SshLauncher<CR>"),
    dashboard.button(
        "l",
        "  LeetCode",
        "<cmd>silent !kitty @ launch --type=os-window nvim +'Leet'<CR>"
    ),
    dashboard.button("t", "  Terminal", function()
        vim.cmd("term")
        vim.api.nvim_feedkeys('i', 'n', false)
    end),
}
local fortune = require("alpha.fortune")
dashboard.section.footer.val = fortune()

dashboard.section.header.opts.hl = "Statement"
dashboard.section.buttons.opts.hl = "Type"
dashboard.section.footer.opts.hl = "Type"

table.insert(dashboard.opts.layout, 1, { type = "padding", val = 5 })

alpha.setup(dashboard.opts)


require("ssh_launcher").setup()


