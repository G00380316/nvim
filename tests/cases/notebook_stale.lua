-- Editing a cell after it ran no longer makes the save "bail": its output is dropped, others are kept.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local function cell(id, src) return { cell_type = "code", id = id, execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { src } } end
local nb = vim.json.encode({
    cells = { cell("a1", "a = 1\nprint('first')"), cell("b2", "print('second')") },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("s.ipynb", nb))
local notebook = require("notebook")
if notebook.output_mode() ~= "inline" then notebook.toggle_output_mode() end
vim.cmd("NotebookRunAll")
vim.wait(30000, function() return notebook.status_text():find("all 2 cells ran", 1, true) ~= nil end, 200)
T.ok(notebook.status_text():find("all 2 cells ran", 1, true), "both cells ran")

-- Edit the first cell's code after it ran.
local cells = notebook.cells(0)
vim.api.nvim_buf_set_lines(0, cells[1].first - 1, cells[1].first, false, { "a = 999" })

local messages = {}
local real_notify = vim.notify
vim.notify = function(msg, ...) messages[#messages + 1] = msg; return real_notify(msg, ...) end
vim.cmd("write")
vim.wait(4000, function()
    for _, m in ipairs(messages) do if m:find("Not saved", 1, true) then return true end end
end, 100)
vim.notify = real_notify
local joined = table.concat(messages, "\n")
T.ok(joined:find("Not saved", 1, true), "the stale output was reported (" .. joined:gsub("\n", " | ") .. ")")
T.ok(not joined:find("Bailing", 1, true), "the export did not bail")

-- The unedited cell's output was still written.
vim.wait(3000, function()
    local saved = vim.json.decode(table.concat(vim.fn.readfile(vim.api.nvim_buf_get_name(0)), "\n"))
    return saved.cells[2] and saved.cells[2].outputs and #saved.cells[2].outputs > 0
end, 200)
local saved = vim.json.decode(table.concat(vim.fn.readfile(vim.api.nvim_buf_get_name(0)), "\n"))
T.ok(saved.cells[2].outputs and #saved.cells[2].outputs > 0, "the other cell's output was saved")
