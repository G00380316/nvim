-- LeetCode runs as its own full-screen Neovim, not inside this one.
local fake = T.file("bin/nvim", '#!/bin/sh\necho "FAKE-NVIM $NVIM_NESTED $@"\nsleep 4\n')
vim.fn.system({ "chmod", "+x", fake })
vim.env.PATH = vim.fn.fnamemodify(fake, ":h") .. ":" .. vim.env.PATH

vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("LeetCode")
local terminals = require("terminals")
vim.wait(3000, function() return terminals.full_active() end, 100)
T.ok(terminals.full_active(), "it is shown full screen")
local buf = vim.api.nvim_win_get_buf(0)
vim.wait(1500)
local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
T.ok(text:find("FAKE-NVIM 1 leetcode.nvim", 1, true), "it started a second Neovim with the leetcode argument (" .. text:gsub("\n", " "):sub(1, 120) .. ")")

-- Running the action again hides it, and again shows the same one.
vim.cmd("LeetCode")
vim.wait(300)
T.ok(not terminals.full_active(), "hidden")
vim.cmd("LeetCode")
vim.wait(300)
T.ok(terminals.full_active(), "shown again")
T.eq(vim.api.nvim_win_get_buf(0), buf, "the same instance")
