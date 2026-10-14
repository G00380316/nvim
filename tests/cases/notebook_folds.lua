-- Notebook folds: the header, each region and each code cell fold with the usual keys.
if vim.fn.executable("jupytext") == 0 then return end
local nb = vim.json.encode({
    cells = {
        { cell_type = "markdown", id = "aaa111", metadata = vim.empty_dict(), source = { "# Title\n", "text" } },
        { cell_type = "code", id = "bbb222", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "x = 1\n", "print(x)" } },
    },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("f.ipynb", nb))
vim.wait(1500)

local function level(lnum) return vim.fn.foldlevel(lnum) end
T.eq(vim.wo.foldmethod, "expr", "folding by expression")
T.ok(level(1) >= 1 and level(4) >= 1, "header lines are in a fold")
T.eq(vim.fn.foldclosed(1) ~= -1, true, "the header starts closed")
-- A region, then a code cell, are each their own fold.
local region = vim.fn.search("<!-- #region", "nw")
local fence = vim.fn.search("```python", "nw")
if region > 0 then T.ok(level(region) >= 1, "region folds") end
T.ok(fence > 0 and level(fence) >= 1, "code cell folds")
vim.api.nvim_win_set_cursor(0, { fence + 1, 0 })
vim.cmd("normal! zc")
T.ok(vim.fn.foldclosed(fence + 1) ~= -1, "zc closes the code cell the cursor is in")
vim.cmd("normal! zo")
T.eq(vim.fn.foldclosed(fence + 1), -1, "zo opens it again")

-- Region blocks, from the expression itself.
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "<!-- #region id=\"x\" -->", "# Hello", "<!-- #endregion -->", "", "```python", "a = 1", "```",
})
local expr = require("notebook").foldexpr
T.eq({ expr(1), expr(2), expr(3), expr(4) }, { ">1", "1", "1", "0" }, "a region is one fold")
T.eq({ expr(5), expr(6), expr(7) }, { ">1", "1", "1" }, "a code cell is one fold")
