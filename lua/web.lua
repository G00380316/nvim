---TypeScript, TSX, JavaScript and JSX files: syntax highlighting and indent
---from the tree-sitter parsers (the old regex syntax files are poor at JSX),
---fetched once when first needed, and comments that suit the place: `{/* */}`
---between JSX tags, `//` in the code.
local M = {}

local filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" }
local installing = {}

---Highlight and indent the buffer with tree-sitter, if the parser is there.
---@param buf integer
---@param lang string
---@return boolean started
local function start(buf, lang)
    if not vim.api.nvim_buf_is_valid(buf) then return false end
    if not pcall(vim.treesitter.language.add, lang) then return false end
    if not pcall(vim.treesitter.start, buf, lang) then return false end
    vim.api.nvim_buf_call(buf, function()
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end)
    return true
end

local function attach(buf)
    local filetype = vim.bo[buf].filetype
    local lang = vim.treesitter.language.get_lang(filetype)
    if not lang or start(buf, lang) then return end
    -- Not installed: fetch it (it needs the tree-sitter CLI and a C compiler,
    -- which :Deps offers), then start in every buffer that waited for it.
    if installing[lang] then return end
    installing[lang] = true
    local ok, task = pcall(function() return require("nvim-treesitter").install({ lang }) end)
    if not ok or not task then return end
    pcall(function()
        task:await(vim.schedule_wrap(function()
            installing[lang] = nil
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(b) and vim.treesitter.language.get_lang(vim.bo[b].filetype) == lang then
                    start(b, lang)
                end
            end
        end))
    end)
end

-- JSX text and the gaps between tags are not code: `//` there would show up on
-- the page. These are the places where a comment has to be `{/* ... */}`.
local jsx_places = {
    jsx_element = true, jsx_self_closing_element = true, jsx_fragment = true,
    jsx_text = true, jsx_opening_element = false, jsx_expression = false,
}

---Whether a comment on this line belongs between JSX tags.
---@param buf integer
---@param row integer 0-based
---@return boolean
local function in_jsx_children(buf, row)
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if not ok or not parser then return false end
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
    local col = (line:find("%S") or 1) - 1
    local node = vim.treesitter.get_node({ bufnr = buf, pos = { row, col } })
    while node do
        local kind = node:type()
        -- Inside an attribute list or an expression `{ }` it is code again.
        if kind == "jsx_attribute" or kind == "jsx_expression" or kind == "jsx_opening_element"
            or kind == "statement_block" or kind == "arguments" or kind == "parenthesized_expression" and false then
            return false
        end
        if jsx_places[kind] then
            -- The opening tag's own line is inside its element too, but a comment
            -- before a tag belongs among the children.
            return true
        end
        node = node:parent()
    end
    return false
end

---Set 'commentstring' for the lines the comment operator is about to act on.
local function choose_commentstring(buf, first_row)
    vim.bo[buf].commentstring = in_jsx_children(buf, first_row) and "{/* %s */}" or "// %s"
end

function M.setup()
    local group = vim.api.nvim_create_augroup("WebFiles", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = filetypes,
        callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then return end
            attach(args.buf)
            if args.match ~= "typescriptreact" and args.match ~= "javascriptreact" then return end
            -- gc / gcc pick the comment style from where the cursor (or the first
            -- selected line) is; the builtin operator then does the work.
            local comment = require("vim._comment")
            vim.keymap.set({ "n", "x" }, "gc", function()
                local first = vim.fn.mode():match("^[vV\22]") and vim.fn.line("v") - 1 or vim.fn.line(".") - 1
                if vim.fn.mode():match("^[vV\22]") then first = math.min(vim.fn.line("v"), vim.fn.line(".")) - 1 end
                choose_commentstring(args.buf, first)
                return comment.operator()
            end, { buffer = args.buf, expr = true, desc = "Comment (JSX-aware)" })
            vim.keymap.set("n", "gcc", function()
                choose_commentstring(args.buf, vim.fn.line(".") - 1)
                return comment.operator() .. "_"
            end, { buffer = args.buf, expr = true, desc = "Comment line (JSX-aware)" })
        end,
    })
end

return M
