-- The explorer can be widened, and long names wrap inside it.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil
for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "oil" then oil = w end
end
T.ok(oil, "explorer open")
T.eq(vim.wo[oil].wrap, true, "long names wrap")
local before = vim.api.nvim_win_get_width(oil)
vim.cmd("ExplorerWiden")
vim.wait(300)
T.ok(vim.api.nvim_win_get_width(oil) > before, "widened (" .. before .. " -> " .. vim.api.nvim_win_get_width(oil) .. ")")
vim.cmd("ExplorerWiden")
vim.wait(300)
T.eq(vim.api.nvim_win_get_width(oil), before, "back to normal")
