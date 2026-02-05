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

--- SPECIAL MAPPINGS ---

vim.keymap.set("n", "q", "<nop>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-d>", "<C-d>zz")                                     -- Scroll Half-Page and Center
vim.keymap.set("n", "<C-u>", "<C-u>zz")                                     -- Scroll Half-Page and Center
vim.keymap.set("n", "J", "mzJ`z")                                           -- Keep Cursor Position When Joining Lines
vim.keymap.set("n", "n", "nzzzv")                                           -- Center Search Results
vim.keymap.set("n", "N", "Nzzzv")                                           -- Center Search Results
vim.keymap.set({ "v", "x" }, "J", ":m '>+1<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set({ "v", "x" }, "K", ":m '<-2<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set({ "v", "x" }, ">", ">gv", { noremap = true, silent = true }) -- Outdent selected block of text
vim.keymap.set({ "v", "x" }, "<", "<gv", { noremap = true, silent = true }) -- Outdent selected block of text

vim.keymap.set({ 'n', 'v' }, 'y', '"+y')
-- Delete Without Affecting Clipboard
vim.keymap.set({ "n", "v" }, "d", [["_d]])
-- Standard-editor-style visual paste (using the system clipboard)
vim.keymap.set("x", "p", [["+P]], { silent = true })

vim.keymap.set({ "n", "v", "i", "t" }, "<C-]>", "<cmd>bn<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-[>", "<cmd>bp<CR>", { noremap = true, silent = true })

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
    vim.fn.jobstart({ "lazygit" }, { term = true })
    vim.cmd("startinsert")
end, { desc = "Open Lazygit in floating terminal" })

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
            vim.api.nvim_replace_termcodes("ciw", true, false, true),
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
    { desc = "Search Visual selection or Word" })

vim.keymap.set("n", "zkm", function() Snacks.picker.keymaps() end, { desc = "Search Keymaps" })

vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    Snacks.picker.buffers({
        sort_mru = true,
        current = true,
    })
end, { desc = "Choose a buffer" })

vim.keymap.set({ "n" }, "/", function()
    Snacks.picker.lines({
        layout = {
            preset = "telescope", -- Uses the Telescope-style floating layout
            -- To make it "take over" the buffer area:
            width = 0.95,
            height = 0.95,
            preview = false, -- Set to true if you want to see the code on the side
        },
        format = {
            line_number = false,
        },
        win = {
            input = {
                keys = {
                    ["<C-c>"] = { "close", mode = { "n", "i" } },
                    ["<leader>c"] = { "toggle_ignore_case", mode = { "n", "i" } },
                }
            }
        },
        prompt = "  ",
    })
end, { desc = "Find in current buffer" })
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
    { desc = "Opening Project Directories" }
)
vim.keymap.set('n', '<leader>f', function()
        Snacks.picker.files({ cwd = vim.fn.expand("~/Documents/Github") })
    end,
    { desc = "Search Project Directories" }
)
vim.keymap.set('n', '<leader>g', function()
        Snacks.picker.grep({ cwd = vim.fn.expand("~/Documents/Github") })
    end,
    { desc = "Grep Project Directories" }
)

vim.keymap.set({ "n", "i", "v" }, "<C-s>", function()
    local bufnr = 0

    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    end
    if vim.bo.filetype ~= "oil" and has_lsp(bufnr) then
        vim.lsp.buf.format({ async = false })
    end
    vim.cmd("write")
    vim.fn.setreg("/", "")
end, { noremap = true, silent = true, desc = "Save" })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", function()
    -- Leave insert / terminal mode cleanly
    if vim.fn.mode() == "i" then
        vim.cmd("stopinsert")
    elseif vim.fn.mode() == "t" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
            "n",
            false
        )
    end

    local buf = vim.api.nvim_get_current_buf()
    local wins = vim.fn.win_findbuf(buf)

    if #wins > 1 then
        -- Buffer is visible in multiple windows → close only this window
        vim.cmd("close")
    else
        -- Only one window shows this buffer → delete buffer
        vim.cmd("bd!")
    end
end, { noremap = true, silent = true, desc = "Smart close window / buffer" })
vim.keymap.set({ "n", "v" }, "zv", "<cmd>vsplit<CR>", { noremap = true, silent = true, desc = "Split Vertically" })
vim.keymap.set({ "n", "v" }, "zh", "<cmd>split<CR>", { noremap = true, silent = true, desc = "Split Horizontally" })
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
    desc = "Clear search highlight and pattern"
})
vim.keymap.set("n", "n", function()
    smart_search_and_jump("n")
end, { desc = "Sticky search: next occurrence" })
vim.keymap.set("n", "N", function()
    smart_search_and_jump("N")
end, { desc = "Sticky search: previous occurrence" })
vim.keymap.set("n", "<leader>s", function()
    case_sensitive = not case_sensitive

    if sticky_active and sticky_word then
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    vim.notify("Sticky search case-sensitive: " .. tostring(case_sensitive), vim.log.levels.INFO, { timeout = 1000 })
end, { desc = "Toggle case sensitivity for sticky search" })
-- 1. A keymap to START the interactive replace
-- This finds the word under the cursor and readies the first replacement.
vim.keymap.set('n', '<leader>r', '*Ncgn', {
    noremap = true,
    silent = true,
    desc = "Start interactive replace for word under cursor"
})
vim.keymap.set({ 'n', 'i' }, '<C-n>', function()
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
vim.keymap.set({ 'n', 'i' }, '<C-p>', function()
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

vim.keymap.set({ "n", "t" }, "<C-a>", "<cmd>Alpha<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zlo",
    "<cmd>silent !kitty @ launch --type=os-window nvim +'Leet'<CR>"
    , { noremap = true, silent = true })
vim.keymap.set("n", "zlt", "<cmd>Leet Run<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zls", "<cmd>Leet Submit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zll", "<cmd>Leet List<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "zlr", "<cmd>Leet Reset<CR>", { noremap = true, silent = true })
