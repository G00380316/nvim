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
        require("editor_filler").open({ win = win })
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

local function protect_terminal_tab_before_close()
    local current = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(current).relative ~= "" then return end

    local normal_windows = vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
    if #normal_windows > 1 then return end

    -- Floaterm closes its own window while its buffer/job is being deleted.
    -- If that is the tab's sole window, Neovim closes the whole tab (and the
    -- last tab can look like, or become, an application quit). Give it an
    -- editor landing window first so Ctrl-Q can only remove the terminal.
    vim.cmd("aboveleft new")
    require("editor_filler").open({ win = vim.api.nvim_get_current_win() })
end

local function close_current()
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local filetype = vim.bo[buf].filetype
    local mode = vim.fn.mode()

    -- Leave modal editing states before changing buffers or windows.
    if mode == "t" then
        vim.cmd("stopinsert")
    elseif mode == "i" then
        vim.cmd("stopinsert")
    elseif mode:match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end

    -- Closing the dashboard used to call :qa. It is now a permanent safe
    -- landing buffer, so a close key can never terminate the Neovim process.
    if filetype == "snacks_dashboard" then
        vim.notify("Nothing to close — use :q, :qa, or :qa! to exit Neovim", vim.log.levels.INFO)
        return
    end

    -- Floating tool windows can always be dismissed without affecting the
    -- application process.
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

    -- Plugin-specific exits restore their replaced editor buffer correctly.
    local in_diffview = false
    pcall(function()
        in_diffview = require("diffview.lib").get_current_view() ~= nil
    end)
    if in_diffview or vim.b[buf].lazygit_editor then
        vim.cmd("GitCloseAll")
        return
    end

    if vim.g.leetcode_active == true then
        pcall(vim.cmd, "Leet exit")
        return
    end

    if buftype == "terminal" then
        protect_terminal_tab_before_close()
        local job_id = vim.b[buf].terminal_job_id
        if job_id then pcall(vim.fn.jobstop, job_id) end
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    elseif buftype == "quickfix" then
        pcall(vim.cmd, "cclose")
    elseif filetype == "oil" then
        pcall(vim.cmd, "close")
    elseif buftype ~= "" then
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
            pcall(vim.cmd, "confirm close")
        else
            close_editor_buffer(buf)
        end
    else
        local editor_windows = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local win_buf = vim.api.nvim_win_get_buf(win)
            local config = vim.api.nvim_win_get_config(win)
            if config.relative == ""
                and vim.bo[win_buf].buftype == ""
                and vim.bo[win_buf].filetype ~= "oil"
            then
                editor_windows = editor_windows + 1
            end
        end

        -- In a split, close the pane first and keep its buffer available. In
        -- the final editor pane, close the buffer and reveal a replacement.
        if editor_windows > 1 then
            local ok = pcall(vim.cmd, "confirm close")
            if not ok then return end
        elseif not close_editor_buffer(buf) then
            return
        end
    end

    -- Rebalance the remaining layout after a successful close.
    vim.schedule(function()
        pcall(vim.cmd, "wincmd =")
        pcall(vim.cmd, "LayoutEnforce")
    end)
end

-- ============================================================
-- CONSISTENT SPLIT LAYOUTS
-- Keep horizontal/vertical splits evenly sized.
-- ============================================================

local function equalize_splits()
    vim.cmd("wincmd =")
    -- `wincmd =` redistributes width across every window, so the fixed-width
    -- explorer has to be re-asserted immediately afterwards.
    pcall(vim.cmd, "LayoutEnforce")
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
    require("workflow_keymaps").open()
end, {
    desc = "My Neovim workflow keymaps",
})

vim.keymap.set("n", "<leader>K", function()
    Snacks.picker.keymaps()
end, {
    desc = "Search every active keymap",
})

vim.keymap.set({ "n", "i", "x", "t" }, "<C-\\>", function()
    require("workflow_keymaps").open()
end, {
    noremap = true,
    silent = true,
    desc = "Open my Neovim commands from any mode",
})

vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    Snacks.picker.buffers({
        sort_mru = true,
        current = true,
        filter = {
            filter = function(item)
                return require("buffers").belongs_to_workspace(item.buf)
            end,
        },
    })
end, {
    desc = "Choose buffer",
})

vim.keymap.set("n", "/", function()
    Snacks.picker.lines({
        layout = {
            preview = false,
        },
    })
end, {
    desc = "Find in current buffer",
})


-- ============================================================
-- Project / Directory Navigation
-- ============================================================

local function choose_workspace_folder()
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
end

vim.keymap.set("n", "<leader>w", choose_workspace_folder, {
    desc = "Choose folder as workspace",
})

vim.keymap.set("n", "<leader>f", function()
    Snacks.picker.files({ cwd = vim.fn.expand("~/") })
end, {
    desc = "Find user files",
})

