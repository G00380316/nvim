-- ============================================================
-- PLUGIN CONFIGS
-- ============================================================

local Snacks = require("snacks")

-- ============================================================
-- Kanagawa Theme
-- ============================================================

require("kanagawa").setup({
    compile = false,
    undercurl = true,

    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = false },
    statementStyle = { bold = true },
    typeStyle = {},

    transparent = false,
    dimInactive = false,
    terminalColors = true,

    colors = {
        palette = {},
        theme = {
            wave = {},
            dragon = {},
            all = {
                ui = {
                    bg_gutter = "none",
                    border = "rounded",
                },
            },
        },
    },

    overrides = function(colors)
        local theme = colors.theme

        local makeDiagnosticColor = function(color)
            local c = require("kanagawa.lib.color")
            return {
                fg = color,
                bg = c(color):blend(theme.ui.bg, 0.95):to_hex(),
            }
        end

        return {
            NormalFloat = { bg = theme.ui.bg_m1 },
            FloatBorder = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m1 },
            FloatTitle = { fg = theme.ui.special, bg = theme.ui.bg_m1, bold = true },

            Pmenu = {
                fg = theme.ui.shade0,
                bg = theme.ui.bg_m1,
                blend = vim.o.pumblend,
            },
            PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = theme.ui.bg_m1 },
            PmenuThumb = { bg = theme.ui.bg_p2 },

            NormalDark = {
                fg = theme.ui.fg_dim,
                bg = theme.ui.bg_m3,
            },

            LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
            MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

            TelescopeTitle = { fg = theme.ui.special, bold = true },
            TelescopePromptBorder = { fg = theme.ui.special },
            TelescopeResultsNormal = { fg = theme.ui.fg_dim },
            TelescopeResultsBorder = { fg = theme.ui.special },
            TelescopePreviewBorder = { fg = theme.ui.special },

            BufferLineBufferSelected = {
                fg = theme.ui.fg,
                bg = theme.ui.bg_p1,
                bold = true,
            },
            BufferLineFill = { bg = theme.ui.bg_m3 },
            BufferLineBackground = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
            BufferLineSeparator = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m3 },
            BufferLineSeparatorVisible = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m3 },
            BufferLineSeparatorSelected = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
            BufferLineIndicatorSelected = {
                fg = theme.ui.special,
                sp = theme.ui.special,
                bold = true,
                underline = true,
            },

            OilNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            OilNormalNC = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            OilCursorLine = { bg = theme.ui.bg_p1 },
            OilSelectedFile = { fg = theme.ui.fg, bg = theme.ui.bg_p1, bold = true },
            OilSelectedFileSign = { fg = theme.ui.special, bg = theme.ui.bg_m1 },
            OilWinSeparator = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m1 },
            WinSeparator = { fg = theme.ui.bg_p2, bg = theme.ui.bg },

            DiagnosticVirtualTextHint = makeDiagnosticColor(theme.diag.hint),
            DiagnosticVirtualTextInfo = makeDiagnosticColor(theme.diag.info),
            DiagnosticVirtualTextWarn = makeDiagnosticColor(theme.diag.warning),
            DiagnosticVirtualTextError = makeDiagnosticColor(theme.diag.error),

            String = {
                fg = colors.palette.carpYellow,
                italic = true,
            },
        }
    end,

    theme = "wave",
    background = {
        dark = "dragon",
    },
})


-- ============================================================
-- Treesitter / Auto Tag
-- ============================================================

require("ts-autotag").setup({})

require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})


-- ============================================================
-- Snacks
-- ============================================================

