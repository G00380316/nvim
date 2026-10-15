---Whether `_` and `-` are part of a word. With them out, w b e and the text
---objects (ciw, daw, *) treat snake_case and kebab-case as several words, each
---motion stopping at the separator; with them in, an identifier is one word.
---Split is the default. Neovim's own default has `_` in and `-` out, and filetype
---plugins add `-` for CSS, Lisp, shell and others, so the setting is applied
---again after each filetype loads.
local M = {}

local split = true

local function apply(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local value = vim.bo[buf].iskeyword
    local parts = vim.split(value, ",", { plain = true })
    local out = {}
    for _, part in ipairs(parts) do
        local is_sep = part == "_" or part == "-"
        if split and not is_sep then out[#out + 1] = part end
        if not split and part ~= "" then out[#out + 1] = part end
    end
    if not split then
        local have = {}
        for _, part in ipairs(out) do have[part] = true end
        for _, ch in ipairs({ "_", "-" }) do
            if not have[ch] then out[#out + 1] = ch end
        end
    end
    vim.bo[buf].iskeyword = table.concat(out, ",")
end

local function apply_all()
    -- The default for buffers yet to be made, then every one that exists.
    local default = vim.split(vim.o.iskeyword, ",", { plain = true })
    local out = {}
    for _, part in ipairs(default) do
        if part ~= "" and not (split and (part == "_" or part == "-")) then out[#out + 1] = part end
    end
    if not split then
        for _, ch in ipairs({ "_", "-" }) do
            if not vim.tbl_contains(out, ch) then out[#out + 1] = ch end
        end
    end
    vim.o.iskeyword = table.concat(out, ",")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do apply(buf) end
end

function M.is_split() return split end

function M.set(value)
    split = value
    apply_all()
end

function M.setup()
    apply_all()
    vim.api.nvim_create_autocmd({ "FileType", "BufNewFile", "BufReadPost" }, {
        group = vim.api.nvim_create_augroup("WordMotions", { clear = true }),
        callback = function(args) apply(args.buf) end,
        desc = "Keep _ and - as word separators after a filetype plugin sets iskeyword",
    })
    vim.api.nvim_create_user_command("WordSplit", function() M.set(true) end, {
        desc = "w, b, e and ciw stop at _ and - (snake_case is several words)",
    })
    vim.api.nvim_create_user_command("WordJoin", function() M.set(false) end, {
        desc = "w, b, e and ciw treat snake_case and kebab-case as one word",
    })
end

return M
