-- The ruler shows in file windows only and can be toggled and widened.
vim.cmd("edit " .. T.file("r.py", "x = 1\n"))
local file_win = vim.api.nvim_get_current_win()
vim.wait(100)
T.eq(vim.wo[file_win].colorcolumn, "80", "on at 80 in a file window")

vim.cmd("RulerWidth")
T.eq(vim.wo[file_win].colorcolumn, "120", "switched to 120")
vim.cmd("RulerToggle")
T.eq(vim.wo[file_win].colorcolumn, "", "toggled off")
vim.cmd("RulerToggle")
T.eq(vim.wo[file_win].colorcolumn, "120", "back on at 120")

vim.cmd("TerminalNew")
vim.wait(600)
local term_ruler
for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "floaterm" then term_ruler = vim.wo[w].colorcolumn end
end
T.eq(term_ruler, "", "no ruler in the terminal")