require("snacks").setup({
    bigfile = { enabled = true },
    dashboard = {
        enabled = true,
        width = 48,
        preset = {
            header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
            keys = {
                { icon = "󰉋 ", key = "o", desc = "Open Workspace", action = "<C-o>" },
                {
                    icon = " ",
                    key = "f",
                    desc = "Find File",
                    action = function()
                        Snacks.picker.files({ cwd = require("workspace").get() })
                    end,
                },
                {
                    icon = " ",
                    key = "g",
                    desc = "Find Text",
                    action = function()
                        Snacks.picker.grep({ cwd = require("workspace").get() })
                    end,
                },
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                { icon = " ", key = "t", desc = "Terminal", action = "<C-t>" },
                { icon = " ", key = "q", desc = "Quit", action = ":confirm qa" },
            },
        },
        sections = {
            { section = "header" },
            { section = "keys",  gap = 1, padding = 1 },
            {
                icon = " ",
                title = "Recent Workspaces",
                section = "projects",
                dirs = function() return require("workspace").recent(5) end,
                session = false,
                pick = false,
                limit = 5,
                padding = 1,
                action = function(dir)
                    require("workspace").open(dir, { exact = true })
                end,
            },
        },
    },
    input = { enabled = true },
    quickfile = { enabled = true },
    picker = {
        ui_select = true,

        layout = {
            cycle = true,
            style = "modern",
        },

        win = {
            input = {
                keys = {
                    ["<C-d>"] = { "bufdelete", mode = { "n", "i" } },
                    ["<Space>l"] = { "flash", mode = { "n", "i" } },
                    ["s"] = { "flash" },
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
            files = {
                hidden = true,
            },
        },

        actions = {
            flash = function(picker)
                require("flash").jump({
                    pattern = "^",
                    label = { after = { 0, 0 } },
                    search = {
                        mode = "search",
                        exclude = {
                            function(win)
                                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                            end,
                        },
                    },
                    action = function(match)
                        local idx = picker.list:row2idx(match.pos[1])
                        picker.list:_move(idx, true, true)
                    end,
                })
            end,
        },

    },
})

-- A dashboard is the permanent empty editor zone, so closing it should quit
-- Neovim rather than let the fixed sidebar or terminal consume its space.
vim.api.nvim_create_autocmd("User", {
    pattern = "SnacksDashboardOpened",
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype == "snacks_dashboard" then
            require("dashboard").keep_single(buf)
            vim.keymap.set("n", "q", "<cmd>confirm qa<CR>", {
                buffer = buf,
                silent = true,
                desc = "Quit from empty workspace dashboard",
            })
            vim.keymap.set("n", "<C-q>", "<cmd>confirm qa<CR>", {
                buffer = buf,
                silent = true,
                desc = "Quit from empty workspace dashboard",
            })
        end
    end,
    desc = "Keep the dashboard as the editor-area filler",
})


-- ============================================================
-- Oil File Explorer Sidebar
-- ============================================================

local oil = require("oil")
local explorer_width = 30
local last_editor_win = nil
local last_panel_win = nil

local function leetcode_active()
    return vim.g.leetcode_active == true
end

local function window_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function window_filetype(win)
    return window_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype or ""
end

local function is_panel(win)
    local filetype = window_filetype(win)
    return filetype == "oil"
        or filetype == "floaterm"
        or filetype == "qf"
end

local function find_window(filetype)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if window_filetype(win) == filetype then
            return win
        end
    end
end

local function find_editor_window()
    if window_is_valid(last_editor_win)
        and vim.api.nvim_win_get_tabpage(last_editor_win) == vim.api.nvim_get_current_tabpage()
        and not is_panel(last_editor_win)
    then
        return last_editor_win
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local config = vim.api.nvim_win_get_config(win)
        if not is_panel(win) and config.relative == "" then
            return win
        end
    end
end

local function focus_editor()
    local current = vim.api.nvim_get_current_win()
    if is_panel(current) then
        last_panel_win = current
    end
    local editor = find_editor_window()
    if editor then
        last_editor_win = editor
        vim.api.nvim_set_current_win(editor)
        return true
    end
    return false
end

local function focus_editor_or_last_panel()
    local current = vim.api.nvim_get_current_win()
    if is_panel(current) then
        focus_editor()
    elseif window_is_valid(last_panel_win) and is_panel(last_panel_win) then
        last_editor_win = current
        vim.api.nvim_set_current_win(last_panel_win)
    end
end

local function switch_editor_buffer(direction)
    require("buffers").cycle(direction)
end

local function focus_terminal()
    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "floaterm" then
        vim.cmd("FloatermToggle")
        return
    end

    local terminal = find_window("floaterm")
    if terminal then
        last_editor_win = not is_panel(current) and current or last_editor_win
        last_panel_win = terminal
        vim.api.nvim_set_current_win(terminal)
        vim.cmd("startinsert")
    else
        focus_editor()
        vim.cmd("FloatermToggle")
    end
end

vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
        local win = vim.api.nvim_get_current_win()
        if not is_panel(win) and vim.api.nvim_win_get_config(win).relative == "" then
            last_editor_win = win
        end
    end,
    desc = "Remember the editor window between sidebar and terminal visits",
})

local function oil_entry_path()
    local entry = oil.get_cursor_entry()
    local directory = oil.get_current_dir()
    if not entry or not directory then return nil, nil end
    return vim.fs.joinpath(directory, entry.name), entry
end

