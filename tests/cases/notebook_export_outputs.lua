-- All the outputs go into an editable Markdown file, whole.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local function cell(id, src) return { cell_type = "code", id = id, execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { src } } end
local nb = vim.json.encode({
    cells = { cell("a1", "print('first output')\n6 * 7"), cell("b2", "print('second ' + 'y' * 120)"), cell("c3", "z = 1") },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
local ipynb = T.file("e.ipynb", nb)
vim.cmd("edit " .. ipynb)
local notebook = require("notebook")
if notebook.output_mode() ~= "inline" then notebook.toggle_output_mode() end
vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("all 3 cells ran", 1, true) ~= nil end, 200)

vim.cmd("NotebookExportOutputs")
local md = vim.fn.fnamemodify(ipynb, ":r") .. "-outputs.md"
T.eq(vim.fn.filereadable(md), 1, "the Markdown file was written beside the notebook")
T.eq(vim.fn.resolve(vim.api.nvim_buf_get_name(0)), vim.fn.resolve(md), "and opened for editing")
local text = table.concat(vim.fn.readfile(md), "\n")
T.ok(text:find("## Cell 1", 1, true) and text:find("## Cell 2", 1, true), "a section per cell with output")
T.ok(not text:find("## Cell 3", 1, true), "a cell with no output has no section")
T.ok(text:find("first output", 1, true) and text:find("42", 1, true), "cell 1's output is there")
T.ok(text:find("y" .. ("y"):rep(119), 1, true), "long output is whole")
T.ok(text:find("```python", 1, true), "the code is shown too")
T.eq(vim.bo.modifiable, true, "the file is editable")

-- Running it again refreshes the generated file; a file you changed is not overwritten.
vim.fn.writefile({ "my own notes" }, md)
vim.cmd("buffer " .. vim.fn.bufnr(ipynb))
vim.cmd("NotebookExportOutputs")
local second = vim.fn.fnamemodify(ipynb, ":r") .. "-outputs-2.md"
T.eq(vim.fn.filereadable(second), 1, "your own file was left alone; a numbered one was made")
T.eq(vim.fn.readfile(md)[1], "my own notes", "and untouched")