local function open_project_switcher()
    local workspace = require("workspace")
    local current = workspace.get()
    local items = {}

    for _, path in ipairs(workspace.recent(20)) do
        local name = vim.fs.basename(path)
        local is_current = path == current
        local is_open = workspace.is_open(path)
        items[#items + 1] = {
            text = table.concat({ name, path, is_current and "current" or is_open and "open" or "" }, " "),
            name = name,
            file = path,
            current = is_current,
            open = is_open,
        }
    end

    items[#items + 1] = {
        text = "browse another folder workspace",
        name = "Browse for another folder…",
        browse = true,
    }

    Snacks.picker.pick({
        title = "Switch Project  ·  live contexts stay open",
        items = items,
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            if item.browse then
                return {
                    { "󰉋  ", "Directory" },
                    { item.name, "SnacksPickerLabel" },
                }
            end

            local status = item.current and "CURRENT" or item.open and "OPEN   " or "       "
            return {
                { status, item.current and "DiagnosticOk" or item.open and "DiagnosticInfo" or "Comment" },
                { "  " },
                { Snacks.picker.util.align(item.name, 24), "SnacksPickerFile" },
                { "  " },
                { vim.fn.fnamemodify(item.file, ":~"), "SnacksPickerDir" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            vim.schedule(function()
                if item.browse then
                    choose_workspace_folder()
                elseif not item.current then
                    workspace.open(item.file, { exact = true })
                end
            end)
        end,
    })
end

vim.keymap.set("n", "<leader>p", open_project_switcher, {
    desc = "Switch live project context",
})

vim.keymap.set("n", "<C-o>", open_project_switcher, {
    desc = "Switch live project context",
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

local function close_nonterminal()
    if vim.bo.buftype == "terminal" then
        vim.notify("Use Ctrl-Q to close terminals", vim.log.levels.INFO)
        return
    end
    close_current()
end

local function close_terminal()
    if vim.bo.buftype ~= "terminal" then
        vim.notify("Ctrl-Q closes terminals; use Ctrl-C here", vim.log.levels.INFO)
        return
    end
    close_current()
end

vim.keymap.set({ "n", "v", "i" }, "<C-c>", close_nonterminal, {
    noremap = true,
    silent = true,
    desc = "Close non-terminal buffer or pane (never exit Neovim)",
})

vim.keymap.set({ "n", "v", "t" }, "<C-q>", close_terminal, {
    noremap = true,
    silent = true,
    desc = "Close terminal (never exit Neovim)",
})

-- Ctrl-C owns non-terminal closing and Ctrl-Q owns terminal closing. These
-- built-in normal-mode shortcuts can close
-- panes or the application, so leave exiting to explicit :q/:qa/:qa! commands.
for _, lhs in ipairs({ "<C-w>q", "<C-w>c", "ZZ", "ZQ" }) do
    vim.keymap.set("n", lhs, "<Nop>", {
        silent = true,
        desc = "Disabled: use Ctrl-C (Ctrl-Q in terminals) to close",
    })
end

-- Runtime ftplugins commonly add q/Esc/C-q shortcuts that silently run
-- :quit, :bdelete, or a close action. Neutralize only those close-like local
-- mappings; editing/navigation meanings are left alone, and terminal programs
-- keep ownership of their own keys.
local function enforce_close_key_contract(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype == "terminal" then return end

    vim.api.nvim_buf_call(buf, function()
        for _, mode in ipairs({ "n", "i" }) do
            for _, lhs in ipairs({ "q", "<Esc>", "<C-q>" }) do
                local map = vim.fn.maparg(lhs, mode, false, true)
                if map.buffer == 1 then
                    local meaning = ((map.desc or "") .. " " .. (map.rhs or "")):lower()
                    local closes = meaning:find("close", 1, true)
                        or meaning:find("quit", 1, true)
                        or meaning:find("cancel", 1, true)
                        or meaning:find("bdelete", 1, true)
                        or meaning:find("<cmd>bd", 1, true)
                    if closes and map.rhs ~= "<Nop>" then
                        vim.keymap.set(mode, lhs, "<Nop>", {
                            buffer = buf,
                            silent = true,
                            desc = "Disabled: use Ctrl-C to close",
                        })
                    end
                end
            end
        end
    end)
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("UniversalCloseKeys", { clear = true }),
    callback = function(args)
        vim.schedule(function() enforce_close_key_contract(args.buf) end)
    end,
    desc = "Reserve Ctrl-C for buffers and panes and Ctrl-Q for terminals",
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
    desc = "Browse and yank terminal output with normal motions",
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
    vim.cmd("edit " .. vim.fn.fnameescape(notes))
end, {
    noremap = true,
    silent = true,
    desc = "Open quick notes in this Neovim instance",
})

-- ============================================================
-- Flash Search
-- ============================================================

-- flash.nvim locates the end of a match by reading Neovim's internal
-- `search_match_lines` / `search_match_endcol` C globals over LuaJIT FFI.
-- Neovim nightly no longer exports either symbol, so every `s` jump died with
-- "symbol not found" before a single match could be collected. Upstream has no
-- fix (checked against origin/main), so re-derive the end position with an
-- ordinary `ce` search, which needs no internals at all.
local function patch_flash_ffi()
    local exported = pcall(function()
        local ffi = require("ffi")
        ffi.cdef([[unsigned int search_match_lines;]])
        return ffi.C.search_match_lines
    end)
    if exported then return end

    local ok, Search = pcall(require, "flash.search")
    if not ok then return end
    local Pos = require("flash.search.pos")

    function Search:_next(flags)
        flags = flags or ""
        local pattern = self.state.pattern.search
        local found, pos = pcall(vim.fn.searchpos, pattern, flags)
        if not found or pos[1] == 0 then return end

        local start = Pos({ pos[1], pos[2] - 1 })
        -- "ce" lands on the final character of the match just matched; "n"
        -- keeps the cursor put so the caller's own iteration is unaffected.
        local ok_end, epos = pcall(vim.fn.searchpos, pattern, "ceWn")
        local finish = (ok_end and epos[1] ~= 0) and Pos({ epos[1], epos[2] - 1 }) or start

        return { win = self.win, pos = start, end_pos = finish }
    end
end

pcall(patch_flash_ffi)

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
