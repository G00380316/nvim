-- ============================================================
-- Core Requires
-- ============================================================

local Snacks = require("snacks")


-- ============================================================
-- State
-- ============================================================

local sticky_active = false
local sticky_word = nil

-- ============================================================
-- General Helpers
-- ============================================================

local function has_lsp(bufnr)
    bufnr = bufnr or 0
    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
end

local function clear_search()
    vim.fn.setreg("/", "")
    vim.cmd("nohlsearch")

    sticky_active = false
    sticky_word = nil
end

local function open_in_file_manager()
    local file = vim.api.nvim_buf_get_name(0)

    if file == "" then
        print("No file associated with this buffer")
        return
    end

    local dir = vim.fn.fnamemodify(file, ":h")

    if vim.fn.has("mac") == 1 then
        vim.fn.jobstart({ "open", dir }, { detach = true })
    elseif vim.fn.has("win32") == 1 then
        vim.fn.jobstart({ "explorer", dir }, { detach = true })
    else
        vim.fn.jobstart({ "xdg-open", dir }, { detach = true })
    end
end


-- ============================================================
-- Sticky Search Helpers
-- n / N searches current word, but jumps pairs if on brackets/quotes.
-- ============================================================

local function build_search_pattern(word)
    local escaped = vim.fn.escape(word, "\\")
    return "\\c\\<" .. escaped .. "\\>"
end

local function jump_quote(direction, quote)
    local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.fn.getline(row)
    local col = col0 + 1

    if direction == "n" then
        local found = line:find(quote, col + 1, true)
        if found then
            vim.api.nvim_win_set_cursor(0, { row, found - 1 })
            return true
        end
    else
        local before = line:sub(1, col - 1)
        local last_pos = nil
        local start = 1

        while true do
            local found = before:find(quote, start, true)
            if not found then
                break
            end

            last_pos = found
            start = found + 1
        end

        if last_pos then
            vim.api.nvim_win_set_cursor(0, { row, last_pos - 1 })
            return true
        end
    end

    return false
end

local function visual_pair_jump(direction)
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    -- Brackets
    if char:match("[%(%)%[%]%{%}]") then
        vim.cmd("normal! %")
        return true
    end

    -- Quotes
    if char == '"' or char == "'" then
        return jump_quote(direction, char)
    end

    return false
end

local function smart_search_and_jump(direction)
    local mode = vim.fn.mode()
    local is_visual = mode:match("[vV\22]") ~= nil

    -- In visual mode, only jump pairs.
    -- Do not restore old visual selection with gv.
    if is_visual then
        visual_pair_jump(direction)
        return
    end

    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    if char:match("[%(%)%[%]%{%}]") then
        pcall(vim.cmd, "normal! %")
        return
    end

    if char == '"' or char == "'" then
        if jump_quote(direction, char) then
            return
        end
    end

    -- Sticky search fallback
    if not sticky_active then
        local word = vim.fn.expand("<cword>")
        if word == "" then
            print("No word under cursor to search")
            return
        end

        sticky_word = word
        sticky_active = true
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    if vim.fn.getreg("/") == "" then
        print("No active search pattern")
        return
    end

    pcall(vim.cmd, "normal! " .. direction)
end

-- ============================================================
-- Safe Paste Helpers
-- Keeps linewise pastes separated from surrounding text.
-- ============================================================

local function regtype_is_linewise(reg)
    local regtype = vim.fn.getregtype(reg or '"')
    return regtype:sub(1, 1) == "V"
end

local function line_is_blank(lnum)
    if lnum < 1 or lnum > vim.fn.line("$") then
        return true
    end

    return vim.fn.getline(lnum):match("^%s*$") ~= nil
end

local function ensure_blank_line_above(lnum)
    if lnum > 1 and not line_is_blank(lnum - 1) then
        vim.fn.append(lnum - 1, "")
    end
end

local function ensure_blank_line_below(lnum)
    if lnum < vim.fn.line("$") and not line_is_blank(lnum + 1) then
        vim.fn.append(lnum, "")
    end
