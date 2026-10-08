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

-- Formatting follows the ruler: textwidth for gq, and the servers' own setting.
vim.cmd("edit " .. T.file("w.py", "x = 1\n"))
vim.wait(100)
T.eq(vim.bo.textwidth, 120, "textwidth follows the ruler (120)")
vim.cmd("RulerWidth")
T.eq(vim.bo.textwidth, 80, "textwidth follows the ruler (80)")
vim.cmd("RulerToggle")
T.eq(vim.bo.textwidth, 0, "ruler off: no wrapping width")
T.eq(require("ruler").server_settings("ruff", 80), { lineLength = 80 }, "ruff line length")
T.eq(require("ruler").server_settings("lua_ls", 100).Lua.format.defaultConfig.max_line_length, "100", "lua_ls line length")
