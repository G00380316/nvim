-- The explorer can be widened, wraps only when asked, and can give up its git-marks column.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil
for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "oil" then oil = w end
end
T.ok(oil, "explorer open")
T.eq(vim.wo[oil].wrap, false, "names on one line to begin with")
vim.cmd("ExplorerWrap"); T.eq(vim.wo[oil].wrap, true, "wrap on")
vim.cmd("ExplorerWrap"); T.eq(vim.wo[oil].wrap, false, "wrap off")
vim.cmd("ExplorerMarks"); T.eq(vim.wo[oil].signcolumn, "no", "marks column hidden")
vim.cmd("ExplorerMarks"); T.eq(vim.wo[oil].signcolumn, "yes:3", "marks column back")

local before = vim.api.nvim_win_get_width(oil)
vim.cmd("ExplorerWiden"); vim.wait(300)
T.ok(vim.api.nvim_win_get_width(oil) > before, "widened")
vim.cmd("ExplorerWiden"); vim.wait(300)
T.eq(vim.api.nvim_win_get_width(oil), before, "back to normal")
