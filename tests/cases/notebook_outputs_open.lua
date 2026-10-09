-- Opening a notebook that has saved outputs shows them under the cells.
local python = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
if vim.fn.executable("jupytext") == 0 or vim.fn.executable(python) == 0 then return end
local nb = vim.json.encode({
    cells = { { cell_type = "code", execution_count = 1, metadata = vim.empty_dict(),
        outputs = { { output_type = "stream", name = "stdout", text = { "saved earlier\n" } } },
        source = { "print('saved earlier')" } } },
    metadata = { kernelspec = { display_name = "Python 3", language = "python", name = "python3" } },
    nbformat = 4, nbformat_minor = 5,
})
vim.cmd("edit " .. T.file("old.ipynb", nb))
local function shown()
    local text = {}
    for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
        local d = m[4]
        for _, l in ipairs(d.virt_lines or {}) do
            for _, c in ipairs(l) do text[#text + 1] = c[1] end
        end
    end
    return table.concat(text, " ")
end
vim.wait(30000, function() return shown():find("saved earlier", 1, true) ~= nil end, 300)
T.ok(shown():find("saved earlier", 1, true), "the saved output is shown on open (saw: " .. shown() .. ")")
