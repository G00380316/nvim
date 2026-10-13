-- Typing opencode in any terminal puts it in app mode and full screen, and back when it exits.
local bin = T.file("bin/opencode", "#!/bin/sh\nsleep 6\n")
vim.fn.system({ "chmod", "+x", bin })
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
local terminals = require("terminals")
local buf = terminals.list()[1]

terminals.send("export PATH=" .. vim.fn.shellescape(vim.fn.fnamemodify(bin, ":h")) .. ":$PATH; opencode", { focus = false })
local function scan_until(cond)
    vim.wait(8000, function()
        terminals.scan_programs()
        vim.wait(400)
        return cond()
    end, 100)
end

scan_until(function() return terminals.full_active() end)
T.ok(terminals.full_active(), "the terminal went full screen by itself")
T.eq(vim.b[buf].terminal_app, true, "and into app mode")

-- Exit the program: back in the panel.
vim.fn.system({ "pkill", "-f", "sleep 6" })
scan_until(function() return not terminals.full_active() end)
T.ok(not terminals.full_active(), "back in the panel when the program exits")
