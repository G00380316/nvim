vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.CommandTPreferredImplementation = 'lua'
vim.g.CommandTEncoding = "UTF-8"
vim.g.CommandTFileScanner = "watchman"
vim.g.CommandTMaxCachedDirectories = 10
vim.g.CommandTMaxFiles = 1000000
vim.g.CommandTScanDotDirectories = 1
vim.g.CommandTTraverseSCM = "pwd"
vim.g.CommandTWildIgnore = vim.o.wildignore ..
    ",**/.git/*,**/.hg/*,**/bower_components/*,**/node_modules/*,**/tmp/*"
vim.opt.termguicolors = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("set")
require("keymaps")
local function load_plugins()
    local plugins = {}
    local path = vim.fn.stdpath("config") .. "/lua/plugins"

    for _, file in ipairs(vim.fn.glob(path .. "/**/*.lua", true, true)) do
        local plugin = dofile(file)
        if plugin then
            table.insert(plugins, plugin)
        end
    end

    return plugins
end

require("lazy").setup(load_plugins())

-- Path to the colorscheme file
local config_path = vim.fn.stdpath("config") .. "/colorscheme.txt"

-- Check if the file exists and load the scheme
local file = io.open(config_path, "r")
if file then
    local scheme = file:read("*l") -- Read the first line
    file:close()

    -- Apply the scheme if it exists
    if scheme and scheme ~= "" then
        vim.cmd("colorscheme " .. scheme)
        -- print("Applied saved scheme: " .. scheme)
    else
        print("No colorscheme saved.")
    end
else
    print("No colorscheme file found.")
end

local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })
local auto_dir_group = vim.api.nvim_create_augroup("Dir", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

local web_dev_autosave = vim.api.nvim_create_augroup("WebDevAutoSave", { clear = true })

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = web_dev_autosave,
    pattern = { "*.html", "*.css", "*.js" }, -- File types to target
    callback = function()
        -- Check if the buffer has a file name and has been modified
        if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 and vim.bo.modified then
            vim.cmd("update") -- Use "update" to save only if there are changes
        end
    end,
    desc = "Auto save for html, css, and js files",
})

-- Auto-Format on "BufEnter"
vim.api.nvim_create_autocmd("BufEnter", {
    group = auto_dir_group,
    pattern = "*",
    callback = function()
        vim.lsp.buf.format()
    end,
})

vim.api.nvim_create_autocmd("BufLeave", {
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(bufnr)
        local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
        local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
        local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

        -- Only remove truly empty, unmodified unnamed buffers
        if name == "" and not modified and listed and buftype == "" then
            vim.schedule(function()
                -- Recheck to avoid closing active buffer too soon
                if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() ~= bufnr then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
            end)
        end
    end,
})

-- Auto-Save on BufLeave (Important will warn that buffers aren't saved if not)
-- vim.api.nvim_create_autocmd("BufLeave", {
--     group = auto_save_group,
--     pattern = "*",
--     command = "silent! write",
-- })

-- Auto-Save on CursorHold
-- vim.api.nvim_create_autocmd("CursorHold", {
--    group = auto_save_group,
--    pattern = "*",
--    command = "silent! write",
--})

vim.api.nvim_create_autocmd("VimLeave", {
    group = auto_save_group,
    pattern = "*",
    command = "silent! write",
})

local function limit_buffers(max)
    local bufs = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted")
    end, vim.api.nvim_list_bufs())

    if #bufs > max then
        -- Sort by buffer number (older are usually lower numbers)
        table.sort(bufs)
        for i = 1, #bufs - max do
            vim.api.nvim_buf_delete(bufs[i], { force = true })
        end
    end
end

-- Call this after opening a buffer
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        limit_buffers(10)
    end,
})

-- auto-open CommandT on vim open
-- vim.api.nvim_create_autocmd("VimEnter", {
--     callback = function()
--         local path = vim.fn.argv(0)
--         if vim.fn.isdirectory(path) == 1 then
--             require('wincent.commandt').setup({ height = vim.o.lines }) -- Make it full screen
--             vim.cmd("silent! CommandT")
--         end
--     end
-- })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "commandt",
    callback = function()
        local opts = { noremap = true, silent = true, buffer = true }
        vim.keymap.set("n", "<C-c>", ":q<CR>", opts)
        vim.keymap.set("i", "<C-c>", "<C-\\><C-n>:q<CR>", opts)
    end,
})

