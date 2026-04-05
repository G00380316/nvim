local last = vim.fn.line("'>")
vim.keymap.set("n", "q", "<nop>", { noremap = true, silent = true })
local max = vim.fn.line("$")
local Snacks = require("snacks")
-- A function to search for the word under the cursor and then jump
-- Sticky smart search state
local sticky_active = false
local sticky_word = nil
local case_sensitive = false

-- A function to clear search highlighting and the search pattern
local function clear_search()
    vim.fn.setreg('/', '')
    sticky_active = false
    sticky_word = nil

    -- vim.notify("Search cleared", vim.log.levels.INFO, { timeout = 1000 })
end

local function build_search_pattern(word)
    local escaped = vim.fn.escape(word, "\\")
    local prefix = case_sensitive and "" or "\\c"
    return prefix .. "\\<" .. escaped .. "\\>"
end

local function smart_search_and_jump(direction)
    -- If no sticky search is active, initialize it using <cword>
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

    -- Before jumping, make sure the search register is not empty
    local search_reg = vim.fn.getreg("/")
    if search_reg == "" then
        print("No active search pattern")
        return
    end

    -- Jump to next/previous match
    vim.cmd("normal! " .. direction)
end

local function has_lsp(bufnr)
    bufnr = bufnr or 0
    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
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


--- SPECIAL MAPPINGS ---

vim.keymap.set("n", "<C-u>", "<C-u>zz")     -- Scroll Half-Page and Center
vim.keymap.set("x", "J", function()
    vim.keymap.set("n", "<C-d>", "<C-d>zz") -- Scroll Half-Page and Center
    vim.keymap.set("n", "J", "mzJ`z")       -- Keep Cursor Position When Joining Lines

    if last >= max then
        return
    end
    vim.cmd("'<,'>move '>+1")
    vim.cmd("normal! gv")
end, { silent = true, desc = "Move selection down" })

vim.keymap.set("x", "K", function()
    local first = vim.fn.line("'<")
    if first <= 1 then
        return
    end
    vim.cmd("'<,'>move '<-2")
    vim.cmd("normal! gv")
end, { silent = true, desc = "Move selection up" })

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

vim.keymap.set("n", "gx", function()
    local raw = vim.fn.expand("<cWORD>")
    local target = vim.fn.fnamemodify(vim.fn.expand(raw), ":p")

    if target:match("^https?://") then
        vim.system({ "open", target })
    elseif vim.fn.isdirectory(target) == 1 then
        vim.system({ "open", target })
    elseif vim.fn.filereadable(target) == 1 then
        vim.cmd("edit " .. target)
    else
        print("Unknown target: " .. raw)
    end
end, { silent = true })

vim.keymap.set("n", "<BS>", "ge", { noremap = true, silent = true })

vim.keymap.set({ "v", "x" }, "<", "<gv", { noremap = true, silent = true }) -- Outdent selected block of text
-- yank to system clipboard
vim.keymap.set({ "n", "v" }, "y", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "Y", '"+Y', { noremap = true, silent = true })

-- delete/change without polluting clipboard
vim.keymap.set({ "n", "v" }, "d", '"_d', { noremap = true, silent = true })
vim.keymap.set("n", "D", '"_D', { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "c", '"_c', { noremap = true, silent = true })
vim.keymap.set("n", "C", '"_C', { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "s", '"_s', { noremap = true, silent = true })
vim.keymap.set("n", "S", '"_S', { noremap = true, silent = true })

vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true })
vim.keymap.set("n", "X", '"_X', { noremap = true, silent = true })

-- replace selection without overwriting clipboard
vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true })
vim.keymap.set("n", "<C-o>", "<nop>", { silent = true })
vim.keymap.set({ "n" }, "<C-]>", "<C-i>",
    { noremap = true, silent = true, desc = "Jump to the next position" })
vim.keymap.set({ "n" }, "<C-[>", "<C-o>",
    { noremap = true, silent = true, desc = "Jump to the prev position" })