end

local function safe_paste(direction)
    local mode = vim.fn.mode()
    local is_visual = mode:match("[vV\22]") ~= nil

    -- Exit visual mode AFTER capturing it
    if is_visual then
        vim.cmd("normal! \27")
    end

    local reg = vim.v.register
    if reg == "" then
        reg = '"'
    end

    -- =========================
    -- VISUAL MODE (replacement)
    -- =========================
    if is_visual then
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")

        -- Grab yanked content BEFORE any deletion
        local yanked = vim.fn.getreg('0')
        local regtype = vim.fn.getregtype('0')

        ensure_blank_line_above(start_line)
        ensure_blank_line_below(end_line)

        -- Delete selection, restore register, paste
        vim.cmd('normal! gv"_d')
        vim.fn.setreg('"', yanked, regtype)
        vim.cmd('normal! P')

        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
        return
    end

    -- Character-wise paste in normal mode → leave untouched
    if not regtype_is_linewise(reg) then
        vim.cmd("normal! " .. direction)
        return
    end

    -- =========================
    -- NORMAL MODE
    -- =========================
    local current_line = vim.fn.line(".")
    if direction == "p" then
        ensure_blank_line_below(current_line)
        vim.cmd("normal! p")
        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
    else
        ensure_blank_line_above(current_line)
        vim.cmd("normal! P")
        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
    end
end
-- ============================================================
-- Save / Quit Helpers
-- ============================================================

