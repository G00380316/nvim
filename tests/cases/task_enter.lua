-- In prose no suggestion is pre-selected, so <CR> goes to the list/task continuation;
-- in code the first match is still chosen.
local selection = require("blink.cmp.config").completion.list.selection
vim.cmd("edit " .. T.file("t.md", "- [ ] a task\n"))
T.eq(selection.preselect(), false, "markdown: nothing pre-selected")
vim.cmd("edit " .. T.file("c.py", "x = 1\n"))
T.eq(selection.preselect(), true, "python: first match pre-selected")

-- And the continuation itself is bound in a note.
vim.cmd("edit " .. T.file("n.md", "- [ ] a task\n"))
local map = vim.fn.maparg("<CR>", "i", false, true)
T.ok(map.buffer == 1 and (map.desc or ""):find("Continue the Markdown list", 1, true), "<CR> continues lists in a note")