vim.keymap.set("n", "<Tab>", "<cmd>bn<CR>", { noremap = true, silent = true, desc = "Next Buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bp<CR>", { noremap = true, silent = true, desc = "Previous Buffer" })

vim.keymap.set("n", "<leader>qn", function()
    local notes = vim.fn.expand("~/.quicknotes.txt")
    if vim.fn.filereadable(notes) == 0 then
        vim.fn.writefile({}, notes)
    end
    vim.cmd("FloatermNew --height=0.85 --width=0.85 --title=QuickNotes nvim " .. vim.fn.fnameescape(notes))
end, { noremap = true, silent = true, desc = "Quick Notes" })

vim.keymap.set("n", "zg", function()
    local cwd = vim.fn.getcwd()

    vim.fn.jobstart({
        "kitty", "@", "launch",
        "--cwd", cwd,
        "--type", "tab",
        "lazygit",
    }, { detach = true })
end, { desc = "Open Lazygit in Kitty tab" })

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
end, { noremap = true, silent = true, desc = "Enter: o or ciw" })

-- Go to definition
vim.keymap.set("n", "gd", function()
    require("fzf-lua").lsp_definitions()
end, { desc = "LSP Definitions (fzf-lua)" })

-- References
vim.keymap.set("n", "gr", function()
    require("fzf-lua").lsp_references()
end, { desc = "LSP References (fzf-lua)" })

-- Diagnostics (current buffer)
vim.keymap.set("n", "<leader>dd", function()
    require("fzf-lua").diagnostics_document()
end, { desc = "Diagnostics (current buffer)" })

-- Diagnostics (workspace)
vim.keymap.set("n", "<leader>dw", function()
    require("fzf-lua").diagnostics_workspace()
end, { desc = "Diagnostics (workspace)" })

-- Go to implementation
vim.keymap.set("n", "gi", function()
    require("fzf-lua").lsp_implementations()
end, {
    desc = "Go to implementation (fzf-lua)",
})

vim.keymap.set({ "n", "v", "i" }, "<C-f>", function() Snacks.picker.files() end, { desc = "File Lookup" })

vim.keymap.set({ "n", "v", "i" }, "<C-g>", function() Snacks.picker.grep() end, { desc = "Grep" })

vim.keymap.set("n", "<leader>h", function() Snacks.picker.help() end, { desc = "I need Help" })

vim.keymap.set("n", "zcf", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find Config Files" })

vim.keymap.set({ "n", "x" }, "<C-l>", function() Snacks.picker.grep_word() end,
    { desc = "Grep Visual selection or Word" })

vim.keymap.set("n", "<C-h>", function() Snacks.picker.keymaps() end, { desc = "Search Keymaps" })

vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    Snacks.picker.buffers({
        sort_mru = true,
        current = true,
    })
end, { desc = "Choose a buffer" })
vim.keymap.set({ "n" }, "/", function()
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
end, { desc = "Find in current buffer" })
vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true, desc = "Exit Terminal mode in Terminal" })
vim.keymap.set({ "c" }, "<CR>", function()
    if vim.fn.pumvisible() == 1 then return '<c-y>' end
    return '<cr>'
end, { expr = true })
vim.keymap.set({ "i" }, "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        local info = vim.fn.complete_info({ "selected" })

        -- Nothing selected → select first item
        if info.selected == -1 then
            return vim.api.nvim_replace_termcodes("<C-n><C-y>", true, false, true)
        end

        -- Item already selected
        return vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
    end

    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end, { expr = true })


