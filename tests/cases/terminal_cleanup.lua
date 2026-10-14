-- Closing a terminal stops what it started, even a program that ignores hang-up and terminate.
local bin = T.file("bin/stubborn", "#!/bin/sh\ntrap '' HUP TERM\nsleep 31\n")
vim.fn.system({ "chmod", "+x", bin })
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
local terminals = require("terminals")
local buf = terminals.list()[1]
terminals.send("export PATH=" .. vim.fn.shellescape(vim.fn.fnamemodify(bin, ":h")) .. ":$PATH; stubborn", { focus = false })
vim.wait(1500)
local function running() return vim.fn.system("pgrep -f 'sleep 31'") ~= "" end
T.ok(running(), "the stubborn program is running")

vim.api.nvim_set_current_buf(buf)
vim.fn.maparg("<C-q>", "n", false, true).callback()
vim.wait(3000, function() return not running() end, 100)
T.ok(not running(), "it was stopped when the terminal was closed")
vim.fn.system("pkill -9 -f 'sleep 31'")