-- Directories continue navigating inside the sidebar. Files deliberately open
-- in the editor zone so Oil itself is never replaced by a selected file.
local function select_oil_entry(kind)
    local path, entry = oil_entry_path()
    if not path then return end
    if entry.type == "directory" then
        oil.select()
        return
    end

    focus_editor()
    if kind == "vertical" then
        vim.cmd("vsplit " .. vim.fn.fnameescape(path))
    elseif kind == "horizontal" then
        vim.cmd("split " .. vim.fn.fnameescape(path))
    elseif kind == "tab" then
        vim.cmd("tabedit " .. vim.fn.fnameescape(path))
    else
        vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
end

local function close_oil_sidebar()
    local win = find_window("oil")
    if win then vim.api.nvim_win_close(win, true) end
end

-- The explorer must never be fully closable, only hidden (<C-e> always brings
-- it back). q/<C-c> already route through close_oil_sidebar; this guards the
-- remaining native ways to lose the window: window-close commands and typing
-- :q/:qa while it's the focused window.
vim.api.nvim_create_user_command("OilSidebarQuitGuard", function()
    close_oil_sidebar()
    vim.notify("The explorer sidebar only hides, it never quits — use <C-e> to reopen, or quit from the dashboard",
        vim.log.levels.INFO)
end, { desc = "Hide the persistent Oil sidebar instead of closing/quitting" })

