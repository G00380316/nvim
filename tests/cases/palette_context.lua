-- The palette puts what is related to where it was opened first.
local palette = require("palette")
local function first_groups(context, n)
    local out = {}
    for i, item in ipairs(palette.items(context)) do
        if i > n then break end
        out[#out + 1] = item.group
    end
    return out
end

-- From the explorer: File / Project rows lead.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil_win = vim.api.nvim_get_current_win()
T.eq(palette.context_kind({ win = oil_win }), "oil", "explorer recognised")
local top = first_groups({ win = oil_win }, 6)
T.ok(vim.tbl_contains(top, "File") or vim.tbl_contains(top, "Project"), "explorer: file/project actions first (" .. table.concat(top, ",") .. ")")

-- From a markdown note: Markdown rows lead.
vim.cmd("edit " .. T.file("n.md", "# x\n"))
local note_win
for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "markdown" then note_win = w end
end
T.eq(palette.context_kind({ win = note_win }), "markdown", "note recognised")
T.eq(first_groups({ win = note_win }, 1)[1], "Markdown", "note: markdown actions first")

-- Nothing is lost: the same rows, just ordered differently.
T.eq(#palette.items({ win = oil_win }), #palette.items({}), "same number of rows")
