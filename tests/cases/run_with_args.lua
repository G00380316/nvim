-- Run with arguments sends them after the file, from a buffer or the explorer.
local path = T.file("greet.py", "import sys\nprint('ARGS:', *sys.argv[1:])\n")
vim.cmd("edit " .. path)
local runner = require("runner")
runner.run("run", { args = "alpha 'two words'" })
vim.wait(2500, function()
    for _, b in ipairs(require("terminals").list()) do
        local text = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
        if text:find("ARGS: alpha two words", 1, true) then return true end
    end
end, 100)
local found = false
for _, b in ipairs(require("terminals").list()) do
    local text = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\n")
    if text:find("ARGS: alpha two words", 1, true) then found = true end
end
T.ok(found, "arguments reached the program")

-- From the explorer: the entry under the cursor.
vim.cmd("FocusTree")
vim.wait(500)
local ok, oil = pcall(require, "oil")
T.ok(ok, "oil available")
for line = 1, vim.api.nvim_buf_line_count(0) do
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    local entry = oil.get_cursor_entry()
    if entry and entry.name == "greet.py" then break end
end
local seen
vim.ui.input = function(opts, cb) seen = opts.prompt; cb("--flag") end
vim.cmd("RunWith")
vim.wait(2000, function() return seen ~= nil end, 50)
T.ok(seen and seen:find("greet.py", 1, true), "explorer entry was asked about (" .. tostring(seen) .. ")")

-- From a file picker: <C-x> hands the highlighted file over.
local asked
vim.ui.input = function(opts, cb) asked = opts.prompt; cb("") end
local picker = Snacks.picker.files({ cwd = vim.env.TEST_DIR, pattern = "greet" })
vim.wait(2000, function() return picker:current() ~= nil end, 50)
T.ok(picker:current(), "picker found the file")
picker:action("run_with_args")
vim.wait(2000, function() return asked ~= nil end, 50)
T.ok(asked and asked:find("greet.py", 1, true), "picker action asked about the file (" .. tostring(asked) .. ")")
