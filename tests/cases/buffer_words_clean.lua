-- Random-looking tokens from other buffers are not offered as words; real words are.
local transform = require("blink.cmp.config").sources.providers.buffer.transform_items
T.eq(type(transform), "function", "buffer words are filtered")

local function labels(items)
    local out = {}
    for _, item in ipairs(items) do out[#out + 1] = item.label end
    return out
end
local function offered(words)
    local items = {}
    for _, w in ipairs(words) do items[#items + 1] = { label = w } end
    return labels(transform({}, items))
end

vim.cmd("edit " .. T.file("n.md", "x"))
T.eq(vim.bo.filetype, "markdown", "in a note")
T.eq(
    offered({ "BhmyIodzHagxrTf_ddbGgCJQ2VJFy6KuZncfwUuDz8mOGpzrEioWSXoUBDP", "token9abc12", "perfect", "getUserName", "NASA", "don't" }),
    { "perfect", "NASA", "don't" },
    "ids, mixed tokens and camelCase dropped in prose; words and acronyms kept"
)

vim.cmd("edit " .. T.file("c.py", "x = 1\n"))
T.eq(
    offered({ "BhmyIodzHagxrTf_ddbGgCJQ2VJFy6KuZncfwUuDz8mOGpzrEioWSXoUBDP", "get_user_name", "result", "x1" }),
    { "get_user_name", "result", "x1" },
    "in code comments names stay, only blobs go"
)
