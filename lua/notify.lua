local M = {}

-- There is no notification plugin, so vim.notify prints to the command line. A
-- message longer than one line -- a failed scp, a pandoc error -- then stops on
-- "Press ENTER or type command to continue" and eats the next key. This keeps
-- every message to one line, in its level's colour, and leaves the whole text in
-- :messages.

local highlights = {
    [vim.log.levels.ERROR] = "ErrorMsg",
    [vim.log.levels.WARN] = "WarningMsg",
}

function M.setup()
    vim.notify = function(message, level, opts)
        message = tostring(message)
        local title = opts and opts.title
        local full = title and (title .. ": " .. message) or message
        local line = full:gsub("%s*\n%s*", "  "):gsub("%s+$", "")
        local room = vim.o.columns - 12
        if vim.fn.strdisplaywidth(line) > room then
            line = vim.fn.strcharpart(line, 0, room - 1) .. "…"
        end
        local hl = highlights[level or vim.log.levels.INFO]
        -- history = false for the shortened line; the full text is kept below.
        vim.api.nvim_echo({ { line, hl } }, false, {})
        if line ~= full then
            vim.api.nvim_echo({ { full, hl } }, true, { verbose = true })
        end
    end
end

return M
