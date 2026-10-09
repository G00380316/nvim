-- The statusline text says how far a run has got; marker lines are hidden, other comments are not.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local function cell(src)
    return { cell_type = "code", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { src } }
end
local nb = vim.json.encode({
    cells = { { cell_type = "markdown", metadata = vim.empty_dict(), source = { "# t" } }, cell("a = 1"), cell("b = a + 1") },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("s.ipynb", nb))
local notebook = require("notebook")
T.eq(notebook.status_text(), "", "nothing said before anything runs")

vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("all 2 cells ran", 1, true) ~= nil end, 200)
T.ok(notebook.status_text():find("✓ all 2 cells ran", 1, true), "finished run reported (got: " .. notebook.status_text() .. ")")

-- A cell that fails is reported as an error.
vim.cmd("enew")
local bad = vim.json.encode({
    cells = { cell("1/0") },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("bad.ipynb", bad))
vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("✗", 1, true) ~= nil end, 200)
T.ok(notebook.status_text():find("1 error", 1, true), "error reported (got: " .. notebook.status_text() .. ")")