vim.cmd(
    [[cnoreabbrev <expr> q (getcmdtype() ==# ':' && getcmdline() ==# 'q' && &filetype ==# 'oil') ? 'OilSidebarQuitGuard' : 'q']])
vim.cmd(
    [[cnoreabbrev <expr> qa (getcmdtype() ==# ':' && getcmdline() ==# 'qa' && &filetype ==# 'oil') ? 'OilSidebarQuitGuard' : 'qa']])
vim.cmd(
    [[cnoreabbrev <expr> q! (getcmdtype() ==# ':' && getcmdline() ==# 'q!' && &filetype ==# 'oil') ? 'OilSidebarQuitGuard' : 'q!']])
vim.cmd(
    [[cnoreabbrev <expr> qa! (getcmdtype() ==# ':' && getcmdline() ==# 'qa!' && &filetype ==# 'oil') ? 'OilSidebarQuitGuard' : 'qa!']])

oil.setup({
    default_file_explorer = true,
    watch_for_changes = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    columns = { "icon" },
    use_default_keymaps = false,
    view_options = {
        show_hidden = true,
        natural_order = true,
        sort = {
            { "type", "asc" },
            { "name", "asc" },
        },
    },
    win_options = {
        number = false,
        relativenumber = false,
        cursorline = true,
        signcolumn = "yes:3",
        winfixwidth = true,
        winhighlight = "Normal:OilNormal,NormalNC:OilNormalNC,WinSeparator:OilWinSeparator",
    },
    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = function() select_oil_entry() end,
        ["zv"] = function() select_oil_entry("vertical") end,
        ["zh"] = function() select_oil_entry("horizontal") end,
        ["gT"] = function() select_oil_entry("tab") end,
        ["<C-t>"] = focus_terminal,
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = close_oil_sidebar,
        ["q"] = close_oil_sidebar,
        ["<Space>l"] = "actions.refresh",
        ["<BS>"] = { "actions.parent", mode = "n" },
        ["gr"] = { "actions.open_cwd", mode = "n" },
        ["gc"] = function()
            local path = oil_entry_path()
            if path then
                local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
                require("workspace").set(directory, { exact = true })
            end
        end,
        ["gd"] = function()
            local path = oil_entry_path()
            if path then vim.system({ "open", "-R", path }, { detach = true }) end
        end,
        ["go"] = function()
            local path = oil_entry_path()
            if path then vim.system({ "open", path }, { detach = true }) end
        end,
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["gt"] = { "actions.toggle_trash", mode = "n" },
        ["<Tab>"] = function() switch_editor_buffer(1) end,
        ["<S-Tab>"] = function() switch_editor_buffer(-1) end,
    },
})

require("oil-git-status").setup({
    show_ignored = true,
    -- The first column is the index (staged), the second is the working tree.
    -- These mirror the familiar NvimTree-style Git marks instead of raw
    -- porcelain letters.
    symbols = {
        index = {
            ["!"] = "◌",
            ["?"] = "★",
            ["A"] = "✓",
            ["C"] = "✓",
            ["D"] = "✓",
            ["M"] = "✓",
            ["R"] = "➜",
            ["T"] = "✓",
            ["U"] = "",
            [" "] = " ",
        },
        working_tree = {
            ["!"] = "◌",
            ["?"] = "★",
            ["A"] = "+",
            ["C"] = "≡",
            ["D"] = "",
            ["M"] = "✗",
            ["R"] = "➜",
            ["T"] = "≠",
            ["U"] = "",
            [" "] = " ",
        },
    },
})

local oil_follow_namespace = vim.api.nvim_create_namespace("OilFollowedEditorFile")

local function mark_oil_entry(win, filename)
    if not window_is_valid(win) then return end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "oil" then return end

    vim.api.nvim_buf_clear_namespace(buf, oil_follow_namespace, 0, -1)
    for line = 1, vim.api.nvim_buf_line_count(buf) do
        local entry = oil.get_entry_on_line(buf, line)
        if entry and entry.name == filename then
            vim.api.nvim_buf_set_extmark(buf, oil_follow_namespace, line - 1, 0, {
                line_hl_group = "OilSelectedFile",
                sign_text = "▎",
                sign_hl_group = "OilSelectedFileSign",
                priority = 150,
            })
            vim.api.nvim_win_set_cursor(win, { line, 0 })
            return
        end
    end
end

local function reveal_editor_file_in_oil(path)
    local sidebar = find_window("oil")
    if not sidebar or path == "" or vim.fn.filereadable(path) ~= 1 then return end

    local directory = vim.fs.normalize(vim.fs.dirname(path))
    local filename = vim.fs.basename(path)
    local oil_buf = vim.api.nvim_win_get_buf(sidebar)
    local current_directory = oil.get_current_dir(oil_buf)

    if current_directory and vim.fs.normalize(current_directory) == directory then
        mark_oil_entry(sidebar, filename)
        return
    end

    vim.api.nvim_win_call(sidebar, function()
        oil.open(directory, nil, function()
            vim.schedule(function() mark_oil_entry(sidebar, filename) end)
        end)
    end)
end

local function open_oil_sidebar(opts)
    opts = opts or {}
    if leetcode_active() then
        close_oil_sidebar()
        if opts.focus then vim.notify("Oil is disabled in LeetCode", vim.log.levels.INFO) end
        return
    end

    local current = vim.api.nvim_get_current_win()
    local existing = find_window("oil")
    if existing then
        if opts.focus then
            last_editor_win = not is_panel(current) and current or last_editor_win
            last_panel_win = existing
            vim.api.nvim_set_current_win(existing)
        end
        return existing
    end

    focus_editor()
    local editor_buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(editor_buf) == ""
        and vim.bo[editor_buf].buftype == ""
        and not vim.bo[editor_buf].modified
    then
        -- Give the editor side a durable filler before splitting. The generic
        -- empty-buffer cleanup would otherwise wipe it and collapse the split.
        require("dashboard").open({ win = vim.api.nvim_get_current_win() })
    end
    vim.cmd("topleft " .. explorer_width .. "vsplit")
    local sidebar = vim.api.nvim_get_current_win()
    oil.open(require("workspace").get(), nil, function()
        if not window_is_valid(sidebar) then return end
        vim.w[sidebar].oil_sidebar = true
        vim.wo[sidebar].winfixwidth = true
        vim.api.nvim_win_set_width(sidebar, explorer_width)
        local editor = find_editor_window()
        if editor then
            reveal_editor_file_in_oil(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(editor)))
        end
        -- Oil finalizes its own window setup after this callback returns, so
        -- reclaiming focus has to happen on the next tick to actually stick.
        if not opts.focus then vim.schedule(focus_editor) end
    end)
    last_panel_win = sidebar
    return sidebar
end

local function focus_tree()
    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "oil" then
        close_oil_sidebar()
        return
    end
    open_oil_sidebar({ focus = true })
end

-- Keep the explorer at a compact IDE-sidebar width. winfixwidth prevents
-- editor splits and equalize commands from stretching it.
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    pattern = "oil",
    callback = function(args)
        local win = vim.fn.bufwinid(args.buf)
        if win == -1 then
            return
        end

        vim.wo[win].winfixwidth = true
        if vim.w[win].oil_sidebar and vim.api.nvim_win_get_width(win) ~= explorer_width then
            vim.api.nvim_win_set_width(win, explorer_width)
        end

        -- <C-w>q/<C-w>c/ZZ bypass the q/<C-c> keymaps below since they close the
        -- window directly; redirect them to the same hide-only path.
        local guard_opts = { buffer = args.buf, silent = true, nowait = true }
        vim.keymap.set("n", "<C-w>q", close_oil_sidebar, guard_opts)
        vim.keymap.set("n", "<C-w>c", close_oil_sidebar, guard_opts)
        vim.keymap.set("n", "ZZ", close_oil_sidebar, guard_opts)
    end,
    desc = "Lock the project explorer to a compact sidebar width",
})

vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
    if vim.fn.mode():sub(1, 1) ~= "n" then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
    focus_tree()
end, {
    noremap = true,
    silent = true,
    desc = "Show/Hide File Explorer",
})

-- Keep the project explorer present like an IDE sidebar. It stays open when
-- files are selected; q, Ctrl-C, or Ctrl-E explicitly hide it.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.defer_fn(function()
            open_oil_sidebar({ focus = false })
        end, 50)
    end,
    desc = "Open the persistent project explorer sidebar",
})

vim.api.nvim_create_autocmd("TabNewEntered", {
    callback = function()
        vim.schedule(function() open_oil_sidebar({ focus = false }) end)
    end,
    desc = "Keep the Oil sidebar present in new tabs",
})

vim.api.nvim_create_user_command("OilSidebarOpen", function()
    open_oil_sidebar({ focus = false })
end, { desc = "Open the persistent Oil sidebar" })

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        if not vim.api.nvim_buf_is_valid(args.buf)
            or vim.bo[args.buf].buftype ~= ""
            or vim.bo[args.buf].filetype == "oil"
        then
            return
        end

        local path = vim.api.nvim_buf_get_name(args.buf)
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf)
                and vim.api.nvim_get_current_buf() == args.buf
            then
                reveal_editor_file_in_oil(path)
            end
        end)
    end,
    desc = "Reveal and mark the active editor file in Oil",
})


-- ============================================================
-- Image Rendering
-- Kitty image backend for markdown/images.
-- ============================================================

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = { "*.md", "*.markdown", "*.norg", "*.typ", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    once = true,
    callback = function()
        require("image").setup({
            backend = "kitty",
            processor = "magick_cli",

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
            window_overlap_clear_ft_ignore = {
                "cmp_menu",
                "cmp_docs",
                "snacks_notif",
                "scrollview",
                "scrollview_sign",
            },

            editor_only_render_when_focused = false,
            tmux_show_only_in_active_window = false,

            hijack_file_patterns = {
                "*.png",
                "*.jpg",
                "*.jpeg",
                "*.gif",
                "*.webp",
                "*.avif",
            },
        })
    end,
    desc = "Load image rendering only for documents that need it",
})


-- ============================================================
-- Floaterm
-- ============================================================

vim.g.floaterm_wintype = "split"
vim.g.floaterm_position = "belowright"
local terminal_height = 12
vim.g.floaterm_height = terminal_height
vim.g.floaterm_autoclose = 0
vim.g.floaterm_autohide = 1
vim.g.floaterm_title = "terminal $1/$2"

-- Use the same slim separator language for the bottom panel and sidebar.
vim.opt.fillchars:append({
    vert = "│",
    horiz = "─",
    horizup = "┴",
    horizdown = "┬",
    verthoriz = "┼",
})

local function resize_terminal(delta)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        if vim.bo[bufnr].filetype == "floaterm" then
            local height = vim.api.nvim_win_get_height(win)
            local maximum = math.max(5, vim.o.lines - 6)
            terminal_height = math.max(5, math.min(maximum, height + delta))
            vim.g.floaterm_height = terminal_height
            vim.api.nvim_win_set_height(win, terminal_height)
            return
        end
    end
    vim.notify("Terminal panel is hidden", vim.log.levels.INFO)
end

local function new_terminal()
    focus_editor()
    vim.cmd("FloatermNew --cwd=" .. vim.fn.fnameescape(require("workspace").get()))
end

local terminal_width = 90

local function split_terminal()
    focus_editor()
    vim.cmd(
        "FloatermNew --wintype=vsplit --position=botright --cwd="
        .. vim.fn.fnameescape(require("workspace").get())
    )
end

local function terminal_picker()
    local bufnrs = vim.fn["floaterm#buflist#gather"]()
    if #bufnrs == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
    end

    Snacks.picker.pick({
        title = "Terminals",
        finder = function()
            local items = {}
            for index, bufnr in ipairs(bufnrs) do
                local title = vim.fn.getbufvar(bufnr, "floaterm_title")
                if title == "" or title:find("%$1") then
                    title = string.format("terminal %d/%d", index, #bufnrs)
                end
                local cwd = vim.fn.getbufvar(bufnr, "floaterm_cwd")
                items[#items + 1] = {
                    text = title,
                    bufnr = bufnr,
                    label = title,
                    dir = cwd ~= "" and cwd or nil,
                    current = bufnr == vim.fn["floaterm#buflist#curr"](),
                }
            end
            return items
        end,
        format = function(item)
            local line = { { (item.current and "● " or "  ") .. item.label, "Function" } }
            if item.dir then
                table.insert(line, { "  " .. item.dir, "Comment" })
            end
            return line
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function() vim.fn["floaterm#show"](0, item.bufnr, "") end)
        end,
    })
end

-- Horizontal (bottom-panel) and vertical (side-by-side) floaterm windows need
-- different fixed-size handling; forcing belowright/height onto a vsplit term
-- would fight its own --wintype=vsplit layout.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "floaterm",
    callback = function()
        local opts = {
            noremap = true,
            silent = true,
            buffer = true,
        }

        vim.wo.winhighlight = "WinSeparator:OilWinSeparator"

        if vim.b.floaterm_wintype == "vsplit" then
            vim.wo.winfixwidth = true
            terminal_width = math.min(terminal_width, math.max(40, vim.o.columns - 40))
            vim.api.nvim_win_set_width(0, terminal_width)
        else
            vim.wo.winfixheight = true
            vim.b.floaterm_position = "belowright"
            terminal_height = math.min(terminal_height, math.max(5, vim.o.lines - 6))
            vim.api.nvim_win_set_height(0, terminal_height)

            vim.keymap.set("t", "<C-Up>", function() resize_terminal(3) end, opts)
            vim.keymap.set("t", "<C-Down>", function() resize_terminal(-3) end, opts)
            vim.keymap.set("n", "<C-Up>", function() resize_terminal(3) end, opts)
            vim.keymap.set("n", "<C-Down>", function() resize_terminal(-3) end, opts)
        end
    end,
})

vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "i" }, "<C-t>", focus_terminal, {
    noremap = true,
    silent = true,
    desc = "Focus/toggle bottom terminal",
})

