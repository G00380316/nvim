-- NotebookView turns the notebook into a page that includes its saved outputs.
local host = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(host) == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", execution_count = 1, metadata = vim.empty_dict(),
        outputs = { { output_type = "stream", name = "stdout", text = { "page output marker\n" } } },
        source = { "print('page output marker')" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
local bin = T.file("bin/open", '#!/bin/sh\necho "$@" > "$TEST_DIR/opened"\n')
vim.fn.system({ "chmod", "+x", bin })
vim.env.PATH = vim.fn.fnamemodify(bin, ":h") .. ":" .. vim.env.PATH
vim.cmd("edit " .. T.file("v.ipynb", nb))
vim.cmd("NotebookView")
local opened = vim.env.TEST_DIR .. "/opened"
vim.wait(30000, function() return vim.fn.filereadable(opened) == 1 end, 200)
T.eq(vim.fn.filereadable(opened), 1, "the page was opened")
local html = vim.trim(table.concat(vim.fn.readfile(opened), ""))
T.ok(html:match("%.html$"), "an html page")
T.ok(table.concat(vim.fn.readfile(html), "\n"):find("page output marker", 1, true), "the page holds the output")
