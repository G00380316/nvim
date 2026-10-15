-- zip files run (extract) and can be navigated back out of.
local zip = vim.env.TEST_DIR .. "/t.zip"
T.file("src/a.txt", "hello\n")
vim.fn.system({ "sh", "-c", ("cd %s/src && zip -q %s a.txt"):format(vim.env.TEST_DIR, zip) })
T.eq(vim.fn.filereadable(zip), 1, "a zip to work with")

T.ok(require("runner").runners.run.extensions.zip, "run knows zip files")

-- Opening an entry, then going back up to the listing, then out.
vim.cmd("edit " .. zip)
local listing = vim.api.nvim_get_current_buf()
T.eq(vim.bo[listing].filetype, "zip", "the zip opens as a listing")
T.ok((vim.fn.maparg("-", "n", false, true).desc or ""):find("Back out", 1, true), "- backs out of the listing")

vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("normal \r")
vim.wait(500)
local entry = vim.api.nvim_get_current_buf()
T.ok(vim.api.nvim_buf_get_name(entry):match("^zip://"), "an entry buffer (" .. vim.api.nvim_buf_get_name(entry) .. ")")
vim.fn.maparg("-", "n", false, true).callback()
vim.wait(300)
T.eq(vim.api.nvim_get_current_buf(), listing, "- from an entry goes back to the listing")