local function enter_insert_if_zsh()
    -- Check if the buffer is a terminal running zsh
    local bufname = vim.fn.expand('%:p')
    if bufname:match("zsh") then
        vim.cmd("startinsert")
    end
end

-- Autocmd for when entering a terminal buffer
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "term://*",
    callback = enter_insert_if_zsh,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        local scheme = vim.g.colors_name -- Correct way to get the colorscheme name
        if not scheme then return end    -- Prevents errors if it's nil

        -- Path to save the colorscheme selection
        local config_path = vim.fn.stdpath("config") .. "/colorscheme.txt"

        -- Write the scheme to the file
        local success, err = pcall(function()
            local file = io.open(config_path, "w")
            if not file then return false end
            file:write(scheme)
            file:close()
            return true
        end)

        -- Check for success and print any errors
        if not success then
            vim.notify("Error saving colorscheme: " .. (err or "Unknown Error"), vim.log.levels.ERROR)
        else
            vim.notify("Saved colorscheme: " .. scheme, vim.log.levels.INFO)
        end
    end,
})

local notify = require("notify")

-- Override vim.notify to filter out LSP messages
vim.notify = function(msg, level, opts)
    -- Suppress LSP "xxx progress" and other noisy messages
    if type(msg) == "string" and msg:match("exit code") then
        return
    end
    if msg:match("warning: multiple different client offset_encodings") then
        return
    end
    if msg:match(".*LSP.*") or msg:match("client") then
        return
    end
    if msg:match("Pending") or msg:match("Judging...") then
        return
    end

    -- Otherwise, show the message using nvim-notify
    notify(msg, level, opts)
end

-- Create an augroup to ensure commands are not duplicated
local autoclose_group = vim.api.nvim_create_augroup("AutoCloseFloats", { clear = true })

-- Define a list of filetypes that should NOT be auto-closed
local exclude_filetypes = {
    "TelescopePrompt",
    "NvimTree",
    "lazy",
    "mason",
    "noice",
    "alpha",
    "trouble",
    "snacks",
}

vim.api.nvim_create_autocmd("WinLeave", {
    group = autoclose_group,
    pattern = "*",
    callback = function(args)
        local win_id = args.win
        local bufnr = args.buf

        -- First, ensure win_id is a number before using it.
        if type(win_id) ~= "number" then
            return
        end

        -- Then, check if the window is still valid.
        if not vim.api.nvim_win_is_valid(win_id) then
            return
        end

        -- Check if the buffer in the window is listed for exclusion
        local ftype = vim.bo[bufnr].filetype
        if vim.tbl_contains(exclude_filetypes, ftype) then
            return
        end

        -- Get window configuration
        local config = vim.api.nvim_win_get_config(win_id)

        -- Check if the window is a float
        if config.relative ~= "" then
            vim.schedule(function()
                -- check validity again inside the schedule
                if vim.api.nvim_win_is_valid(win_id) then
                    vim.api.nvim_win_close(win_id, true)
                end
            end)
        end
    end,
})


local smart_cd_group = vim.api.nvim_create_augroup("SmartCD", { clear = true })

local function find_project_root(file_path)
    -- Get the directory of the current file
    local dir = vim.fn.fnamemodify(file_path, ":h")
    if dir == "" or not vim.fn.isdirectory(dir) then
        return nil
    end

    -- Search upwards for project markers
    local markers = { ".git", "package.json", ".project" }
    local root = vim.fs.find(markers, { path = dir, upward = true, type = "directory" })[1]
        or vim.fs.find(markers, { path = dir, upward = true, type = "file" })[1]

    if root then
        -- Return the directory containing the marker
        return vim.fn.fnamemodify(root, ":h")
    end

    return nil
end

vim.api.nvim_create_autocmd("BufEnter", {
    group = smart_cd_group,
    pattern = "*", -- Run for all files
    callback = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then return end

        -- Find the project root using our new function
        local project_root = find_project_root(file_path)

        -- Determine the target directory
        local target_dir
        if project_root then
            target_dir = project_root                  -- Target the discovered project root 🌳
        else
            target_dir = vim.fn.fnamemodify(file_path, ":h") -- Fallback to the file's directory
        end

        -- Change directory only if needed and the target is valid
        if target_dir and vim.fn.isdirectory(target_dir) == 1 and vim.fn.getcwd() ~= target_dir then
            vim.cmd.cd(target_dir)
        end
    end,
    desc = "Smartly change directory to project root or file's directory",
})
--vim.g.netrw_browse_split = 0
--vim.g.netrw_banner = 0
--vim.g.netrw_winsize = 25
