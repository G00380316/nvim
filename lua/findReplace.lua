-- A function to search for the word under the cursor and then jump
local function smart_search_and_jump(direction)
    local word = vim.fn.expand("<cword>")
    if word == "" then
        vim.notify("No word under cursor", vim.log.levels.WARN, { timeout = 1000 })
        return
    end

    vim.fn.setreg('/', '\\<' .. word .. '\\>')

    vim.opt.hlsearch = true

    vim.api.nvim_feedkeys(direction, 'n', false)
end

-- A function to clear search highlighting and the search pattern
local function clear_search()
    vim.fn.setreg('/', '')
    vim.notify("Search cleared", vim.log.levels.INFO, { timeout = 1000 })
end

vim.keymap.set('n', 'cn', clear_search, {
    desc = "Clear search highlight and pattern"
})

function smart_search_and_jump(direction)
    local current_word = vim.fn.expand('<cword>')
    if current_word == '' then return end

    local search_pattern = '\\c\\<' .. current_word .. '\\>'
    vim.fn.setreg('/', search_pattern) -- set search register
    vim.cmd('normal! ' .. direction)   -- perform normal n or N
end

vim.keymap.set('n', 'n', function() smart_search_and_jump('n') end, {
    desc = "Find next occurrence of current word (case-insensitive)"
})

vim.keymap.set('n', 'N', function() smart_search_and_jump('N') end, {
    desc = "Find previous occurrence of current word (case-insensitive)"
})

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