local function save_current_file()
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode

    -- Leave insert/visual mode cleanly.
    if mode:sub(1, 1) == "i" then
        vim.cmd("stopinsert")
    elseif mode:sub(1, 1) == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "nx",
            false
        )
    end

    local function write_buffer()
        if vim.bo[bufnr].filetype ~= "oil" and has_lsp(bufnr) then
            pcall(vim.lsp.buf.format, { async = false })
        end

        local ok, err = pcall(vim.cmd, "write")
        if not ok then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        clear_search()
    end

    local name = vim.api.nvim_buf_get_name(bufnr)

    -- Save unnamed buffer by asking for a path.
    if name == "" then
        local cwd = vim.fn.getcwd()
        local default_path = cwd .. "/"

        local ok, filepath = pcall(vim.fn.input, "Save as: ", default_path, "file")
        if not ok or not filepath or filepath == "" then
            return
        end

        filepath = vim.fn.fnamemodify(filepath, ":p")

        local dir = vim.fn.fnamemodify(filepath, ":h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end

        local save_ok, save_err = pcall(vim.cmd, "saveas " .. vim.fn.fnameescape(filepath))
        if not save_ok then
            vim.notify(save_err, vim.log.levels.ERROR)
            return
        end

        clear_search()
        return
    end

    write_buffer()
end

local function next_editor_buffer(current)
    return require("buffers").replacement(current)
end

local function close_editor_buffer(buf)
    local win = vim.api.nvim_get_current_win()
    local replacement = next_editor_buffer(buf)

    -- Keep the editor zone alive between the fixed tree and terminal panels.
    -- :bdelete on the displayed buffer would otherwise remove its window.
    if replacement then
        vim.api.nvim_win_set_buf(win, replacement)
    else
        require("dashboard").open({ win = win })
    end

    local success = pcall(vim.cmd, "confirm bdelete " .. buf)
    if not success or (vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted) then
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_win_set_buf(win, buf)
        end
        return false
    end
    return true
end

local function quit()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local modified = vim.bo[buf].modified
    local buftype = vim.bo[buf].buftype
    local mode = vim.fn.mode()

    -- 1. Exit terminal mode cleanly first
    if mode == "t" then
        vim.cmd("stopinsert")
    elseif mode == "i" then
        vim.cmd("stopinsert")
    end

    -- 2. Handle floating windows
    local win_config = vim.api.nvim_win_get_config(0)
    if win_config.relative ~= "" then
        if buftype == "terminal" then
            local job_id = vim.b[buf].terminal_job_id

            -- Kill terminal job directly instead of sending "exit"
            if job_id then
                pcall(vim.fn.jobstop, job_id)
            end

            pcall(vim.cmd, "bd!")
        else
            -- Oil help, Lazy, popup windows, etc.
            pcall(vim.cmd, "close")
        end

        return
    end

    -- 3. Plugin-specific exits
    local in_diffview = false
    pcall(function()
        in_diffview = require("diffview.lib").get_current_view() ~= nil
    end)
    if in_diffview or vim.b[buf].lazygit_editor then
        vim.cmd("GitCloseAll")
        return
    end

    if pcall(vim.cmd, "Leet exit") then
        return
    end

    -- 4. Empty starter buffer -> quit nvim
    if name == "" and not modified and buftype == "" then
        pcall(vim.cmd, "qa")
        return
    end

    -- 5. Standard close logic
    local wins = vim.fn.win_findbuf(buf)

    if #wins > 1 then
        pcall(vim.cmd, "close")
    else
        if buftype == "terminal" then
            local job_id = vim.b[buf].terminal_job_id

            if job_id then
                pcall(vim.fn.jobstop, job_id)
            end

            pcall(vim.cmd, "bd!")
        elseif vim.bo[buf].filetype == "oil" then
            pcall(vim.cmd, "close")
        else
            if not close_editor_buffer(buf) then
                return
            end
        end
    end

    -- 6. Rebalance layout
    vim.schedule(function()
        pcall(vim.cmd, "wincmd =")
    end)
end

-- ============================================================
-- CONSISTENT SPLIT LAYOUTS
-- Keep horizontal/vertical splits evenly sized.
-- ============================================================

local function equalize_splits()
    vim.cmd("wincmd =")
end

vim.api.nvim_create_autocmd({
    "VimResized",
    "WinNew",
    "WinClosed",
    "BufWinEnter",
}, {
    group = vim.api.nvim_create_augroup("ConsistentSplitLayout", { clear = true }),
    callback = function()
        vim.schedule(equalize_splits)
    end,
    desc = "Keep split layouts consistent",
})

-- ============================================================
-- Render Markdown
-- ============================================================

require("render-markdown").setup({
    opts = {
        heading = {
            width = "block",
            min_width = 50,
            border = true,
            backgrounds = {
                "RenderMarkdownH1Bg",
                "RenderMarkdownH2Bg",
                "RenderMarkdownH3Bg",
                "RenderMarkdownH4Bg",
                "RenderMarkdownH5Bg",
                "RenderMarkdownH6Bg",
            },
            foregrounds = {
                "RenderMarkdownH1",
                "RenderMarkdownH2",
                "RenderMarkdownH3",
                "RenderMarkdownH4",
                "RenderMarkdownH5",
                "RenderMarkdownH6",
            },
        },
        render_modes = { "n", "v", "i", "c" },
        checkbox = {
            unchecked = { icon = "󰄱 " },
            checked = { icon = " " },
            custom = {
                todo = {
                    raw = "[>]",
                    rendered = "󰥔 ",
                },
            },
        },
        code = {
            position = "right",
            width = "block",
            left_pad = 2,
            right_pad = 4,
        },
    },
})


-- ============================================================
-- Basic Movement / Editing
-- ============================================================

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll half-page up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll half-page down and center" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<BS>", "ge", {
    noremap = true,
    silent = true,
    desc = "Go to previous end of word",
})

vim.keymap.set({ "v", "x" }, "<", "<gv", {
    noremap = true,
    silent = true,
    desc = "Outdent and keep selection",
})

vim.keymap.set({ "v", "x" }, ">", ">gv", {
    noremap = true,
    silent = true,
    desc = "Indent and keep selection",
})

vim.keymap.set("x", "J", ":move '>+1<CR>gv=gv", {
    noremap = true,
    silent = true,
    desc = "Move selection down",
})

