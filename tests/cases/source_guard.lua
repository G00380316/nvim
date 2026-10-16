-- <leader>o sources Lua and Vim files, and refuses anything else instead of erroring on every line.
vim.cmd("edit " .. T.file("transcript.txt", "[user@host ~]$ cd Documents\n[user@host Documents]$ ls\n"))
local messages = {}
local real = vim.notify
vim.notify = function(msg, ...) messages[#messages + 1] = msg end
vim.fn.maparg("<leader>o", "n", false, true).callback()
vim.notify = real
T.ok(table.concat(messages, " "):find("Only Lua and Vim", 1, true), "a text file is refused with a clear message")
local errors = vim.api.nvim_exec2("messages", { output = true }).output
T.ok(not errors:find("E492", 1, true), "and nothing was sourced")

vim.g.sourced_by_test = nil
vim.cmd("edit " .. T.file("s.lua", "vim.g.sourced_by_test = 'yes'\n"))
vim.fn.maparg("<leader>o", "n", false, true).callback()
T.eq(vim.g.sourced_by_test, "yes", "a Lua file is sourced")
