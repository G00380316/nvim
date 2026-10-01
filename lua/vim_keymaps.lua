local M = {}

-- Vim's own keys, which are not mappings and so cannot be found by
-- <leader>K: nothing in the keymap tables knows that `caw` changes a word or
-- that `g;` walks back through your edits. They are written down here instead.
--
-- Every row is checked against this config's real mappings when the list is
-- drawn. That is the point of having it: `zh` scrolls sideways in Vim and
-- splits a window here, `d` goes to the black hole, `s` flashes rather than
-- substitutes. A reference that did not say so would be worse than none.
--
-- {placeholders} stand for something you type next -- a motion, a char, a
-- register -- and are stripped before anything is looked up or opened.
local entries = {
    -- Motions
    { "Motions", "h j k l", "Left, down, up, right", "h" },
    { "Motions", "w / W", "Start of the next word / WORD" },
    { "Motions", "e / E", "End of this word / WORD" },
    { "Motions", "b / B", "Back to the start of a word / WORD" },
    { "Motions", "ge / gE", "Back to the end of the previous word / WORD" },
    { "Motions", "0", "First column of the line" },
    { "Motions", "^", "First non-blank of the line" },
    { "Motions", "$", "End of the line" },
    { "Motions", "g_", "Last non-blank of the line" },
    { "Motions", "f{char} / F{char}", "Onto the next / previous occurrence of a char", "f" },
    { "Motions", "t{char} / T{char}", "Up to just before the next / previous char", "t" },
    { "Motions", "; / ,", "Repeat / reverse the last f t F T" },
    { "Motions", "{ / }", "Previous / next blank line (paragraph)" },
    { "Motions", "( / )", "Previous / next sentence" },
    { "Motions", "gg / G", "First / last line of the file" },
    { "Motions", "{count}G", "Jump to a line number", "G" },
    { "Motions", "%", "To the bracket that matches this one" },
    { "Motions", "H M L", "Top, middle, bottom line on screen", "H" },
    { "Motions", "|", "To a screen column" },
    { "Motions", "{count}|", "To column {count}", "|" },

    -- Operators: a verb, then any motion or text object above
    { "Operators", "d{motion}", "Delete over a motion", "d" },
    { "Operators", "c{motion}", "Change over a motion", "c" },
    { "Operators", "y{motion}", "Yank over a motion", "y" },
    { "Operators", ">{motion} / <{motion}", "Indent / outdent over a motion", ">" },
    { "Operators", "={motion}", "Re-indent over a motion", "=" },
    { "Operators", "gu{motion} / gU{motion}", "Lowercase / uppercase over a motion", "gu" },
    { "Operators", "g~{motion}", "Swap case over a motion", "g~" },
    { "Operators", "gq{motion}", "Wrap lines to textwidth", "gq" },
    { "Operators", "!{motion}", "Filter lines through a shell command", "!" },
    { "Operators", "zf{motion}", "Make a fold over a motion", "zf" },
    { "Operators", "dd cc yy", "The same three on whole lines", "dd" },
    { "Operators", "D C Y", "The same three to the end of the line", "D" },
    { "Operators", "x / X", "Delete the char under / before the cursor", "x" },
    { "Operators", "s / S", "Substitute the char / the whole line", "s" },
    { "Operators", "r{char}", "Replace one char without leaving normal mode", "r" },
    { "Operators", "R", "Replace mode: type over what is there" },
    { "Operators", "~", "Swap the case of one char" },
    { "Operators", "J / gJ", "Join the next line on, with / without a space", "J" },
    { "Operators", ".", "Repeat the last change" },
    { "Operators", "u / <C-r>", "Undo / redo", "u" },
    { "Operators", "U", "Undo every change on the last line touched" },
    { "Operators", "<C-a> / <C-x>", "Increment / decrement the number at or after the cursor", "<C-a>" },

    -- Text objects: use after an operator, or in visual mode
    { "Text objects", "iw / aw", "Inner word / a word and its space", "iw" },
    { "Text objects", "iW / aW", "The same for WORDs (space-separated)", "iW" },
    { "Text objects", "is / as", "Inner / a sentence", "is" },
    { "Text objects", "ip / ap", "Inner / a paragraph", "ip" },
    { "Text objects", "i\" a\" i' a'", "Inside / including the quotes", "i\"" },
    { "Text objects", "i( a( or ib ab", "Inside / including the parentheses", "ib" },
    { "Text objects", "i{ a{ or iB aB", "Inside / including the braces", "iB" },
    { "Text objects", "i[ a[", "Inside / including the square brackets", "i[" },
    { "Text objects", "i< a<", "Inside / including the angle brackets", "i<" },
    { "Text objects", "it / at", "Inside / including an HTML or XML tag", "it" },
    { "Text objects", "caw ciw diw", "Worked examples: change a word, change in word, delete in word", "iw" },

    -- Visual mode
    { "Visual", "v / V / <C-v>", "Select by character / line / block", "v" },
    { "Visual", "gv", "Reselect whatever was selected last" },
    { "Visual", "o", "Jump to the other end of the selection", "v_o" },
    { "Visual", "I / A", "In a block selection, insert at the start / end of every line", "v_b_I" },
    { "Visual", "$", "In a block selection, run to the end of every line", "visual-block" },
    { "Visual", "u / U / ~", "Lowercase / uppercase / swap case the selection", "v_u" },
    { "Visual", "gq", "Wrap the selection to textwidth", "v_gq" },
    { "Visual", ":", "Start a command already ranged to the selection", "v_:" },
    { "Visual", "g<C-a>", "Turn a selected column of numbers into a sequence", "v_g_CTRL-A" },

    -- Registers
    { "Registers", "\"{reg}y / \"{reg}p", "Yank into / paste from a named register", "quote" },
    { "Registers", "\"+ / \"*", "The system clipboard", "quoteplus" },
    { "Registers", "\"_", "The black hole: delete without touching any register", "quote_" },
    { "Registers", "\"0", "The last thing yanked, whatever was deleted since", "quote0" },
    { "Registers", "\"%", "The name of the current file", "quote%" },
    { "Registers", ":registers", "Show what is in every register", ":registers" },
    { "Registers", "p / P", "Paste after / before the cursor", "p" },
    { "Registers", "gp / gP", "Paste and leave the cursor after it", "gp" },
    { "Registers", "]p", "Paste adjusted to the current indent", "]p" },

    -- Marks and jumps
    { "Marks", "m{a-z}", "Set a mark in this file", "m" },
    { "Marks", "m{A-Z}", "Set a mark that remembers its file too", "m" },
    { "Marks", "`{mark}", "Jump to a mark, exact column", "`" },
    { "Marks", "'{mark}", "Jump to a mark's line, first non-blank", "'" },
    { "Marks", "`` / ''", "Back to where you were before the last jump", "``" },
    { "Marks", ":marks", "Show every mark", ":marks" },
    { "Marks", "<C-o> / <C-i>", "Back / forward through the jumplist", "CTRL-O" },
    { "Marks", ":jumps", "Show the jumplist", ":jumps" },
    { "Marks", "g; / g,", "Back / forward through the places you edited", "g;" },
    { "Marks", "gi", "Insert again exactly where you last left insert mode", "gi" },
    { "Marks", "`.", "Jump to the position of your last change", "`." },
    { "Marks", "<C-^>", "Back to the file you were in before this one", "CTRL-^" },

    -- Search and substitute
    { "Search", "/ / ?", "Search forward / backward", "/" },
    { "Search", "n / N", "Next / previous match" },
    { "Search", "* / #", "Search for the whole word under the cursor, forward / back", "star" },
    { "Search", "g* / g#", "The same, matching inside longer words", "gstar" },
    { "Search", ":noh", "Stop highlighting the current match", ":nohlsearch" },
    { "Search", ":%s/old/new/g", "Replace through the whole file", ":s" },
    { "Search", ":%s/old/new/gc", "The same, confirming each one", ":s_c" },
    { "Search", "&", "Repeat the last substitute on this line", "&" },
    { "Search", ":g/pat/d", "Run a command on every matching line", ":global" },
    { "Search", ":v/pat/d", "Run a command on every line that does not match", ":vglobal" },

    -- Scrolling
    { "Scrolling", "<C-d> / <C-u>", "Down / up half a screen", "CTRL-D" },
    { "Scrolling", "<C-f> / <C-b>", "Forward / back a whole screen", "CTRL-F" },
    { "Scrolling", "<C-e> / <C-y>", "Scroll one line down / up", "CTRL-E" },
    { "Scrolling", "zz / zt / zb", "Put this line in the middle / at the top / at the bottom", "zz" },
    { "Scrolling", "zh / zl", "Scroll sideways one column", "zh" },

    -- Folds
    { "Folds", "za / zA", "Toggle this fold / and everything nested in it", "za" },
    { "Folds", "zo / zO", "Open this fold / and everything nested in it", "zo" },
    { "Folds", "zc / zC", "Close this fold / and everything nested in it", "zc" },
    { "Folds", "zR / zM", "Open every fold / close every fold", "zR" },
    { "Folds", "zj / zk", "To the start of the next / end of the previous fold", "zj" },

    -- Macros
    { "Macros", "q{reg}", "Start recording into a register", "q" },
    { "Macros", "q", "Stop recording", "q" },
    { "Macros", "@{reg}", "Play a recording back", "@" },
    { "Macros", "@@", "Play the last one again", "@@" },
    { "Macros", "{count}@{reg}", "Play it back {count} times", "@" },

    -- Insert mode
    { "Insert", "<C-w> / <C-u>", "Delete the word / everything before the cursor", "i_CTRL-W" },
    { "Insert", "<C-o>", "One normal-mode command, then back to inserting", "i_CTRL-O" },
    { "Insert", "<C-r>{reg}", "Insert the contents of a register", "i_CTRL-R" },
    { "Insert", "<C-r>=", "Insert the result of an expression", "i_CTRL-R_=" },
    { "Insert", "<C-n> / <C-p>", "Complete this word from words in the buffers", "i_CTRL-N" },
    { "Insert", "<C-x><C-f>", "Complete a file path", "i_CTRL-X_CTRL-F" },
    { "Insert", "<C-x><C-l>", "Complete a whole line", "i_CTRL-X_CTRL-L" },
    { "Insert", "<C-t> / <C-d>", "Indent / outdent this line", "i_CTRL-T" },
    { "Insert", "<C-a>", "Insert whatever you typed last time", "i_CTRL-A" },
    { "Insert", "<C-v>{code}", "Insert a character literally, or by code", "i_CTRL-V" },

    -- Windows and tabs
    { "Windows", "<C-w>s / <C-w>v", "Split across / down", "CTRL-W_s" },
    { "Windows", "<C-w>w / <C-w>p", "Cycle windows / back to the last one", "CTRL-W_w" },
    { "Windows", "<C-w>h j k l", "Move to the window in that direction", "CTRL-W_h" },
    { "Windows", "<C-w>H J K L", "Move this window to that edge", "CTRL-W_H" },
    { "Windows", "<C-w>c / <C-w>o", "Close this window / close all the others", "CTRL-W_c" },
    { "Windows", "<C-w>= / <C-w>_ / <C-w>|", "Equalise / maximise height / maximise width", "CTRL-W_=" },
    { "Windows", "gt / gT", "Next / previous tab page", "gt" },
    { "Windows", ":tabnew", "Open a tab page", ":tabnew" },

    -- Files and the rest
    { "Misc", "gf / gx", "Open the file / the URL under the cursor", "gf" },
    { "Misc", "ga / g8", "Show the character code / its UTF-8 bytes under the cursor", "ga" },
    { "Misc", "g<C-g>", "Count the lines, words and characters", "g_CTRL-G" },
    { "Misc", "<C-g>", "Say which file this is and where you are in it", "CTRL-G" },
    { "Misc", "z= / zg / zw", "Spelling: suggest / add as good / mark as wrong", "z=" },
    { "Misc", "]s / [s", "To the next / previous misspelling", "]s" },
    { "Misc", "K", "Look up the word under the cursor", "K" },
    { "Misc", "ZZ / ZQ", "Write and quit / quit discarding changes", "ZZ" },
    { "Misc", "q:", "Open the command history as an editable window", "q:" },
    { "Misc", "<C-c>", "Cancel whatever is half-typed", "CTRL-C" },
}