vim.keymap.set("x", "K", ":move '<-2<CR>gv=gv", {
    noremap = true,
    silent = true,
    desc = "Move selection up",
})


-- ============================================================
-- Clipboard / Delete / Paste
-- ============================================================

vim.keymap.set({ "n", "v" }, "y", '"+y', {
    noremap = true,
    silent = true,
    desc = "Yank to system clipboard",
})

vim.keymap.set("n", "Y", '"+Y', {
    noremap = true,
    silent = true,
    desc = "Yank line to system clipboard",
})

vim.keymap.set({ "n", "v" }, "d", '"_d', {
    noremap = true,
    silent = true,
    desc = "Delete without clipboard",
})

vim.keymap.set("n", "D", '"_D', {
    noremap = true,
    silent = true,
    desc = "Delete line without clipboard",
})

vim.keymap.set({ "n", "v" }, "c", '"_c', {
    noremap = true,
    silent = true,
    desc = "Change without clipboard",
})

vim.keymap.set("n", "C", '"_C', {
    noremap = true,
    silent = true,
    desc = "Change line without clipboard",
})

vim.keymap.set("n", "S", '"_S', {
    noremap = true,
    silent = true,
    desc = "Substitute line without clipboard",
})

vim.keymap.set("n", "x", '"_x', {
    noremap = true,
    silent = true,
    desc = "Delete char without clipboard",
})

vim.keymap.set("n", "X", '"_X', {
    noremap = true,
    silent = true,
    desc = "Delete previous char without clipboard",
})

vim.keymap.set("n", "p", function()
    safe_paste("p")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste below",
})

vim.keymap.set("n", "P", function()
    safe_paste("P")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste above",
})

vim.keymap.set("x", "p", function()
    safe_paste("p")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste replacement",
})

-- Usually P in visual mode is the same as p, but we'll keep it consistent
vim.keymap.set("x", "P", function()
    safe_paste("P")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste replacement",
})

-- ============================================================
-- Editor Buffer Navigation
-- ============================================================

local function cycle_editor_buffer(direction)
    require("buffers").cycle(direction)
end

vim.keymap.set("n", "<C-]>", function() cycle_editor_buffer(1) end, {
    silent = true,
    desc = "Next editor buffer",
})

vim.keymap.set("n", "<C-[>", function() cycle_editor_buffer(-1) end, {
    silent = true,
    desc = "Previous editor buffer",
})

vim.keymap.set("n", "<Tab>", function() cycle_editor_buffer(1) end, {
    silent = true,
    desc = "Next editor buffer",
})

vim.keymap.set("n", "<S-Tab>", function() cycle_editor_buffer(-1) end, {
    silent = true,
    desc = "Previous editor buffer",
})

-- ============================================================
-- Editor Splits / Pane Sizing
-- ============================================================

local function focus_editor_pane()
    pcall(vim.cmd, "EditorFocus")
end

local function split_editor(command)
    focus_editor_pane()
    vim.cmd(command)
end

local function resize_editor(command)
    focus_editor_pane()
    vim.cmd(command)
end

vim.api.nvim_create_user_command("EditorSplitVertical", function()
    split_editor("vsplit")
end, { desc = "Split the current editor buffer vertically" })

vim.api.nvim_create_user_command("EditorSplitHorizontal", function()
    split_editor("split")
end, { desc = "Split the current editor buffer horizontally" })

vim.api.nvim_create_user_command("EditorPaneWider", function()
    resize_editor("vertical resize +5")
end, { desc = "Grow the editor pane horizontally" })

vim.api.nvim_create_user_command("EditorPaneNarrower", function()
    resize_editor("vertical resize -5")
end, { desc = "Shrink the editor pane horizontally" })

vim.api.nvim_create_user_command("EditorPaneTaller", function()
    resize_editor("resize +3")
end, { desc = "Grow the editor pane vertically" })

vim.api.nvim_create_user_command("EditorPaneShorter", function()
    resize_editor("resize -3")
end, { desc = "Shrink the editor pane vertically" })

