-- A split terminal panel can be zoomed to one terminal, cycled like buffers, and restored.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
vim.cmd("TerminalSplit")
vim.wait(1000)
local terminals = require("terminals")
local function panel()
    local out = {}
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(w).relative == "" and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "floaterm" then out[#out + 1] = w end
    end
    return out
end
T.eq(#panel(), 2, "the panel is split in two")
local bufs = terminals.list()
T.eq(#bufs, 2, "two terminals")

vim.cmd("TerminalZoom")
vim.wait(300)
T.eq(#panel(), 1, "zoomed: one window fills the panel")
T.eq(#terminals.list(), 2, "the other terminal is still alive behind it")
local shown = vim.api.nvim_win_get_buf(panel()[1])

-- zn swaps which terminal is on top, still one window.
terminals.cycle(1)
vim.wait(300)
T.eq(#panel(), 1, "still one window after cycling")
T.ok(vim.api.nvim_win_get_buf(panel()[1]) ~= shown, "the other terminal is on top now")

vim.cmd("TerminalZoom")
vim.wait(300)
T.eq(#panel(), 2, "restored: the split is back")
