-- ============================================================
-- AUTOCMDS
-- ============================================================


-- ============================================================
-- Smart Working Directory
-- Changes cwd to the nearest project root, falling back to file dir.
-- ============================================================

local smart_cd_group = vim.api.nvim_create_augroup("SmartCD", { clear = true })

local function find_project_root(file_path)
    -- Get the directory of the current file.
    local dir = vim.fn.fnamemodify(file_path, ":h")
    if dir == "" or not vim.fn.isdirectory(dir) then
        return nil
    end

    -- Search upwards for project markers.
    local markers = { ".git", "package.json", ".project" }

    local root = vim.fs.find(markers, {
        path = dir,
        upward = true,
        type = "directory",
    })[1] or vim.fs.find(markers, {
        path = dir,
        upward = true,
        type = "file",
    })[1]

    if root then
        -- Return the directory containing the marker.
        return vim.fn.fnamemodify(root, ":h")
    end

    return nil
end

vim.api.nvim_create_autocmd("BufEnter", {
    group = smart_cd_group,
    pattern = "*",
    callback = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then
            return
        end

        local project_root = find_project_root(file_path)

        local target_dir
        if project_root then
            target_dir = project_root
        else
            target_dir = vim.fn.fnamemodify(file_path, ":h")
        end

        if target_dir
            and vim.fn.isdirectory(target_dir) == 1
            and vim.fn.getcwd() ~= target_dir
        then
            vim.cmd.cd(target_dir)
        end
    end,
    desc = "Smartly change directory to project root or file's directory",
})


-- ============================================================
-- Buffer Auto-Cleanup
-- Limits buffer count and removes empty/directory/dead buffers.
-- ============================================================

local autoclose_group = vim.api.nvim_create_augroup("AutoCloseFloats", { clear = true })

local function limit_buffers(max)
    local bufs = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())

    if #bufs > max then
        table.sort(bufs)

        for i = 1, #bufs - max do
            vim.api.nvim_buf_delete(bufs[i], { force = true })
        end
    end
end

-- Limit total listed buffers.
vim.api.nvim_create_autocmd("BufEnter", {
    group = autoclose_group,
    callback = function()
        limit_buffers(20)
    end,
})

-- Remove empty unnamed buffers after leaving them.
vim.api.nvim_create_autocmd("BufLeave", {
    group = autoclose_group,
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)

        if name == ""
            and not vim.bo[bufnr].modified
            and vim.bo[bufnr].buflisted
            and vim.bo[bufnr].buftype == ""
        then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr)
                    and vim.api.nvim_get_current_buf() ~= bufnr
                then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

-- Remove directory buffers after leaving them.
vim.api.nvim_create_autocmd("BufLeave", {
    group = autoclose_group,
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)

        if vim.fn.isdirectory(name) == 1
            and not vim.bo[bufnr].modified
            and vim.bo[bufnr].buftype == ""
        then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr)
                    and vim.api.nvim_get_current_buf() ~= bufnr
                then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

-- Extra safety pass for unnamed buffers.
vim.api.nvim_create_autocmd("BufEnter", {
    group = autoclose_group,
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)

        if name == ""
            and not vim.bo[bufnr].modified
            and vim.bo[bufnr].buflisted
            and vim.bo[bufnr].buftype == ""
        then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(bufnr)
                    and vim.api.nvim_get_current_buf() ~= bufnr
                then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

local function clean_dead_buffers()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if not vim.api.nvim_buf_is_valid(bufnr)
            or not vim.api.nvim_buf_is_loaded(bufnr)
        then
            goto continue
        end

        if vim.bo[bufnr].buftype ~= "" then
            goto continue
        end

        if vim.bo[bufnr].buflisted == false then
            goto continue
        end

        local name = vim.api.nvim_buf_get_name(bufnr)

        if name ~= ""
            and vim.fn.filereadable(name) == 0
            and vim.fn.isdirectory(name) == 0
        then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end

        ::continue::
    end
end

vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWritePost",
    "FocusGained",
}, {
    callback = function()
        vim.schedule(clean_dead_buffers)
    end,
})

vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWritePost",
    "FocusGained",
}, {
    callback = function()
        vim.schedule(clean_dead_buffers)
    end,
})


-- ============================================================
-- Floating Window Auto-Close
-- Closes floating windows when leaving them, except special UIs.
-- ============================================================

local exclude_filetypes = {
    "TelescopePrompt",
    "NvimTree",
    "lazy",
    "mason",
    "noice",
    "alpha",
    "trouble",
    "snacks",
    "Leet",
}