vim.keymap.set("n", "<Space>t", new_terminal, {
    noremap = true,
    silent = true,
    desc = "Open another bottom terminal",
})

vim.keymap.set("n", "<Space>v", split_terminal, {
    noremap = true,
    silent = true,
    desc = "Open a terminal in a vertical split",
})

vim.keymap.set({ "n", "t" }, "zt", function()
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
    terminal_picker()
end, {
    noremap = true,
    silent = true,
    desc = "List and jump to an open terminal",
})

vim.keymap.set("t", "<C-t>", function()
    vim.cmd("stopinsert")
    focus_terminal()
end, { silent = true, desc = "Hide bottom terminal" })

vim.keymap.set("t", "<C-e>", function()
    vim.cmd("stopinsert")
    focus_tree()
end, { silent = true, desc = "Focus file explorer" })

local function navigate_window(direction, tmux_flag)
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end

    local current = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. direction)

    -- At a Neovim edge, continue into the adjacent tmux pane when available.
    if vim.api.nvim_get_current_win() == current and vim.env.TMUX and vim.env.TMUX ~= "" then
        vim.system({ "tmux", "select-pane", tmux_flag }, { detach = true })
        return
    end

    if window_filetype(vim.api.nvim_get_current_win()) == "floaterm" then
        vim.cmd("startinsert")
    end
