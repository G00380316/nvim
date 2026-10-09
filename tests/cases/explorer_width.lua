-- The explorer wraps by itself when a name is too long, and can be forced either way.
vim.cmd("edit " .. T.file("proj/a.txt", "x\n"))
T.file("proj/this_is_an_extremely_long_file_name_that_cannot_possibly_fit_in_the_panel.txt", "x\n")
vim.cmd("cd " .. vim.env.TEST_DIR .. "/proj")
vim.cmd("FocusTree")
vim.wait(800)
local oil
for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "oil" then oil = w end
end
T.ok(oil, "explorer open")
vim.cmd("doautocmd WinResized")
vim.wait(300)
T.eq(vim.wo[oil].wrap, true, "a long name turns wrapping on by itself")

vim.cmd("ExplorerWrap") -- always
vim.cmd("ExplorerWrap") -- never
T.eq(vim.wo[oil].wrap, false, "never: one line even with a long name")
vim.cmd("ExplorerWrap") -- auto
vim.wait(300)
T.eq(vim.wo[oil].wrap, true, "auto again: wraps for the long name")

vim.cmd("ExplorerMarks"); T.eq(vim.wo[oil].signcolumn, "no", "marks column hidden")
vim.cmd("ExplorerMarks"); T.eq(vim.wo[oil].signcolumn, "yes:3", "marks column back")

local before = vim.api.nvim_win_get_width(oil)
vim.cmd("ExplorerWiden"); vim.wait(300)
T.ok(vim.api.nvim_win_get_width(oil) > before, "widened")
vim.cmd("ExplorerWiden"); vim.wait(300)
T.eq(vim.api.nvim_win_get_width(oil), before, "back to normal")
