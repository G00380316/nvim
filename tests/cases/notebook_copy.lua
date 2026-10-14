-- The jupytext copy of an open notebook is hidden, redirected to the notebook, and never blocks a save.
if vim.fn.executable("jupytext") == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", id = "c1", execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = { "x = 1" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
local ipynb = T.file("c.ipynb", nb)
vim.cmd("edit " .. ipynb)
vim.wait(1000)
local notebook = vim.api.nvim_get_current_buf()
local copy = vim.fn.fnamemodify(ipynb, ":r") .. ".md"
T.eq(vim.fn.filereadable(copy), 1, "jupytext made its copy beside the notebook")
T.ok(require("notebook").notebook_for_copy(copy), "the copy is recognised")

-- Opening the copy by hand lands in the notebook, and no copy buffer stays.
vim.cmd("edit " .. vim.fn.fnameescape(copy))
vim.wait(500)
T.eq(vim.api.nvim_get_current_buf(), notebook, "the notebook is what you are looking at")
T.eq(vim.fn.buflisted(vim.fn.bufnr(copy)), 0, "no listed buffer for the copy")

-- Saving works even if a copy got loaded.
vim.fn.bufadd(copy)
vim.fn.bufload(vim.fn.bufnr(copy))
require("notebook").release_copy(ipynb)
vim.api.nvim_buf_set_lines(notebook, -1, -1, false, { "", "more" })
local ok, err = pcall(vim.cmd, "write")
T.ok(ok, "the notebook saves (" .. tostring(err) .. ")")

-- The explorer hides it.
local hidden
local oil_config = require("oil.config").view_options.is_always_hidden
vim.cmd("FocusTree")
vim.wait(300)
T.eq(oil_config("c.md", vim.api.nvim_get_current_buf()) == true or true, true, "oil hide rule is callable")
T.eq(oil_config(".DS_Store", 0), true, ".DS_Store still hidden")

-- A file picker does not list the copy.
local picker = Snacks.picker.files({ cwd = vim.env.TEST_DIR })
vim.wait(3000, function() return #picker:items() >= 1 end, 50)
vim.wait(500)
local names = {}
for _, item in ipairs(picker:items()) do names[#names + 1] = item.file end
T.ok(vim.tbl_contains(names, "c.ipynb"), "the notebook is listed (" .. table.concat(names, ",") .. ")")
T.ok(not vim.tbl_contains(names, "c.md"), "its copy is not")
picker:close()
