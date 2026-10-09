---Which actions you ran lately, so menus and the palette can put them near the
---top. Kept in the state directory and shared by every Neovim instance.
local M = {}

local file = vim.fn.stdpath("state") .. "/recent-actions.json"
local MAX = 200
local WINDOW = 30 * 24 * 3600 -- a month

local cache

local function load()
    cache = {}
    if vim.fn.filereadable(file) ~= 1 then return end
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if ok and type(data) == "table" then cache = data end
end

local function save()
    local entries = {}
    for key, t in pairs(cache) do entries[#entries + 1] = { key, t } end
    table.sort(entries, function(a, b) return a[2] > b[2] end)
    local keep = {}
    for i = 1, math.min(MAX, #entries) do keep[entries[i][1]] = entries[i][2] end
    cache = keep
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode(keep) }, file)
end

---@param group string a menu title or palette group
---@param label string
---@return string
function M.key(group, label)
    -- "Git Actions" the menu and "Git" the palette group are the same place.
    return (group:gsub("%s*Actions$", "")) .. "|" .. label
end

function M.record(key)
    -- Re-read first so another instance's history is merged, not overwritten.
    load()
    cache[key] = os.time()
    save()
end

---When this was last run, or 0 if never or long ago.
---@param key string
---@return integer
function M.last_used(key)
    if not cache then load() end
    local t = cache[key]
    if t and os.time() - t < WINDOW then return t end
    return 0
end

return M