-- Which modes each group's keys live in. Probing the wrong ones is how
-- `<C-w>s` came out "taken": <C-w> is mapped in insert mode, by Neovim itself,
-- and that says nothing at all about the window commands.
local group_modes = {
    ["Motions"] = { "n", "x", "o" },
    ["Operators"] = { "n", "x" },
    ["Text objects"] = { "o", "x" },
    ["Visual"] = { "x" },
    ["Registers"] = { "n", "x" },
    ["Marks"] = { "n" },
    ["Search"] = { "n", "x" },
    ["Scrolling"] = { "n", "x" },
    ["Folds"] = { "n" },
    ["Macros"] = { "n", "x" },
    ["Insert"] = { "i" },
    ["Windows"] = { "n" },
    ["Misc"] = { "n", "x" },
}

---The literal keys of an entry, with every {placeholder} taken out, so a row
---that reads `d{motion}` can still be looked up as `d`.
local function literal(lhs)
    return (lhs:gsub("{[%w%-]+}", ""):gsub("%s.*$", ""))
end

---The first key of a sequence, `<C-w>` counting as one.
local function first_key(keys)
    return keys:match("^<[^>]+>") or keys:sub(1, 1)
end

---Whether a mapping is somebody having changed this key, or just how the key
---is plumbed.
---
---Neovim ships its own defaults as real mappings and labels them `:help
---X-default`; they *are* the behaviour being documented, not a departure from
---it. A bare <Plug> mapping with nothing said about it is the same story --
---matchit implements `%`, it does not replace it.
local function is_rewrite(map)
    local desc = map.desc
    if desc and desc ~= "" then
        return desc:match("%-default$") == nil
    end
    return type(map.rhs) ~= "string" or map.rhs:match("^<Plug>") == nil
