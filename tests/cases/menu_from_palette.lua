-- A menu opened from the palette keeps the window the palette was opened in.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil_win = vim.api.nvim_get_current_win()
local oil_buf = vim.api.nvim_get_current_buf()
local menus = require("action_menus")

local got
local real_pick = menus.pick
menus.pick = function(menu, origin) got = origin end
vim.cmd("wincmd l")
menus.open("hints", { win = oil_win, buf = oil_buf })
menus.pick = real_pick
T.ok(got and got.win == oil_win, "the menu was handed the palette's window")

vim.api.nvim_set_current_win(oil_win)
-- <C-x> in the explorer runs the entry with arguments instead of Vim's own <C-x>.
for _, mode in ipairs({ "n", "i" }) do
    local map = vim.fn.maparg("<C-x>", mode, false, true)
    T.ok(map and map.buffer == 1 and map.desc and map.desc:find("arguments", 1, true), "explorer <C-x> mapped in " .. mode)
end
