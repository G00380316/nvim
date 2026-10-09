-- Tidy removes table padding and keeps the content and alignment.
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "text before",
    "| Task   | What you'll do                                    | Marks |",
    "| ------ | ------------------------------------------------- | ----: |",
    "| **2a** | Perform it                                        |  `10` |",
    "",
    "text after",
})
local n = require("notebook").tidy_tables(0)
local out = vim.api.nvim_buf_get_lines(0, 0, -1, false)
T.ok(n > 0, "something was tidied")
T.eq(out[2], "| Task | What you'll do | Marks |", "header trimmed")
T.eq(out[3], "| --- | --- | ---: |", "divider shortened, alignment kept")
T.eq(out[4], "| **2a** | Perform it | `10` |", "row trimmed")
T.eq(out[1], "text before", "text before untouched")
T.eq(out[6], "text after", "text after untouched")
T.eq(require("notebook").tidy_tables(0), 0, "already tidy: nothing to do")