end

---What this config has done with a key, if it has done anything.
---
---The exact sequence first, then the key it starts with: `d` being mapped is
---why `dd` deletes to the black hole here, even though nothing is mapped to
---`dd` itself.
local function override(keys, modes)
    if keys == "" then return nil end

    local probes = { keys }
    if first_key(keys) ~= keys then probes[#probes + 1] = first_key(keys) end

    for _, probe in ipairs(probes) do
        for _, mode in ipairs(modes) do
            local map = vim.fn.maparg(probe, mode, false, true)
            if type(map) == "table" and not vim.tbl_isempty(map) and is_rewrite(map) then
                local desc = map.desc
                if not desc or desc == "" then
                    desc = type(map.rhs) == "string" and map.rhs ~= "" and map.rhs or "remapped"
                end
                return { keys = probe, desc = desc }
            end
        end
    end
end

function M.items()
    local items = {}

    for _, entry in ipairs(entries) do
        local group, lhs, desc, help = unpack(entry)
        local keys = literal(lhs)
        local modes = group_modes[group] or { "n" }
        local taken = override(keys, modes)

        items[#items + 1] = {
            text = table.concat({
                group, lhs, desc,
                taken and ("remapped taken " .. taken.desc) or "",
            }, " "),
            group = group,
            lhs = lhs,
            mode = table.concat(modes, "/"),
            desc = desc,
            help = help or keys,
            taken = taken,
        }
    end

    return items
end

local function open_picker()
    local Snacks = require("snacks")

    Snacks.picker.pick({
        title = "Vim Keys  ·  Enter opens :help  ·  Ctrl-Q closes",
        items = M.items(),
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            local align = Snacks.picker.util.align
            local row = {
                { align(item.group, 13), "SnacksPickerLabel" },
                { "  " },
                { align(item.lhs, 22),   "SnacksPickerKeymapLhs" },
                { "  " },
                { align(item.mode, 6),   "SnacksPickerKeymapMode" },
                { "  " },
                { align(item.desc, 56),  "SnacksPickerDesc" },
            }

            -- Standard groups on purpose: this config does not define the
            -- SnacksPicker* warning highlights, so they would render as plain
            -- text and the whole point would be lost.
            if item.taken then
                row[#row + 1] = { "  " }
                row[#row + 1] = { item.taken.keys .. " here: " .. item.taken.desc, "WarningMsg" }
            end

            return row
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            -- Help, not the key itself: half of these are verbs waiting for a
            -- motion, and the other half would be a surprising thing for a
            -- reference to do to your buffer.
            vim.schedule(function()
                if vim.fn.exists(":EditorFocus") == 2 then pcall(vim.cmd, "EditorFocus") end

                local ok = pcall(vim.cmd.help, item.help)
                if not ok then
                    vim.notify(
                        ("No help tag for %s -- try :help %s"):format(item.lhs, item.help),
                        vim.log.levels.WARN,
                        { title = "Vim Keys" }
                    )
                end
            end)
        end,
    })
end

function M.open()
    local mode = vim.api.nvim_get_mode().mode
    if mode:sub(1, 1) == "t" or mode:sub(1, 1) == "i" then
        vim.cmd("stopinsert")
    elseif mode:match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end

    vim.schedule(open_picker)
end

return M
