-- After <Esc> part-way through a snippet, <C-Space> in normal mode fills the next placeholder.
vim.cmd("edit " .. T.file("s.py", ""))
vim.cmd("startinsert")
vim.wait(100)
vim.snippet.expand("foo ${1:one} bar ${2:two} baz")
vim.wait(100)
T.ok(vim.snippet.active(), "snippet active")
vim.cmd("stopinsert")
vim.wait(300)
T.ok(vim.snippet.active({ direction = 1 }), "session kept: placeholders are still ahead")

-- The key itself is exercised in a real terminal (it selects the next
-- placeholder with queued keys, which a headless run does not play out); here,
-- that it is bound and does not end the session.
local map = vim.fn.maparg("<C-Space>", "n", false, true)
T.ok((map.desc or ""):find("snippet placeholder", 1, true), "<C-Space> is the fill key")
T.eq(pcall(map.callback), true, "the key runs without error")
T.ok(vim.snippet.active(), "session still active after jumping")

-- <leader>c abandons it.
vim.cmd("stopinsert")
vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
vim.wait(300)
vim.fn.maparg("<leader>c", "n", false, true).callback()
T.ok(not vim.snippet.active(), "<leader>c ends the snippet")
