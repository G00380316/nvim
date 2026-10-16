-- Leaving insert mode saves the file, and the toggle turns that off and on.
local path = T.file("a.txt", "one\n")
vim.cmd("edit " .. path)
local autosave = require("autosave")
T.eq(autosave.enabled(), true, "on by default")

local function leave_after_edit(text)
    vim.cmd("startinsert")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
    vim.cmd("doautocmd InsertLeave")
end

leave_after_edit("saved by leaving insert")
T.eq(vim.fn.readfile(path)[1], "saved by leaving insert", "leaving insert saved it")

vim.cmd("AutoSaveToggle")
T.eq(autosave.enabled(), false, "toggled off")
leave_after_edit("not saved")
T.eq(vim.fn.readfile(path)[1], "saved by leaving insert", "with auto-save off, the file is untouched")
T.eq(vim.bo.modified, true, "the buffer is still modified")

-- It is remembered.
T.eq(vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("state") .. "/autosave.json"), "")).on, false, "the choice is stored")

vim.cmd("AutoSaveToggle")
T.eq(autosave.enabled(), true, "toggled back on")
leave_after_edit("saved again")
T.eq(vim.fn.readfile(path)[1], "saved again", "saving works again")