end

local function map_window_navigation(lhs, direction, tmux_flag, label)
    vim.keymap.set({ "n", "t" }, lhs, function()
        navigate_window(direction, tmux_flag)
    end, { silent = true, desc = "Move to " .. label .. " window/tmux pane" })
end

map_window_navigation("<C-h>", "h", "-L", "left")
map_window_navigation("<C-j>", "j", "-D", "lower")
map_window_navigation("<C-k>", "k", "-U", "upper")
map_window_navigation("<C-l>", "l", "-R", "right")

vim.api.nvim_create_user_command("FocusEditor", focus_editor_or_last_panel, {
    desc = "Switch between the editor and the last focused panel",
})
vim.api.nvim_create_user_command("EditorFocus", focus_editor, {
    desc = "Focus the center editor without toggling back to a panel",
})
vim.api.nvim_create_user_command("FocusTree", focus_tree, { desc = "Focus or toggle the file explorer" })
vim.api.nvim_create_user_command("FocusTerminal", focus_terminal, { desc = "Focus or toggle the terminal" })
vim.api.nvim_create_user_command("TerminalNew", new_terminal, { desc = "Open another bottom terminal" })
vim.api.nvim_create_user_command("TerminalSplit", split_terminal, { desc = "Open a terminal in a vertical split" })
vim.api.nvim_create_user_command("TerminalList", terminal_picker, { desc = "List and jump to an open terminal" })
vim.api.nvim_create_user_command("EditorTabNext", function()
    switch_editor_buffer(1)
end, { desc = "Open the next editor tab from any panel" })
vim.api.nvim_create_user_command("EditorTabPrevious", function()
    switch_editor_buffer(-1)
end, { desc = "Open the previous editor tab from any panel" })

-- ============================================================
-- Source Control
-- ============================================================

local git_width = explorer_width

