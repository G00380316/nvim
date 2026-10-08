-- In code, buffer words are offered only while writing a comment.
local path = T.file("w.lua", "local wonderful = 1\n-- won\nlocal won\n")
vim.cmd("edit " .. path)
vim.treesitter.start(0, "lua")
local blink = require("blink.cmp")

local function offered(row, col)
    vim.api.nvim_win_set_cursor(0, { row, col })
    vim.cmd("startinsert!")
    blink.hide()
    blink.show({ providers = { "buffer" } })
    vim.wait(800, function() return #blink.get_items() > 0 end)
    local items = blink.get_items()
    vim.cmd("stopinsert")
    return #items > 0
end

T.ok(offered(2, 6), "words are offered inside a comment")
T.ok(not offered(3, 9), "words are not offered in code")
