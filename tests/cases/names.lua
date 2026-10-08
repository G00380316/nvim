-- Folders show by their own name; only clashing names grow a parent.
local names = require("names")
local a, b, c = "/x/Labs/W03", "/x/Archive/W03", "/x/Labs/W04"
local peers = { a, b, c }
T.eq(names.label(c, peers), "W04", "unique name stays bare")
T.eq(names.label(a, peers), "W03 \u{b7} Labs", "clash gets its parent")
T.eq(names.label(b, peers), "W03 \u{b7} Archive", "other side of the clash")
T.eq(names.label("/x/Labs/W03", { "/y/Labs/W03" }), "W03 \u{b7} x/Labs", "deeper clash goes further up")

-- workspace labels use the history as the peers
local ws = require("workspace")
local d1, d2 = T.file("one/proj/f"), T.file("two/proj/f")
ws.set(vim.env.TEST_DIR .. "/one/proj", { exact = true })
T.eq(ws.label(vim.env.TEST_DIR .. "/one/proj"), "proj", "alone it is just its name")
ws.set(vim.env.TEST_DIR .. "/two/proj", { exact = true })
T.eq(ws.label(vim.env.TEST_DIR .. "/one/proj"), "proj \u{b7} one", "a second proj makes both ambiguous")
