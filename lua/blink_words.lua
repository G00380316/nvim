---A blink.cmp source that completes English words from the system dictionary.
---It is what makes prose suggestions "proper": typing `beaut` offers `beautiful`
---and `beauty`, not only what happens to be written in the open files. Only used
---in notes and text (see the per_filetype lists in lsp.lua).
local M = {}

local WORDS = "/usr/share/dict/words"
local words ---@type string[]?

---The dictionary, lowercased and sorted, read once when first asked.
local function load()
    if words then return words end
    words = {}
    if vim.fn.filereadable(WORDS) ~= 1 then return words end
    local seen = {}
    for _, word in ipairs(vim.fn.readfile(WORDS)) do
        local lower = word:lower()
        -- Proper nouns and abbreviations appear lowercased and capitalised;
        -- keep each word once.
        if not seen[lower] and lower:match("^%a+$") and #lower > 2 then
            seen[lower] = true
            words[#words + 1] = lower
        end
    end
    table.sort(words)
    return words
end

---Up to `limit` dictionary words starting with `prefix`, shortest first.
---@param prefix string lowercase
---@param limit integer
function M.lookup(prefix, limit)
    local list = load()
    -- Binary search for the first word >= prefix.
    local low, high = 1, #list + 1
    while low < high do
        local mid = math.floor((low + high) / 2)
        if list[mid] < prefix then low = mid + 1 else high = mid end
    end
    local found = {}
    local i = low
    while list[i] and list[i]:sub(1, #prefix) == prefix and #found < 200 do
        if list[i] ~= prefix then found[#found + 1] = list[i] end
        i = i + 1
    end
    table.sort(found, function(a, b)
        if #a ~= #b then return #a < #b end
        return a < b
    end)
    return vim.list_slice(found, 1, limit)
end

function M.new() return setmetatable({}, { __index = M }) end

function M:get_completions(ctx, callback)
    local before = ctx.line:sub(1, ctx.cursor[2])
    local typed = before:match("[%a]+$")
    if not typed or #typed < 3 then
        callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
        return function() end
    end

    -- Keep the way it was started: `Beaut` completes to `Beautiful`, `BEAUT`
    -- to `BEAUTIFUL`.
    local function as_typed(word)
        if typed:upper() == typed and #typed > 1 then return word:upper() end
        if typed:sub(1, 1):upper() == typed:sub(1, 1) then return word:sub(1, 1):upper() .. word:sub(2) end
        return word
    end

    local items = {}
    for _, word in ipairs(M.lookup(typed:lower(), 15)) do
        local text = as_typed(word)
        items[#items + 1] = {
            label = text,
            kind = require("blink.cmp.types").CompletionItemKind.Text,
            insertText = text,
            filterText = text,
        }
    end
    callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
    return function() end
end

return M
