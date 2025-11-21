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

    vim.notify("Search cleared", vim.log.levels.INFO, { timeout = 1000 })
end

vim.keymap.set('n', 'cn', clear_search, {
    desc = "Clear search highlight and pattern"
})

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

-- n / N keys use the sticky search
vim.keymap.set("n", "n", function()
    smart_search_and_jump("n")
end, { desc = "Sticky search: next occurrence" })

vim.keymap.set("n", "N", function()
    smart_search_and_jump("N")
end, { desc = "Sticky search: previous occurrence" })
-- Toggle case-sensitivity (applies to current sticky pattern too)

vim.keymap.set("n", "css", function()
    case_sensitive = not case_sensitive

    if sticky_active and sticky_word then
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    vim.notify("Sticky search case-sensitive: " .. tostring(case_sensitive), vim.log.levels.INFO, { timeout = 1000 })
end, { desc = "Toggle case sensitivity for sticky search" })

-- 1. A keymap to START the interactive replace
-- This finds the word under the cursor and readies the first replacement.
vim.keymap.set('n', 'wr', '*Ncgn', {
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

vim.keymap.set({ "n" }, "/", function()
    require("telescope.builtin").current_buffer_fuzzy_find({
        layout_strategy = "vertical",
        layout_config = {
            width = 0.4,
            height = 0.3,
            prompt_position = "top",
        },
        border = true,
        winblend = 10, -- Optional transparency
    })
end, { desc = "Find in current buffer (minimal)" })