require("diffview").setup({
    enhanced_diff_hl = true,
    use_icons = true,
    file_panel = {
        listing_style = "tree",
        win_config = {
            position = "left",
            width = git_width,
        },
    },
})

local lazygit_buf = nil

local function close_diffviews()
    pcall(function()
        local lib = require("diffview.lib")
        for index = #lib.views, 1, -1 do
            local view = lib.views[index]
            pcall(view.close, view)
            lib.dispose_view(view)
        end
    end)
end

local function remember_editor_before_lazygit(win, buf)
    vim.w[win].lazygit_previous_buf = buf
    vim.w[win].lazygit_previous_bufhidden = vim.bo[buf].bufhidden
    if vim.bo[buf].buftype == "" then vim.bo[buf].bufhidden = "hide" end
end

local function lazygit_editor_window()
    if focus_editor() then return vim.api.nvim_get_current_win() end

    -- Oil and the other panels are protected: LazyGit may only replace an
    -- editor buffer. Recreate the editor zone if this tab has only panels.
    if is_panel(vim.api.nvim_get_current_win()) then
        vim.cmd("rightbelow vsplit")
        require("dashboard").open({ win = vim.api.nvim_get_current_win() })
    end
    return vim.api.nvim_get_current_win()
end

local function restore_editor_after_lazygit(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_is_valid(win) then
            local previous = vim.w[win].lazygit_previous_buf
            if previous
                and previous ~= buf
                and vim.api.nvim_buf_is_valid(previous)
            then
                vim.api.nvim_win_set_buf(win, previous)
                vim.bo[previous].bufhidden = vim.w[win].lazygit_previous_bufhidden or ""
            else
                require("dashboard").open({ win = win })
            end
            vim.w[win].lazygit_previous_buf = nil
            vim.w[win].lazygit_previous_bufhidden = nil
        end
    end
end

local function close_lazygit()
    local buf = lazygit_buf
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    restore_editor_after_lazygit(buf)
    local job = vim.b[buf].terminal_job_id
    if job then pcall(vim.fn.jobstop, job) end
    if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    lazygit_buf = nil
end

local function toggle_lazygit()
    if vim.fn.executable("lazygit") ~= 1 then
        vim.notify("lazygit is not installed", vim.log.levels.ERROR)
        return
    end

    if lazygit_buf and vim.api.nvim_buf_is_valid(lazygit_buf) then
        if vim.api.nvim_get_current_buf() == lazygit_buf then
            restore_editor_after_lazygit(lazygit_buf)
        else
            local win = lazygit_editor_window()
            local current = vim.api.nvim_get_current_buf()
            if current ~= lazygit_buf then remember_editor_before_lazygit(win, current) end
            vim.api.nvim_win_set_buf(win, lazygit_buf)
            vim.cmd("startinsert")
        end
        return
    end

    local workspace = require("workspace")
    local root = workspace.git_root()
    if not root then
        vim.notify("Workspace is not a Git repository: " .. workspace.get(), vim.log.levels.WARN)
        return
    end

    local editor_win = lazygit_editor_window()
    remember_editor_before_lazygit(editor_win, vim.api.nvim_get_current_buf())
    lazygit_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(editor_win, lazygit_buf)
    local job = vim.fn.jobstart({ "lazygit" }, { term = true, cwd = root })
    if job <= 0 then
        local failed_buf = lazygit_buf
        restore_editor_after_lazygit(failed_buf)
        pcall(vim.api.nvim_buf_delete, failed_buf, { force = true })
        lazygit_buf = nil
        vim.notify("Could not start lazygit", vim.log.levels.ERROR)
        return
    end
    vim.bo[lazygit_buf].filetype = "lazygit"
    vim.bo[lazygit_buf].buflisted = true
    vim.bo[lazygit_buf].bufhidden = "hide"
    vim.b[lazygit_buf].lazygit_editor = true
    pcall(vim.api.nvim_buf_set_name, lazygit_buf, "lazygit://" .. root)

    vim.keymap.set("n", "q", close_lazygit, {
        buffer = lazygit_buf,
        silent = true,
        desc = "Close LazyGit editor buffer",
    })
    vim.keymap.set({ "n", "t" }, "<C-q>", close_lazygit, {
        buffer = lazygit_buf,
        silent = true,
        desc = "Close LazyGit editor buffer",
    })

    vim.api.nvim_create_autocmd("TermClose", {
        buffer = lazygit_buf,
        once = true,
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then
                    restore_editor_after_lazygit(args.buf)
                    pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
                end
                if lazygit_buf == args.buf then lazygit_buf = nil end
            end)
        end,
        desc = "Restore the editor after LazyGit exits",
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = lazygit_buf,
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf)
                    and vim.api.nvim_get_current_buf() == args.buf
                then
                    vim.cmd("startinsert")
                end
            end)
        end,
        desc = "Enter terminal mode when revisiting the LazyGit buffer",
    })
    vim.cmd("startinsert")