require("render-markdown").setup({
    opts = {
        heading = {
            width = 'block',
            min_width = 50,
            border = true,
            backgrounds = {
                'RenderMarkdownH1Bg',
                'RenderMarkdownH2Bg',
                'RenderMarkdownH3Bg',
                'RenderMarkdownH4Bg',
                'RenderMarkdownH5Bg',
                'RenderMarkdownH6Bg',
            },
            foregrounds = {
                'RenderMarkdownH1',
                'RenderMarkdownH2',
                'RenderMarkdownH3',
                'RenderMarkdownH4',
                'RenderMarkdownH5',
                'RenderMarkdownH6',
            },
        },
        render_modes = { 'n', 'v', 'i', 'c' },
        checkbox = {
            unchecked = { icon = '󰄱 ' },
            checked = { icon = ' ' },
            custom = { todo = { raw = '[>]', rendered = '󰥔 ' } },
        },
        code = {
            position = 'right',
            width = 'block',
            left_pad = 2,
            right_pad = 4,
        },
    },
})

--- KEYMAPS ---

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>', { desc = "Update Source" })
-- vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = "Format Code" })
vim.keymap.set('n', '<leader>p', function()
        require("oil").open("~/Documents/Github")
    end,
    { desc = "Open Project Directories" }
)
vim.keymap.set('n', '<leader>d', function()
        require("oil").open("~/")
    end,
    { desc = "Open Directories" }
)
vim.keymap.set('n', 'zf', function()
        Snacks.picker.files({ cwd = vim.fn.expand("~/") })
    end,
    { desc = "Find User Directories" }
)
vim.keymap.set('n', '<leader>f', function()
        Snacks.picker.files({ cwd = vim.fn.expand("~/Documents/Github") })
    end,
    { desc = "Find Project Directories" }
)
vim.keymap.set('n', '<leader>g', function()
        Snacks.picker.grep({ cwd = vim.fn.expand("~/Documents/Github") })
    end,
    { desc = "Grep Project Directories" }
)

vim.keymap.set({ "n", "i", "v" }, "<C-s>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode

    -- Leave insert/visual cleanly before doing anything else
    if mode:sub(1, 1) == "i" then
        vim.cmd("stopinsert")
    elseif mode:sub(1, 1) == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "nx",
            false
        )
    end


    local function save_file()
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

    -- [No Name] buffer: prompt for a path in cwd
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

    save_file()
end, { noremap = true, silent = true, desc = "Save" })

local quit = function()
    local mode = vim.fn.mode()

    -- Leave insert / terminal mode cleanly
    if mode == "i" then
        vim.cmd("stopinsert")
    elseif mode == "t" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
            "n",
            false
        )
    end

    -- 1. Try Leet exit first
    if pcall(vim.cmd, "Leet exit") then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local modified = vim.bo[buf].modified

    -- 2. If empty [No Name] buffer → quit Neovim
    if name == "" and not modified then
        pcall(
            vim.cmd, "qa"
        )
        return
    end

    -- 3. Fallback: smart close
    local wins = vim.fn.win_findbuf(buf)

    if #wins > 1 then
        pcall(vim.cmd, "close")
    else
        pcall(vim.cmd, "bd!")
    end
end

vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", function()
    quit()
end, { noremap = true, silent = true, desc = "Smart close / quit" })
vim.keymap.set({ "n" }, "q", function()
    quit()
end, { noremap = true, silent = true, desc = "Smart close / quit" })

vim.keymap.set("n", "zv", "<cmd>vsplit<CR><C-w>l", { noremap = true, silent = true, desc = "Split Vertically" })
vim.keymap.set("n", "zh", "<cmd>split<CR><C-w>j", { noremap = true, silent = true, desc = "Split Horizontally" })
vim.keymap.set("n", "<C-w>", "<C-w>w", { noremap = true, silent = true, desc = "Switch to next window" })
vim.keymap.set(
    "i",
    "<C-w>",
    "<Esc><C-w>w",
    { noremap = true, silent = true, desc = "Switch to next window from insert mode" }
)
vim.keymap.set("v", "<C-w>", "<C-w>w", { noremap = true, silent = true, desc = "Switch to next window in visual mode" })
vim.keymap.set(
    "t",
    "<C-w>",
    [[<C-\><C-n><C-w>w]],
    { noremap = true, silent = true, desc = "Switch to next window in terminal mode" }
)

