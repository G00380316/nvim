-- Opening externally hands the file to `open`; audio and design files open themselves.
local bin = T.file("bin/open", '#!/bin/sh\necho "$@" >> "$TEST_DIR/opened"\n')
vim.fn.system({ "chmod", "+x", bin })
vim.env.PATH = vim.fn.fnamemodify(bin, ":h") .. ":" .. vim.env.PATH

local csv = T.file("a.csv", "a,b\n")
vim.cmd("edit " .. csv)
vim.cmd("OpenExternally")
vim.wait(1500, function() return vim.fn.filereadable(vim.env.TEST_DIR .. "/opened") == 1 end, 50)
T.eq(vim.fn.filereadable(vim.env.TEST_DIR .. "/opened"), 1, "open was called for the csv")

vim.cmd("edit " .. csv)
local sound = T.file("s.mp3", "x")
vim.cmd("edit " .. sound)
vim.wait(800)
T.ok(vim.fn.bufname("%") ~= sound, "audio file did not stay open as a buffer")
