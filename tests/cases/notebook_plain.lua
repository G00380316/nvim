-- Markdown rendering is off in notebooks, so cell output is not drawn over.
if vim.fn.executable("jupytext") == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "x = 1" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("p.ipynb", nb))
vim.wait(1500)
local ns = vim.api.nvim_create_namespace("render-markdown.nvim")
local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
T.eq(#marks, 0, "no render-markdown overlays in the notebook buffer")
