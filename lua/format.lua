---Formatting TypeScript, TSX, JavaScript, JSX, JSON, CSS and HTML files with
---the tool the project uses -- Biome when it has a biome.json, otherwise
---Prettier (the project's own copy first) -- instead of the language server's
---plainer formatting. Saving a file runs it; `:Format` runs it by hand. A file
---of another kind, or no formatter at all, falls back to the language server.
local M = {}

local filetypes = {
    typescript = true, typescriptreact = true, javascript = true, javascriptreact = true,
    json = true, jsonc = true, css = true, scss = true, html = true,
}

local function find_up(start, names)
    return vim.fs.find(names, { path = start, upward = true, limit = 1 })[1]
end

---The command that formats `file`'s text from stdin, and what it is called.
---@param file string
---@return string[]? command
---@return string? name
function M.command_for(file)
    local dir = vim.fs.dirname(file)
    local function local_bin(name)
        local found = find_up(dir, { "node_modules/.bin/" .. name })
        if found then return found end
        if vim.fn.executable(name) == 1 then return name end
    end

    local biome_config = find_up(dir, { "biome.json", "biome.jsonc" })
    if biome_config then
        local bin = local_bin("biome")
        if bin then return { bin, "format", "--stdin-file-path=" .. file }, "biome" end
    end
    local prettier = local_bin("prettier")
    if prettier then return { prettier, "--stdin-filepath", file }, "prettier" end
end

---Replace the buffer's text with `formatted`, changing only the lines that
---differ so the cursor, folds and marks stay where they are.
local function apply(buf, formatted)
    local old = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
    if old == formatted then return end
    local hunks = vim.diff(old, formatted, { result_type = "indices", algorithm = "histogram" })
    local new_lines = vim.split(formatted:gsub("\n$", ""), "\n", { plain = true })
    for i = #hunks, 1, -1 do
        local start_a, count_a, start_b, count_b = unpack(hunks[i])
        local replacement = vim.list_slice(new_lines, start_b, start_b + count_b - 1)
        -- A hunk that only deletes reports its position as the line before it.
        local first = count_a == 0 and start_a or start_a - 1
        vim.api.nvim_buf_set_lines(buf, first, first + count_a, false, replacement)
    end
end

---Format a buffer. Returns true when a formatter handled it (even if nothing
---changed), false when there is none to use and the caller should fall back.
---@param buf? integer
---@param opts? { quiet?: boolean }
---@return boolean
function M.run(buf, opts)
    buf = buf or vim.api.nvim_get_current_buf()
    opts = opts or {}
    local file = vim.api.nvim_buf_get_name(buf)
    if not filetypes[vim.bo[buf].filetype] or file == "" or vim.bo[buf].buftype ~= "" then return false end

    local command, name = M.command_for(file)
    if not command then
        if not opts.quiet and vim.fn.executable("prettier") == 0 and not vim.g.format_offered then
            vim.g.format_offered = true
            require("deps").ensure("prettier", { reason = "formatting TypeScript, JavaScript, CSS and JSON" })
        end
        return false
    end

    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
    local result = vim.system(command, { stdin = text, text = true, cwd = vim.fs.dirname(file) }):wait(8000)
    if result.code ~= 0 or (result.stdout or "") == "" then
        -- A file with a syntax error cannot be formatted: leave it as it is.
        local first = vim.split(vim.trim(result.stderr or ""), "\n", { plain = true })[1] or ""
        vim.notify(("%s could not format this file: %s"):format(name, first), vim.log.levels.WARN, { title = "Format" })
        return true
    end
    apply(buf, result.stdout)
    return true
end

function M.setup()
    vim.api.nvim_create_user_command("Format", function()
        if not M.run(0, { quiet = false }) then
            local ok = pcall(vim.lsp.buf.format, { async = false })
            if not ok then vim.notify("Nothing to format this file with", vim.log.levels.INFO, { title = "Format" }) end
        end
    end, { desc = "Format this file (Prettier or Biome for web files, else the language server)" })
end

return M