end

local function close_all_git_windows()
    close_diffviews()
    close_lazygit()
end

vim.api.nvim_create_user_command("GitCloseAll", close_all_git_windows, {
    desc = "Close LazyGit and every Diffview window",
})

vim.api.nvim_create_user_command("GitPanel", toggle_lazygit, {
    desc = "Toggle the LazyGit editor buffer",
})

vim.keymap.set({ "n", "t" }, "zg", function()
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
    toggle_lazygit()
end, {
    noremap = true,
    silent = true,
    desc = "Focus/toggle LazyGit editor buffer",
})
vim.keymap.set("n", "zgd", function()
    vim.cmd("DiffviewOpen")
end, { desc = "Git changed-file diff" })
vim.keymap.set("n", "zgh", function()
    vim.cmd("DiffviewFileHistory")
end, { desc = "Git repository history" })
-- ============================================================
-- Gitsigns
-- ============================================================

require("gitsigns").setup({
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
    },

    update_debounce = 100,
    status_formatter = nil,
})


-- ============================================================
-- LeetCode
-- ============================================================

require("leetcode").setup({
    lang = "python3",
    image_support = true,

    hooks = {
        enter = {
            function()
                vim.g.leetcode_active = true
                close_oil_sidebar()
            end,
        },
        leave = {
            function()
                vim.g.leetcode_active = false
                vim.schedule(function()
                    open_oil_sidebar({ focus = false })
                end)
            end,
        },
    },

    storage = {
        home = "~/Documents/Github/Leetcode",
        cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
})



-- ============================================================
-- Misc Plugin Setup
-- ============================================================

require("ssh_launcher").setup()
require("rip-substitute").setup({
    popupWin = {
        border = "rounded",
        title = " Replace ",
        position = "bottom",
    },
})

local quicker = require("quicker")
quicker.setup({
    edit = {
        enabled = true,
        autosave = "unmodified",
    },
    keys = {
        {
            ">",
            function()
                quicker.expand({ before = 2, after = 2, add_to_existing = true })
            end,
            desc = "Expand quickfix context",
        },
        {
            "<",
            function() quicker.collapse() end,
            desc = "Collapse quickfix context",
        },
    },
    on_qf = function(buf)
        vim.keymap.set("n", "q", quicker.toggle, {
            buffer = buf,
            silent = true,
            desc = "Close editable results",
        })
        vim.keymap.set("n", "<C-c>", quicker.toggle, {
            buffer = buf,
            silent = true,
            desc = "Close editable results",
        })
    end,
})

local function open_project_results(query)
    query = vim.trim(query or "")
    if query == "" then return end

    local root = require("workspace").get()
    vim.system({
        "rg",
        "--vimgrep",
        "--smart-case",
        "--hidden",
        "--glob",
        "!.git",
        query,
        ".",
    }, { cwd = root, text = true }, function(result)
        vim.schedule(function()
            if result.code == 1 then
                vim.notify("No matches for: " .. query, vim.log.levels.INFO)
                return
            end
            if result.code ~= 0 then
                local message = vim.trim(result.stderr or "")
                vim.notify(message ~= "" and message or "Project search failed", vim.log.levels.ERROR)
                return
            end

            vim.fn.setqflist({}, "r", {
                title = "Search: " .. query,
                lines = vim.split(result.stdout or "", "\n", { trimempty = true }),
                efm = "%f:%l:%c:%m",
            })
            if quicker.is_open() then
                quicker.refresh()
                local results_win = find_window("qf")
                if results_win then vim.api.nvim_set_current_win(results_win) end
            else
                quicker.open({ focus = true })
            end
        end)
    end)
end

vim.api.nvim_create_user_command("ProjectResults", function(opts)
    if opts.args ~= "" then
        open_project_results(opts.args)
        return
    end
    vim.ui.input({
        prompt = "Project search: ",
        default = vim.fn.expand("<cword>"),
    }, open_project_results)
end, {
    nargs = "*",
    desc = "Search the workspace into an editable quickfix buffer",
})

vim.keymap.set({ "n", "x" }, "<leader>s", function()
    require("rip-substitute").sub()
end, { desc = "Replace in buffer or selection" })

vim.keymap.set("n", "<leader>sq", "<cmd>ProjectResults<CR>", {
    silent = true,
    desc = "Search project into editable results",
})

vim.keymap.set("n", "<leader>st", quicker.toggle, {
    silent = true,
    desc = "Toggle editable results",
})