vim.keymap.set('n', '<leader>c', clear_search, {
    desc = "Clear Search highlight and pattern"
})
vim.keymap.set("n", "n", function()
    smart_search_and_jump("n")
end, { desc = "Sticky Search: next occurrence" })
vim.keymap.set("n", "N", function()
    smart_search_and_jump("N")
end, { desc = "Sticky Search: previous occurrence" })
vim.keymap.set("n", "<leader>s", function()
    case_sensitive = not case_sensitive

    if sticky_active and sticky_word then
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    vim.notify("Sticky Search case-sensitive: " .. tostring(case_sensitive), vim.log.levels.INFO, { timeout = 1000 })
end, { desc = "Toggle case sensitivity for sticky search" })
-- 1. A keymap to START the interactive replace
-- This finds the word under the cursor and readies the first replacement.
vim.keymap.set('n', '<leader>i', '*Ncgn', {
    noremap = true,
    silent = true,
    desc = "Start interactive replace for word under cursor"
})
vim.keymap.set({ 'n', 'i' }, '<C-.>', function()
    local function do_repeat()
        vim.api.nvim_feedkeys('.', 'n', false)
        -- Uncomment below to return to insert mode after replacing
        -- vim.api.nvim_feedkeys('i', 'n', false)
    end

    if vim.fn.mode() == 'i' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>n', true, false, true), 'n', false)
        vim.defer_fn(do_repeat, 30)
    else
        vim.api.nvim_feedkeys('n', 'n', false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace current match and find next (with delay fix)"
})
-- 2. A keymap for "Replace and Find Previous"
-- This repeats the last change (.) and jumps to the previous match (N).
vim.keymap.set({ 'n', 'i' }, '<C-,>', function()
    local function do_repeat()
        vim.api.nvim_feedkeys('.', 'n', false)
    end

    if vim.fn.mode() == 'i' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>N', true, false, true), 'n', false)
        vim.defer_fn(do_repeat, 30) -- delay 30ms
    else
        vim.api.nvim_feedkeys('N', 'n', false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace previous match properly"
})

vim.keymap.set({ "n", "t" }, "<C-a>", "<cmd>Alpha<CR>", { noremap = true, silent = true, desc = "Open Alpha" })
vim.keymap.set("n", "zlo", function()
    local cwd = vim.fn.getcwd()

    vim.fn.jobstart({
        "kitty", "@", "launch",
        "--cwd", cwd,
        "--type", "tab",
        "nvim",
        "+Leet",
    }, { detach = true })
end, {
    noremap = true,
    silent = true,
    desc = "Open Leet in kitty tab",
})
vim.keymap.set("n", "zlt", "<cmd>Leet Run<CR>", { noremap = true, silent = true, desc = "Test Leet Solution" })
vim.keymap.set("n", "zls", "<cmd>Leet Submit<CR>", { noremap = true, silent = true, desc = "Submit Leet Solution" })
vim.keymap.set("n", "zll", "<cmd>Leet List<CR>", { noremap = true, silent = true, desc = "List Leet Problems" })
vim.keymap.set("n", "zlr", "<cmd>Leet Reset<CR>", { noremap = true, silent = true, desc = "Reset Leet Solution" })
vim.keymap.set("n", "go", open_in_file_manager,
    { noremap = true, silent = true, desc = "Open Current folder in Explorer/Finder" })

vim.keymap.set("n", "zsw", function()
    require("grug-far").open({
        prefills = { search = vim.fn.expand("<cword>") },
    })
end, { desc = "Search current word" })

-- Visual selection search
vim.keymap.set("v", "zsw", function()
    require("grug-far").with_visual_selection()
end, { desc = "Search selection" })

vim.keymap.set("n", "zs", function()
    require("grug-far").open({ transient = true })
end, { desc = "Search Window" })
