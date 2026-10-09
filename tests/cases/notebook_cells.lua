-- Cells are found by their fences, and a cell really runs in a kernel.
local lines = { "# Title", "", "```python", "x = 1", "y = 2", "```", "text", "```{python}", "z = 3", "```", "```", "" }
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
local cells = require("notebook").cells(0)
T.eq(#cells, 2, "two code cells found")
T.eq(cells[1], { first = 4, last = 5 }, "first cell lines")
T.eq(cells[2], { first = 9, last = 9 }, "second cell lines")
T.eq(require("notebook").cell_at(0, 4), cells[1], "cursor in a cell")
T.eq(require("notebook").cell_at(0, 7), nil, "cursor outside any cell")

local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local out = vim.env.TEST_DIR .. "/ran.txt"
local nb = vim.json.encode({
    cells = { { cell_type = "code", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {},
        source = { ("open(%q, 'w').write('ran')"):format(out) } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("run.ipynb", nb))
local run = require("notebook").cells(0)
vim.api.nvim_win_set_cursor(0, { run[1].first, 0 })
vim.cmd("NotebookRunCell")
vim.wait(25000, function() return vim.fn.filereadable(out) == 1 end, 200)
T.eq(vim.fn.filereadable(out), 1, "the cell ran in the kernel")

-- And the result is shown: the cell ends "Done", not stuck "On Hold".
local function status()
    for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
        local d = m[4]
        if d.virt_lines and d.virt_lines[1] then return d.virt_lines[1][1][1] end
    end
end
vim.wait(10000, function() return (status() or ""):find("Done", 1, true) ~= nil end, 200)
T.ok((status() or ""):find("Done", 1, true), "cell output shows Done (was: " .. tostring(status()) .. ")")

-- Saving the notebook writes the outputs into the .ipynb.
vim.cmd("write")
local saved_nb
vim.wait(10000, function()
    saved_nb = vim.json.decode(table.concat(vim.fn.readfile(vim.api.nvim_buf_get_name(0)), "\n"))
    local outs = saved_nb.cells[1] and saved_nb.cells[1].outputs
    return outs and #outs > 0
end, 300)
local outs = saved_nb.cells[1].outputs
T.ok(outs and #outs > 0, "the cell's output was saved into the notebook")
