-- Copy cell output puts what the cell printed, whole, on the clipboard.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local function cell(id, src) return { cell_type = "code", id = id, execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { src } } end
local nb = vim.json.encode({
    cells = { cell("a1", "print('line one')\nprint('line two ' + 'x' * 150)\n40 + 2"), cell("b2", "print('other')") },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("c.ipynb", nb))
local notebook = require("notebook")
if notebook.output_mode() ~= "inline" then notebook.toggle_output_mode() end
vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("all 2 cells ran", 1, true) ~= nil end, 200)

local cells = notebook.cells(0)
vim.api.nvim_win_set_cursor(0, { cells[1].first, 0 })
vim.fn.setreg("+", "")
vim.cmd("NotebookCopyOutput")
local copied = vim.fn.getreg("+")
T.ok(copied:find("line one\nline two ", 1, true), "both printed lines are there, unbroken (" .. copied:sub(1, 60):gsub("\n", "\\n") .. ")")
T.ok(copied:find("x" .. ("x"):rep(149), 1, true), "the long line is whole, not wrapped")
T.ok(copied:find("42", 1, true), "the result is there too")
T.ok(not copied:find("other", 1, true), "only this cell's output")
T.ok(not copied:find("\27", 1, true), "no colour codes")
