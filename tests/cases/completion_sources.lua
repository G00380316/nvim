-- Prose files complete from snippets and buffer words; personal snippets load.
local cfg = require("blink.cmp.config").sources
T.ok(vim.tbl_contains(cfg.per_filetype.markdown, "buffer"), "markdown completes from buffer words")
T.ok(vim.tbl_contains(cfg.per_filetype.text, "buffer"), "text completes from buffer words")
T.ok(vim.tbl_contains(cfg.per_filetype.markdown, "snippets"), "markdown has snippets")
for _, f in ipairs({ "markdown.json", "text.json" }) do
    local path = vim.fn.stdpath("config") .. "/snippets/" .. f
    T.ok(pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n")), f .. " is valid JSON")
end
