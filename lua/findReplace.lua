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
    -- Turn off search highlighting
    vim.opt.hlsearch = false
    -- Optional: Clear the last search pattern to fully exit the "mode"
    vim.fn.setreg('/', '')
    vim.notify("Search cleared", vim.log.levels.INFO, { timeout = 1000 })
end

vim.keymap.set('n', 'cn', clear_search, {
    desc = "Clear search highlight and pattern"
})
-- Map 'n' and 'N' to the new smart function
vim.keymap.set('n', 'n', function() smart_search_and_jump('n') end, {
    desc = "Find next occurrence of current word"
})

vim.keymap.set('n', 'N', function() smart_search_and_jump('N') end, {
    desc = "Find previous occurrence of current word"
})