vim.api.nvim_create_user_command("EditorPanesEqual", function()
    focus_editor_pane()
    vim.cmd("wincmd =")
end, { desc = "Equalize editor panes" })

vim.keymap.set("n", "zv", "<cmd>EditorSplitVertical<CR>", {
    silent = true,
    desc = "Vertical editor split",
})

vim.keymap.set("n", "zh", "<cmd>EditorSplitHorizontal<CR>", {
    silent = true,
    desc = "Horizontal editor split",
})

vim.keymap.set("n", "z=", "<cmd>EditorPanesEqual<CR>", {
    silent = true,
    desc = "Equalize editor panes",
})

vim.keymap.set("n", "<C-Right>", "<cmd>EditorPaneWider<CR>", {
    silent = true,
    desc = "Grow editor pane right",
})

vim.keymap.set("n", "<C-Left>", "<cmd>EditorPaneNarrower<CR>", {
    silent = true,
    desc = "Shrink editor pane from right",
})

vim.keymap.set("n", "<C-Up>", "<cmd>EditorPaneTaller<CR>", {
    silent = true,
    desc = "Grow editor pane upward",
})

vim.keymap.set("n", "<C-Down>", "<cmd>EditorPaneShorter<CR>", {
    silent = true,
    desc = "Shrink editor pane vertically",
})

-- ============================================================
-- Search / Replace
-- ============================================================

vim.keymap.set("n", "<leader>c", clear_search, {
    desc = "Clear search highlight and pattern",
})

vim.keymap.set({ "n", "x" }, "n", function()
    smart_search_and_jump("n")
end, {
    desc = "Sticky search next / matching pair",
})

vim.keymap.set({ "n", "x" }, "N", function()
    smart_search_and_jump("N")
end, {
    desc = "Sticky search previous / matching pair",
})

vim.keymap.set("n", "<leader>r", "*Ncgn", {
    noremap = true,
    silent = true,
    desc = "Start interactive replace for word",
})

vim.keymap.set({ "n", "i" }, "<C-.>", function()
    local function do_repeat()
        vim.api.nvim_feedkeys(".", "n", false)
    end

    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>n", true, false, true),
            "n",
            false
        )
        vim.defer_fn(do_repeat, 30)
    else
        vim.api.nvim_feedkeys("n", "n", false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace current match and find next",
})

vim.keymap.set({ "n", "i" }, "<C-,>", function()
    local function do_repeat()
        vim.api.nvim_feedkeys(".", "n", false)
    end

    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>N", true, false, true),
            "n",
            false
        )
        vim.defer_fn(do_repeat, 30)
    else
        vim.api.nvim_feedkeys("N", "n", false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace previous match",
})


-- ============================================================
-- LSP navigation (Snacks is the single picker backend)
-- ============================================================

vim.keymap.set("n", "gd", function()
    Snacks.picker.lsp_definitions()
end, {
    desc = "LSP definitions",
})

vim.keymap.set("n", "gr", function()
    Snacks.picker.lsp_references()
end, {
    desc = "LSP references",
})

vim.keymap.set("n", "gi", function()
    Snacks.picker.lsp_implementations()
end, {
    desc = "LSP implementations",
})

vim.keymap.set("n", "<leader>dd", function()
    Snacks.picker.diagnostics_buffer()
end, {
    desc = "Diagnostics current buffer",
})

vim.keymap.set("n", "<leader>dw", function()
    Snacks.picker.diagnostics({ cwd = require("workspace").get() })
end, {
    desc = "Diagnostics workspace",
})


-- ============================================================
-- Snacks Pickers
-- ============================================================

vim.keymap.set({ "n", "v", "i" }, "<C-f>", function()
    Snacks.picker.files({ cwd = require("workspace").get() })
end, {
    desc = "Find files",
})

vim.keymap.set({ "n", "v", "i" }, "<C-g>", function()
    Snacks.picker.grep({ cwd = require("workspace").get() })
end, {
    desc = "Grep",
})

