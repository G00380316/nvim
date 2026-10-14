-- "Show output" opens the cell's output in an ordinary, editable buffer.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", id = "c1", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "for i in range(5): print('row', i)" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("o.ipynb", nb))
local notebook = require("notebook")
if notebook.output_mode() ~= "inline" then notebook.toggle_output_mode() end
vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("all 1 cells ran", 1, true) ~= nil end, 200)
local notebook_buf = vim.api.nvim_get_current_buf()
local cells = notebook.cells(0)
vim.api.nvim_win_set_cursor(0, { cells[1].first, 0 })

vim.cmd("NotebookOutput")
local out = vim.api.nvim_get_current_buf()
T.ok(out ~= notebook_buf, "a buffer of its own was opened")
T.eq(vim.bo[out].modifiable, true, "it is editable")
T.eq(vim.bo[out].readonly, false, "and not read-only")
local lines = vim.api.nvim_buf_get_lines(out, 0, -1, false)
T.eq(lines[1], "row 0", "the output starts at the top")
T.eq(#lines, 5, "all five lines are there")
-- Move and edit like any buffer.
vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.cmd("normal! Ix")
T.eq(vim.api.nvim_buf_get_lines(out, 2, 3, false)[1], "xrow 2", "it can be edited")
vim.cmd("close")
T.ok(not vim.api.nvim_buf_is_valid(out) or not vim.api.nvim_buf_is_loaded(out), "q / close removes it")
