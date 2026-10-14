-- Running a single cell works (it follows the run, which needs `watch`).
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", id = "c1", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "print('one cell')" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("r.ipynb", nb))
local notebook = require("notebook")
local cells = notebook.cells(0)
vim.api.nvim_win_set_cursor(0, { cells[1].first, 0 })
local ok, err = pcall(vim.cmd, "NotebookRunCell")
T.ok(ok, "NotebookRunCell does not error (" .. tostring(err) .. ")")
vim.wait(30000, function() return notebook.status_text():find("all 1 cells ran", 1, true) ~= nil end, 200)
T.ok(notebook.status_text():find("all 1 cells ran", 1, true), "the cell ran (" .. notebook.status_text() .. ")")