vim.keymap.set("n", "<leader>h", function()
    Snacks.picker.help()
end, {
    desc = "Help picker",
})

vim.keymap.set("n", "zcf", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, {
    desc = "Find config files",
})

vim.keymap.set({ "n", "x" }, "<leader>l", function()
    Snacks.picker.grep_word({ cwd = require("workspace").get() })
end, {
    desc = "Grep word or visual selection",
})

vim.keymap.set("n", "<leader>k", function()
    Snacks.picker.keymaps()
end, {
    desc = "Search keymaps",
})

vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    Snacks.picker.buffers({
        sort_mru = true,
        current = true,
    })
end, {
    desc = "Choose buffer",
})

vim.keymap.set("n", "/", function()
    Snacks.picker.lines({
        layout = {
            preview = false,
        },
        win = {
            input = {
                keys = {
                    ["<C-c>"] = { "close", mode = { "n", "i" } },
                },
            },
        },
    })
end, {
    desc = "Find in current buffer",
})


-- ============================================================
-- Project / Directory Navigation
-- ============================================================

vim.keymap.set("n", "<leader>w", function()
    Snacks.picker.explorer({
        title = "Choose Folder as Workspace  ·  l expand  ·  Enter choose",
        cwd = vim.fn.expand("~/"),
        hidden = true,
        ignored = true,
        follow_file = false,
        auto_close = true,
        layout = { preset = "vertical", preview = false },
        actions = {
            choose_workspace = function(picker, item)
                if not item or not item.file then return end

                local path = vim.fs.normalize(item.file)
                if vim.fn.isdirectory(path) == 0 then
                    path = vim.fn.fnamemodify(path, ":h")
                end

                picker:close()
                vim.schedule(function()
                    require("workspace").open(path, { exact = true })
                end)
            end,
        },
        win = {
            list = {
                keys = {
                    ["<CR>"] = "choose_workspace",
                },
            },
        },
    })
end, {
    desc = "Choose folder as workspace",
})

vim.keymap.set("n", "<leader>f", function()
    Snacks.picker.files({ cwd = vim.fn.expand("~/") })
end, {
    desc = "Find user files",
})

vim.keymap.set("n", "<C-o>", function()
    local dev = {}
    for _, path in ipairs({
        "~/Documents/Github",
        "~/Library/Mobile Documents/com~apple~CloudDocs",
        "~/dev",
        "~/projects",
    }) do
        path = vim.fn.expand(path)
        if vim.fn.isdirectory(path) == 1 then
            dev[#dev + 1] = path
        end
    end

    Snacks.picker.projects({
        title = "Open Workspace",
        dev = dev,
        projects = { require("workspace").get() },
        recent = true,
        max_depth = 3,
        patterns = {
            ".git",
            ".hg",
            ".project",
            "package.json",
            "pyproject.toml",
            "Cargo.toml",
            "go.mod",
            "Makefile",
        },
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function()
                require("workspace").open(item.file, { exact = true })
            end)
        end,
    })
end, {
    desc = "Open workspace",
})

vim.keymap.set("n", "go", open_in_file_manager, {
    noremap = true,
    silent = true,
    desc = "Open current folder in Finder/Explorer",
})

vim.keymap.set("n", "gx", function()
    local raw = vim.fn.expand("<cWORD>")
    local target = vim.fn.fnamemodify(vim.fn.expand(raw), ":p")

    if raw:match("^https?://") then
        vim.system({ "open", raw })
    elseif target:match("^https?://") then
        vim.system({ "open", target })
    elseif vim.fn.isdirectory(target) == 1 then
        vim.system({ "open", target })
    elseif vim.fn.filereadable(target) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(target))
    else
        print("Unknown target: " .. raw)
    end
end, {
    silent = true,
    desc = "Open links, files, and directories",
})


-- ============================================================
-- Save / Source / Quit / Set Working Dir
-- ============================================================

