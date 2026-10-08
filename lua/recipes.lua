---Editing recipes: the "how do I ..." half of Vim, searchable by what you want
---to do rather than by the key that does it. They are listed in the command
---palette under "Edit", so typing `surround`, `quotes`, `block` or `swap`
---finds them, and Enter does the thing to the word, line or selection you were
---on -- the keys are shown beside each so it sticks.
local M = {}

---@param text string keys, fed as if typed (so this config's own mappings apply)
local function feed(text)
    vim.api.nvim_feedkeys(vim.keycode(text), "m", false)
end

-- ---------------------------------------------------------------- surround

---The `\k\+` word on the current line that holds the cursor.
local function word_bounds()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local from = 0
    while true do
        local _, s, e = unpack(vim.fn.matchstrpos(line, [[\k\+]], from))
        if s < 0 then return nil end
        if col >= s and col < e then return s, e end
        from = e
    end
end

local function wrap_word(left, right)
    return function()
        local s, e = word_bounds()
        if not s then
            vim.notify("The cursor is not on a word", vim.log.levels.WARN, { title = "Edit" })
            return
        end
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.api.nvim_buf_set_text(0, row, e, row, e, { right })
        vim.api.nvim_buf_set_text(0, row, s, row, s, { left })
    end
end

local function wrap_selection(left, right)
    return function()
        local a, b = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        if a[2] == 0 then
            vim.notify("Select something first, then open this", vim.log.levels.WARN, { title = "Edit" })
            return
        end
        local last = vim.api.nvim_buf_get_lines(0, b[2] - 1, b[2], false)[1] or ""
        local end_col = math.min(b[3], #last)
        -- '> points at the first byte of the last character.
        if end_col > 0 then end_col = end_col + (vim.str_utf_end(last, end_col) or 0) end
        if vim.fn.visualmode() == "V" then
            vim.api.nvim_buf_set_text(0, b[2] - 1, #last, b[2] - 1, #last, { right })
            vim.api.nvim_buf_set_text(0, a[2] - 1, 0, a[2] - 1, 0, { left })
        else
            vim.api.nvim_buf_set_text(0, b[2] - 1, end_col, b[2] - 1, end_col, { right })
            vim.api.nvim_buf_set_text(0, a[2] - 1, a[3] - 1, a[2] - 1, a[3] - 1, { left })
        end
    end
end

---The positions {row, col} of the `left` and `right` characters around the
---cursor, innermost pair, or nil.
local function enclosing(left, right)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if left == right then
        local line = vim.api.nvim_get_current_line()
        local open
        for i = 1, #line do
            if line:sub(i, i) == left then
                if open then
                    if col + 1 >= open and col + 1 <= i then return { row, open - 1 }, { row, i - 1 } end
                    open = nil
                else
                    open = i
                end
            end
        end
        return nil
    end
    -- \V: the brackets are literal, whatever they mean to a regex.
    local open, close = "\\V" .. left, "\\V" .. right
    local l = vim.fn.searchpairpos(open, "", close, "bnW")
    local r = vim.fn.searchpairpos(open, "", close, "nW")
    if l[1] == 0 or r[1] == 0 then
        -- On the opening bracket itself the backwards search skips it.
        local line = vim.api.nvim_get_current_line()
        if line:sub(col + 1, col + 1) == left then
            r = vim.fn.searchpairpos(open, "", close, "nW")
            if r[1] ~= 0 then return { row, col }, { r[1], r[2] - 1 } end
        end
        return nil
    end
    return { l[1], l[2] - 1 }, { r[1], r[2] - 1 }
end

local function unwrap(left, right)
    return function()
        local l, r = enclosing(left, right)
        if not l then
            vim.notify(("Not inside %s%s"):format(left, right), vim.log.levels.WARN, { title = "Edit" })
            return
        end
        vim.api.nvim_buf_set_text(0, r[1] - 1, r[2], r[1] - 1, r[2] + 1, {})
        vim.api.nvim_buf_set_text(0, l[1] - 1, l[2], l[1] - 1, l[2] + 1, {})
    end
end

local function rewrap(from_left, from_right, to_left, to_right)
    return function()
        local l, r = enclosing(from_left, from_right)
        if not l then
            vim.notify(("Not inside %s%s"):format(from_left, from_right), vim.log.levels.WARN, { title = "Edit" })
            return
        end
        vim.api.nvim_buf_set_text(0, r[1] - 1, r[2], r[1] - 1, r[2] + 1, { to_right })
        vim.api.nvim_buf_set_text(0, l[1] - 1, l[2], l[1] - 1, l[2] + 1, { to_left })
    end
end

M.wrap_selection = wrap_selection

local pairs_for = {
    ["("] = { "(", ")" }, [")"] = { "(", ")" }, b = { "(", ")" },
    ["["] = { "[", "]" }, ["]"] = { "[", "]" },
    ["{"] = { "{", "}" }, ["}"] = { "{", "}" }, B = { "{", "}" },
    ["<"] = { "<", ">" }, [">"] = { "<", ">" },
    ["*"] = { "**", "**" },
}

---Visual `S`: wrap the selection in the pair for the next key typed. Brackets
---give their pair (b and B too), * gives **bold**, and any other character
---wraps with itself -- quotes, backticks, _, ~.
function M.surround_selection()
    local key = vim.fn.getcharstr()
    if key == "\27" or key == "" then return end
    local pair = pairs_for[key] or { key, key }
    -- Leaving visual mode is what sets the '< and '> marks.
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    wrap_selection(pair[1], pair[2])()
end

-- ----------------------------------------------------------------- recipes

-- { title, keys shown, explanation, action }  -- action: function or key string
local entries = {
    -- Surround
    { "Surround word with double quotes", [[ciw"<C-r>""]], "Wraps the word in place, nothing is deleted: word becomes \"word\"", wrap_word('"', '"') },
    { "Surround word with single quotes", "ciw'<C-r>\"'", "Wraps the word in place: word becomes 'word'", wrap_word("'", "'") },
    { "Surround word with backticks", "ciw`<C-r>\"`", "The word under the cursor becomes `word` (inline code)", wrap_word("`", "`") },
    { "Surround word with parentheses", "ciw(<C-r>\")", "The word under the cursor becomes (word)", wrap_word("(", ")") },
    { "Surround word with square brackets", "ciw[<C-r>\"]", "The word under the cursor becomes [word]", wrap_word("[", "]") },
    { "Surround word with braces", "ciw{<C-r>\"}", "The word under the cursor becomes {word}", wrap_word("{", "}") },
    { "Surround word with bold (markdown)", "ciw**<C-r>\"**", "The word becomes **word**", wrap_word("**", "**") },
    { "Surround selection with double quotes", [[select, then c"<C-r>""]], "Select text first (v), then open this", wrap_selection('"', '"') },
    { "Surround selection with parentheses", "select, then c(<C-r>\")", "Select text first (v), then open this", wrap_selection("(", ")") },
    { "Surround selection with braces", "select, then c{<C-r>\"}", "Select text first (v), then open this", wrap_selection("{", "}") },
    { "Surround selection with square brackets", "select, then c[<C-r>\"]", "Select text first (v), then open this", wrap_selection("[", "]") },
    { "Remove the double quotes around the cursor", [[di" then P]], "\"word\" becomes word", unwrap('"', '"') },
    { "Remove the single quotes around the cursor", "di' then P", "'word' becomes word", unwrap("'", "'") },
    { "Remove the parentheses around the cursor", "di( then P", "(text) becomes text", unwrap("(", ")") },
    { "Remove the braces around the cursor", "di{ then P", "{text} becomes text", unwrap("{", "}") },
    { "Remove the square brackets around the cursor", "di[ then P", "[text] becomes text", unwrap("[", "]") },
    { "Change double quotes to single quotes", [[cs"' (surround)]], "\"text\" becomes 'text'", rewrap('"', '"', "'", "'") },
    { "Change single quotes to double quotes", [[cs'" (surround)]], "'text' becomes \"text\"", rewrap("'", "'", '"', '"') },
    { "Change parentheses to square brackets", "cs([ (surround)", "(text) becomes [text]", rewrap("(", ")", "[", "]") },
    { "Change square brackets to parentheses", "cs[( (surround)", "[text] becomes (text)", rewrap("[", "]", "(", ")") },

    -- Blocks: the text between a pair of brackets, quotes or tags
    { "Select inside braces", "vi{", "The body of a { } block, without the braces", "vi{" },
    { "Select a whole braces block", "va{", "A { } block including the braces", "va{" },
    { "Select inside parentheses", "vi(", "Everything between ( and )", "vi(" },
    { "Select inside quotes", 'vi"', "The text between a pair of quotes", 'vi"' },
    { "Select inside a tag", "vit", "The content of an HTML / XML tag", "vit" },
    { "Select a whole paragraph", "vap", "Up to the next blank line", "vap" },
    { "Delete inside braces", "di{", "Empty a { } block, keep the braces", "di{" },
    { "Change inside braces", "ci{", "Replace a block's body; ends in insert mode", "ci{" },
    { "Change inside parentheses", "ci(", "Replace call arguments or a condition", "ci(" },
    { "Change inside quotes", 'ci"', "Replace a string's text; ends in insert mode", 'ci"' },
    { "Delete a whole braces block", "da{", "Remove a { } block with its braces", "da{" },
    { "Yank inside braces", "yi{", "Copy a block's body", "yi{" },
    { "Yank a paragraph", "yap", "Copy up to the next blank line", "yap" },
    { "Indent a block", ">i{", "Shift a { } block's body right", ">i{" },
    { "Re-indent a block", "=i{", "Fix the indentation of a { } block", "=i{" },
    { "Fold a block", "zfa{", "Collapse a { } block; zo opens it, zc closes it", "zfa{" },
    { "Comment a block", "gcap", "Toggle comments over the paragraph", "gcap" },
    { "Jump to the matching bracket", "%", "From a ( [ { to its partner, and back", "%" },

    -- Lines
    { "Comment or uncomment the line", "gcc", "Toggle a comment on the line", "gcc" },
    { "Duplicate the line", ":t.", "Copy the line to just below it", ":t.<CR>" },
    { "Swap this line with the one below", ":m .+1", "Move the line down one", ":m .+1<CR>==" },
    { "Move the line up", ":m .-2", "Move the line up one", ":m .-2<CR>==" },
    { "Move the line down", ":m .+1", "Move the line down one", ":m .+1<CR>==" },
    { "Delete the line", "dd", "Remove the whole line", "dd" },
    { "Delete to the end of the line", "D", "From the cursor to the end", "D" },
    { "Join with the next line", "J", "Pull the next line up onto this one", "J" },
    { "Open a line below", "o", "New line under, in insert mode", "o" },
    { "Open a line above", "O", "New line over, in insert mode", "O" },
    { "Indent the line", ">>", "Shift the line right", ">>" },
    { "Outdent the line", "<<", "Shift the line left", "<<" },

    -- Words and text
    { "Change the word", "ciw", "Replace the word under the cursor", "ciw" },
    { "Delete the word", "diw", "Remove the word under the cursor", "diw" },
    { "Uppercase the word", "gUiw", "word becomes WORD", "gUiw" },
    { "Lowercase the word", "guiw", "WORD becomes word", "guiw" },
    { "Capitalise the word", "~", "Flip the case of the letter under the cursor", "~" },
    { "Swap two characters", "xp", "Fix a typo like teh -> the", "xp" },
    { "Increment the number", "<C-a>", "Add one to the number at the cursor", "<C-a>" },
    { "Decrement the number", "<C-x>", "Subtract one", "<C-x>" },

    -- Whole file
    { "Select everything", "ggVG", "Select the whole file", "ggVG" },
    { "Re-indent the whole file", "gg=G", "Fix all the indentation", "gg=G" },
    { "Sort the lines", ":sort", "Sort a selection, or the file with :%sort", ":%sort<CR>" },
    { "Remove blank lines", ":g/^$/d", "Delete every empty line", ":g/^$/d<CR>" },
    { "Remove trailing spaces", ":%s/\\s\\+$//e", "Strip spaces from line ends", ":%s/\\s\\+$//e<CR>" },
    { "Wrap long lines to a paragraph", "gqap", "Reflow the paragraph to textwidth", "gqap" },
    { "Edit a column of text", "<C-v> then I", "Select a column with <C-v> and j, then I types on every line", "<C-v>" },
}

---Palette rows: group, label, key, detail, run.
function M.items()
    local out = {}
    for _, e in ipairs(entries) do
        local action = e[4]
        out[#out + 1] = {
            group = "Edit",
            label = e[1],
            key = e[2],
            detail = e[3],
            run = type(action) == "function" and action or function() feed(action) end,
        }
    end
    return out
end

return M
