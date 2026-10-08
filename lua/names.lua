---Short folder names that stay unambiguous.
---
---A folder is shown by its own name -- `W03`, not `~/Library/Mobile Documents/
---.../Labs/exercises/W03`. Two folders that share a name would then look
---identical, so only those get their parent added: `W03 · Labs` and
---`W03 · Archive`, with more parents only if that still is not enough.
local M = {}

local SEP = " \u{b7} "

local function segments(path)
    local parts = {}
    for part in vim.fs.normalize(path):gmatch("[^/]+") do parts[#parts + 1] = part end
    return parts
end

---The label for `path` that tells it apart from every path in `peers`.
---@param path string
---@param peers? string[] other folders that could appear beside it
---@return string
function M.label(path, peers)
    local mine = segments(path)
    if #mine == 0 then return "/" end

    local rivals = {}
    for _, other in ipairs(peers or {}) do
        if vim.fs.normalize(other) ~= vim.fs.normalize(path) then
            local parts = segments(other)
            if parts[#parts] == mine[#mine] then rivals[#rivals + 1] = parts end
        end
    end

    local function suffix(parts, depth)
        local extra = {}
        for i = 1, depth - 1 do
            local part = parts[#parts - i]
            if part then table.insert(extra, 1, part) end
        end
        return table.concat(extra, "/")
    end

    for depth = 1, #mine do
        local mine_tail = suffix(mine, depth)
        local clash = false
        for _, parts in ipairs(rivals) do
            if suffix(parts, depth) == mine_tail then clash = true break end
        end
        if not clash or depth == #mine then
            return mine_tail == "" and mine[#mine] or (mine[#mine] .. SEP .. mine_tail)
        end
    end
    return mine[#mine]
end

---Labels for a whole set at once, keyed by path.
---@param paths string[]
---@return table<string, string>
function M.labels(paths)
    local out = {}
    for _, p in ipairs(paths) do out[p] = M.label(p, paths) end
    return out
end

return M
