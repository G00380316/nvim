-- Prose completes from the dictionary and no longer asks the language server.
local cfg = require("blink.cmp.config").sources
T.ok(vim.tbl_contains(cfg.per_filetype.markdown, "words"), "markdown offers dictionary words")
T.ok(not vim.tbl_contains(cfg.per_filetype.markdown, "lsp"), "markdown no longer uses the language server")
T.ok(not vim.tbl_contains(cfg.per_filetype.text, "lsp"), "text has no language server")

if vim.fn.filereadable("/usr/share/dict/words") == 1 then
    local words = require("blink_words").lookup("beaut", 15)
    T.ok(vim.tbl_contains(words, "beautiful"), "beaut -> beautiful (" .. table.concat(words, ",") .. ")")
    local got
    require("blink_words").new():get_completions({ line = "I saw a Beaut", cursor = { 1, 13 } }, function(r) got = r end)
    T.ok(got and got.items[1] and got.items[1].label:sub(1, 1) == "B", "capital kept")
end
