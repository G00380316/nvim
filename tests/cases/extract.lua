-- :Extract unpacks an archive next to itself.
local f = T.file("src/a.txt", "hi\n")
vim.fn.system({ "tar", "czf", vim.env.TEST_DIR .. "/a.tar.gz", "-C", vim.env.TEST_DIR .. "/src", "a.txt" })
os.remove(f)
local out = vim.env.TEST_DIR .. "/a.txt"
vim.cmd("edit " .. vim.env.TEST_DIR .. "/a.tar.gz")
vim.cmd("Extract")
vim.wait(2500, function() return vim.fn.filereadable(out) == 1 end, 50)
T.eq(vim.fn.filereadable(out), 1, "archive contents extracted")
