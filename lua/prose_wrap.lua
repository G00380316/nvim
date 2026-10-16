---Typing past the ruler. In prose the line breaks itself at the ruler's column
---and the next line carries on whatever the first one was part of; in code, a
---comment does the same and code is never broken. The cases:
---
---  - bullet / numbered / task item: the next line lines up under the text, not
---    under the marker (a task's box is part of the marker);
---  - blockquote and callout: the next line starts with the `>` again;
---  - plain paragraph, nested list: the same indent;
---  - heading, table row, code fence and what is inside one, front matter, a
---    line of HTML: never broken;
---  - a commit message: the subject is not broken, the body wraps at 72;
---  - code: `//`, `#`, `--` and `/* */` comments carry their leader on the next
---    line; a line of code is left alone.
---
---The width is the ruler's, so toggling the ruler off turns wrapping off too.
---Pasting is not typing: nothing is rewrapped on a paste.
local M = {}

local PROSE = { markdown = true, jupyter = true, text = true, gitcommit = true }

-- A list marker: a bullet or number, then an optional task box. With the `n`
-- flag in 'formatoptions' the next line is indented to match what this matches.
local LIST_PATTERN = [[^\s*\%(\d\+[.)]\|[-*+]\)\s\+\%(\[[ xX>-]\]\s\+\)\?]]

---The width to wrap at in this buffer, 0 for none.
local function width_for(buf)
    local ruler = require("ruler").state()
    if not ruler.enabled then return 0 end
    if vim.bo[buf].filetype == "gitcommit" then return math.min(72, ruler.width) end
    return ruler.width
end

---Lines of the buffer, flagged for being inside a code fence or front matter.
local cache = {}
local function protected_lines(buf)
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    local c = cache[buf]
    if c and c.tick == tick then return c.flags end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local flags, fenced = {}, false
    local start = 1
    if lines[1] == "---" then
        for j = 2, math.min(#lines, 80) do
            if lines[j] == "---" then
                for k = 1, j do flags[k] = true end
                start = j + 1
                break
            end
        end
    end
    for i = start, #lines do
        if lines[i]:match("^%s*```") or lines[i]:match("^%s*~~~") then
            flags[i] = true
            fenced = not fenced
        elseif fenced then
            flags[i] = true
        end
    end
    cache[buf] = { tick = tick, flags = flags }
    return flags
end

---Whether a line of prose may be broken.
local function may_break(buf, lnum, line)
    if line:match("^%s*#+%s") or line:match("^%s*#+$") then return false end -- heading
    if line:match("^%s*|") then return false end -- table row
    if line:match("^%s*<[%a/!]") then return false end -- HTML, comment markers
    if line:match("^%s*%[[^%]]+%]:%s") then return false end -- link definition
    if vim.bo[buf].filetype == "gitcommit" and lnum == 1 then return false end -- subject
    return not protected_lines(buf)[lnum]
end

function M.setup()
    local group = vim.api.nvim_create_augroup("ProseWrap", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            local ft = vim.bo[args.buf].filetype
            if PROSE[ft] then
                -- t: wrap text as you type; c: carry a comment/quote leader on;
                -- q: gq formats; j: join comments; n: numbered/bulleted lists
                -- indent the next line; l: do not break lines that were already long.
                vim.opt_local.formatoptions = "tcqjnl"
                if ft == "markdown" or ft == "jupyter" then
                    -- Bullets are handled as list items (so a task's box counts),
                    -- not as comment leaders; only `>` is a leader.
                    vim.opt_local.comments = "n:>"
                    vim.opt_local.formatlistpat = LIST_PATTERN
                end
                -- Long lines that are not broken still wrap on screen under their
                -- own text, not back at the margin.
                vim.opt_local.breakindent = true
                vim.opt_local.breakindentopt = "list:-1"
            else
                -- Code: comments wrap and carry their leader; code never does, and
                -- Enter does not start a new comment line by itself.
                vim.opt_local.formatoptions:append("c")
                vim.opt_local.formatoptions:remove({ "t", "r", "o" })
            end
        end,
        desc = "Set how a line breaks at the ruler, for this kind of file",
    })

    -- Decide, as the line nears the ruler, whether it may break here.
    vim.api.nvim_create_autocmd("InsertCharPre", {
        group = group,
        callback = function()
            local buf = vim.api.nvim_get_current_buf()
            if not PROSE[vim.bo[buf].filetype] then return end
            local width = width_for(buf)
            if width == 0 then return end
            if vim.fn.virtcol(".") < width - 3 then return end
            local lnum = vim.api.nvim_win_get_cursor(0)[1]
            local line = vim.api.nvim_get_current_line()
            vim.bo[buf].textwidth = may_break(buf, lnum, line) and width or 0
        end,
        desc = "Never break a heading, table row or code fence at the ruler",
    })

    -- Back to the ruler's width once typing stops, for gq and the like.
    vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function(args)
            if PROSE[vim.bo[args.buf].filetype] then vim.bo[args.buf].textwidth = width_for(args.buf) end
        end,
    })
end

M.may_break = may_break
M.list_pattern = LIST_PATTERN

return M
