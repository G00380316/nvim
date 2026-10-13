-- A terminal can be shown full screen and put back; app mode sends <Tab> to the program.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
local terminals = require("terminals")
local buf = terminals.list()[1]
local panel_win = vim.fn.win_findbuf(buf)[1]
local before = {}
for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do before[w] = vim.api.nvim_win_get_height(w) end

vim.cmd("TerminalFull")
vim.wait(300)
T.ok(terminals.full_active(), "full screen on")
local win = vim.api.nvim_get_current_win()
T.eq(vim.api.nvim_win_get_buf(win), buf, "the same terminal is shown")
T.eq(vim.api.nvim_win_get_width(win), vim.o.columns, "full width")
T.ok(vim.api.nvim_win_get_height(win) >= vim.o.lines - 3, "full height")
T.eq(vim.b[buf].terminal_app, true, "full screen terminals are app terminals")

vim.cmd("TerminalFull")
vim.wait(300)
T.ok(not terminals.full_active(), "full screen off")
for w, h in pairs(before) do
    if vim.api.nvim_win_is_valid(w) then T.eq(vim.api.nvim_win_get_height(w), h, "layout untouched (window " .. w .. ")") end
end

-- <Tab> in the app terminal's normal mode goes to the program, not to the next buffer.
local map = vim.fn.maparg("<Tab>", "n", false, true)
vim.api.nvim_set_current_buf(buf)
map = vim.fn.maparg("<Tab>", "n", false, true)
T.ok(map.buffer == 1 and (map.desc or ""):find("program", 1, true), "<Tab> is sent to the program in an app terminal")

-- An app terminal pages its program with <C-Up> / <C-Down>, as the mouse is off.
vim.api.nvim_set_current_buf(buf)
for _, lhs in ipairs({ "<C-Up>", "<C-Down>" }) do
    local m = vim.fn.maparg(lhs, "t", false, true)
    T.ok(m.buffer == 1 and (m.desc or ""):find("Scroll the program", 1, true), lhs .. " pages the program")
end
