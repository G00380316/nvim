-- A .ipynb opens as Markdown and saves back as a notebook.
if vim.fn.executable("jupytext") == 0 then return end -- needs `pipx install jupytext`
local nb = vim.json.encode({
    cells = {
        { cell_type = "markdown", metadata = vim.empty_dict(), source = { "# Title" } },
        { cell_type = "code", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "x = 1" } },
    },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4,
    nbformat_minor = 5,
})
local path = T.file("n.ipynb", nb)
vim.cmd("edit " .. path)
T.eq(vim.bo.filetype, "jupyter", "opened as a notebook (Markdown inside)")
local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
T.ok(text:find("# Title", 1, true) and text:find("```python", 1, true), "cells shown as markdown and code fences")
vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", "more text" })
vim.cmd("write")
local saved = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
T.eq(saved.nbformat, 4, "saved back as a notebook")
T.eq(#saved.cells, 3, "the new cell was written")
