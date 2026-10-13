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

-- Exiting the terminal's shell itself, while full screen, also returns to the normal layout.
vim.cmd("TerminalNew")
vim.wait(800)
local second = vim.api.nvim_get_current_buf()
vim.cmd("TerminalFull")
vim.wait(300)
T.ok(terminals.full_active(), "full screen again")
vim.fn.chansend(vim.b[second].terminal_job_id, "exit\n")
vim.wait(4000, function() return not terminals.full_active() end, 100)
T.ok(not terminals.full_active(), "the shell exiting closes the full-screen view")
T.ok(vim.api.nvim_win_get_config(0).relative == "", "focus is back in a normal window")

-- Full screen opened by hand, then opencode run in it: quitting opencode still goes back.
vim.cmd("TerminalNew")
vim.wait(800)
local third = vim.api.nvim_get_current_buf()
vim.cmd("TerminalFull")
vim.wait(300)
terminals.send("export PATH=" .. vim.fn.shellescape(vim.fn.fnamemodify(bin, ":h")) .. ":$PATH; opencode", { focus = false })
scan_until(function() return vim.b[third].terminal_full_program == true end)
T.ok(vim.b[third].terminal_full_program, "the running program was noticed")
T.ok(terminals.full_active(), "still full screen while it runs")
vim.fn.system({ "pkill", "-f", "sleep 6" })
scan_until(function() return not terminals.full_active() end)
T.ok(not terminals.full_active(), "quitting the program leaves full screen")