vim.api.nvim_create_autocmd("WinLeave", {
    group = autoclose_group,
    pattern = "*",
    callback = function(args)
        local win_id = args.win
        local bufnr = args.buf

        if type(win_id) ~= "number" then
            return
        end

        if not vim.api.nvim_win_is_valid(win_id) then
            return
        end

        local ftype = vim.bo[bufnr].filetype
        if vim.tbl_contains(exclude_filetypes, ftype) then
            return
        end

        local config = vim.api.nvim_win_get_config(win_id)

        if config.relative ~= "" then
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win_id) then
                    vim.api.nvim_win_close(win_id, true)
                end
            end)
        end
    end,
})


-- ============================================================
-- Prosession Cleanup
-- Cleans sessions when leaving buffers.
-- ============================================================

local prosession_group = vim.api.nvim_create_augroup("ProSession", { clear = true })

vim.api.nvim_create_autocmd("BufLeave", {
    group = prosession_group,
    callback = function()
        vim.cmd("ProsessionClean")
    end,
})


-- ============================================================
-- Unsupported File Handling
-- Opens binary/document files externally and closes the buffer.
-- ============================================================

local function open_if_unsupported()
    local file = vim.fn.expand("<afile>")

    vim.fn.jobstart({ "open", file }, { detach = false })
    vim.api.nvim_buf_delete(0, { force = true })
end

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "*.pdf", "*.doc", "*.docx" },
    callback = open_if_unsupported,
})


-- ============================================================
-- Terminal Behaviour
-- Starts insert mode automatically for zsh terminal buffers.
-- ============================================================

local function enter_insert_if_zsh()
    local bufname = vim.fn.expand("%:p")

    if bufname:match("zsh") then
        vim.cmd("startinsert")
    end
end

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "term://*",
    callback = enter_insert_if_zsh,
})


-- ============================================================
-- General User Autocmds
-- Terminal close + restore cursor position.
-- ============================================================

local augroup = vim.api.nvim_create_augroup("UserConfig", {})

vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function()
        if vim.v.event.status == 0 then
            vim.api.nvim_buf_delete(0, {})
        end
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)

        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})


-- ============================================================
-- Auto Save / Format
-- Auto-saves on insert leave and formats before write.
-- ============================================================

local function has_lsp(bufnr)
    bufnr = bufnr or 0
    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
end

local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

vim.api.nvim_create_autocmd("InsertLeave", {
    group = auto_save_group,
    pattern = "*",
    callback = function()
        local name = vim.api.nvim_buf_get_name(0)

        if name ~= ""
            and vim.bo.modified
            and vim.bo.buftype == ""
        then
            vim.cmd("silent! update")
        end
    end,
    desc = "Auto save on insert leave",
})

vim.api.nvim_create_autocmd("BufWritePre", {
    group = auto_save_group,
    pattern = "*",
    callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then
            return
        end

        if has_lsp(args.buf) then
            pcall(vim.lsp.buf.format, {
                async = false,
                bufnr = args.buf,
            })
        end
    end,
    desc = "Format before save",
})


-- ============================================================
-- Yank Highlight
-- Briefly highlights yanked text.
-- ============================================================

local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "Visual",
            timeout = 300,
        })
    end,
})


-- ============================================================
-- File Format Cleanup
-- Forces unix line endings and strips carriage returns before save.
-- ============================================================

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then
            return
        end

        vim.bo[args.buf].fileformat = "unix"

        local view = vim.fn.winsaveview()
        vim.cmd([[silent! %s/\r//ge]])
        vim.fn.winrestview(view)
    end,
})


-- ============================================================
-- Diagnostics Refresh
-- Refreshes statusline after diagnostics/LSP changes.
-- ============================================================

local diag_refresh_group = vim.api.nvim_create_augroup("DiagRefresh", { clear = true })

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "BufEnter" }, {
    group = diag_refresh_group,
    callback = function()
        vim.schedule(function()
            pcall(vim.cmd, "redrawstatus")
        end)
    end,
})

-- ============================================================
-- Markdown Auto Save
-- Save markdown files when leaving the buffer/window.
-- ============================================================

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = vim.api.nvim_create_augroup("MarkdownAutoSaveOnLeave", { clear = true }),
    pattern = { "*.md", "*.markdown" },
    callback = function(args)
        if vim.bo[args.buf].modified and vim.bo[args.buf].buftype == "" then
            vim.api.nvim_buf_call(args.buf, function()
                vim.cmd("silent! update")
            end)
        end
    end,
    desc = "Auto save markdown files on leave",
})
