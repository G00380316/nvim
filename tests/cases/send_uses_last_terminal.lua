-- Running a command uses the terminal you used last; a new one is made only when none exists.
vim.cmd("edit " .. T.file("a.py", "print(1)\n"))
local terminals = require("terminals")
T.eq(terminals.target(), nil, "no terminal yet")

vim.cmd("TerminalNew"); vim.wait(800)
vim.cmd("TerminalNew"); vim.wait(800)
local list = terminals.list()
T.eq(#list, 2, "two terminals")
local first, second = list[1], list[2]

-- Focus the second, go to the editor, and send: it must go to the second.
terminals.focus(second)
vim.wait(200)
vim.cmd("wincmd k")
vim.wait(200)
T.eq(terminals.target(), second, "last used terminal is the target")
terminals.send("echo LASTUSED", { focus = false })
vim.wait(800)
T.eq(#terminals.list(), 2, "no extra terminal was created")
local text = table.concat(vim.api.nvim_buf_get_lines(second, 0, -1, false), "\n")
T.ok(text:find("LASTUSED", 1, true), "command ran in the last used terminal")
local other = table.concat(vim.api.nvim_buf_get_lines(first, 0, -1, false), "\n")
T.ok(not other:find("LASTUSED", 1, true), "and not in the other")
