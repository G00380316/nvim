-- <leader>xr / :Run send to the terminal but leave you in the editor, normal mode.
local path = T.file("t.py", "print(1)\n")
vim.cmd("edit " .. path)
local editor = vim.api.nvim_get_current_win()

vim.cmd("RunTest")
vim.wait(1500)
T.eq(vim.api.nvim_get_current_win(), editor, "focus after first run (new terminal)")
T.eq(vim.fn.mode(), "n", "mode after first run")

vim.cmd("RunTest")
vim.wait(500)
T.eq(vim.api.nvim_get_current_win(), editor, "focus after second run")
T.eq(vim.fn.mode(), "n", "mode after second run")

local lines = {}
for _, b in ipairs(require("terminals").list()) do
    vim.list_extend(lines, vim.api.nvim_buf_get_lines(b, 0, -1, false))
end
local text = table.concat(lines, "\n")
T.ok(text:find("runtest 't.py'", 1, true), "command reached the terminal")
T.ok(not text:find("k%(cd"), "no stray key in front of the command")