vim.keymap.set("n", "<leader>o", ":update<CR>:source<CR>", {
    desc = "Update and source current file",
})

vim.keymap.set({ "n", "i", "v" }, "<C-s>", save_current_file, {
    noremap = true,
    silent = true,
    desc = "Save",
})

vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", quit, {
    noremap = true,
    silent = true,
    desc = "Smart close / quit",
})

vim.keymap.set("n", "q", quit, {
    noremap = true,
    silent = true,
    desc = "Smart close / quit",
})

-- Deliberately change the workspace instead of creating a temporary cwd.
vim.keymap.set("n", "zcd", function()
    require("workspace").from_current_buffer()
end, { desc = "Use current file's project as workspace" })

-- ============================================================
-- Insert / Command / Terminal
-- ============================================================

vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", {
    noremap = true,
    desc = "Exit terminal mode",
})

vim.keymap.set("c", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-y>"
    end

    return "<CR>"
end, {
    expr = true,
})

vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        local info = vim.fn.complete_info({ "selected" })

        if info.selected == -1 then
            return vim.api.nvim_replace_termcodes("<C-n><C-y>", true, false, true)
        end

        return vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
    end

    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end, {
    expr = true,
})

vim.keymap.set("n", "<CR>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    if char == "" or char:match("%s") then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("w", true, false, true),
            "n",
            true
        )
    else
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('"_ciw', true, false, true),
            "n",
            true
        )
    end
end, {
    noremap = true,
    silent = true,
    desc = "Enter: move word or change inner word",
})


-- ============================================================
-- Quick Notes / Kitty
-- ============================================================

vim.keymap.set("n", "<leader>qn", function()
    local notes = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/quicknotes.md")

    if vim.fn.filereadable(notes) == 0 then
        vim.fn.writefile({}, notes)
    end

    pcall(vim.cmd, "EditorFocus")
    vim.cmd(
        "FloatermNew"
        .. " --height=0.85"
        .. " --width=0.85"
        .. " --title=QuickNotes"
        .. " --autoclose=2"
        .. " nvim "
        .. vim.fn.fnameescape(notes)
    )
end, {
    noremap = true,
    silent = true,
    desc = "Quick notes",
})

-- ============================================================
-- LeetCode
-- ============================================================

vim.keymap.set("n", "zlo", function()
    vim.fn.jobstart({
        "kitty",
        "@",
        "launch",
        "--cwd",
        vim.fn.getcwd(),
        "--type",
        "tab",
        "nvim",
        "+Leet",
    }, {
        detach = true,
    })
end, {
    noremap = true,
    silent = true,
    desc = "Open Leet in Kitty tab",
})

vim.keymap.set("n", "zlt", "<cmd>Leet Run<CR>", {
    noremap = true,
    silent = true,
    desc = "Test Leet solution",
})

vim.keymap.set("n", "zls", "<cmd>Leet Submit<CR>", {
    noremap = true,
    silent = true,
    desc = "Submit Leet solution",
})

vim.keymap.set("n", "zll", "<cmd>Leet List<CR>", {
    noremap = true,
    silent = true,
    desc = "List Leet problems",
})

vim.keymap.set("n", "zlr", "<cmd>Leet Reset<CR>", {
    noremap = true,
    silent = true,
    desc = "Reset Leet solution",
})


-- ============================================================
-- Flash Search
-- ============================================================

vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
-- vim.keymap.set({ "n" }, "sa", function()
--     require("flash").jump({
--         pattern = ".", -- initialize pattern with any char
--         search = {
--             mode = function(pattern)
--                 -- remove leading dot
--                 if pattern:sub(1, 1) == "." then
--                     pattern = pattern:sub(2)
--                 end
--                 -- return word pattern and proper skip pattern
--                 return ([[\<%s\w*\>]]):format(pattern), ([[\<%s]]):format(pattern)
--             end,
--         },
--         -- select the range
--         jump = { pos = "range" },
--     })
-- end, { desc = "Flash select any word" })
