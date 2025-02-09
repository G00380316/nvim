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
        print("Applied saved scheme: " .. scheme)
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

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = auto_save_group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Auto-save on buffer leave
--vim.api.nvim_create_autocmd("BufLeave", {
--  group = auto_save_group,
--  pattern = "*",
-- command = "silent! write",
--})

-- Auto-Format on BufLeave
vim.api.nvim_create_autocmd("BufEnter", {
    group = auto_dir_group,
    pattern = "*",
    callback = function()
        vim.lsp.buf.format()
    end,
})

-- Auto-Save on CursorHold
vim.api.nvim_create_autocmd("CursorHold", {
    group = auto_save_group,
    pattern = "*",
    command = "silent! write",
})

--vim.api.nvim_create_autocmd("VimEnter", {
--    callback = function()
--        local path = vim.fn.argv(0)
--        -- Check if the buffer opened is a directory
--        if vim.fn.isdirectory(path) == 1 then
--            vim.schedule(function()
--                -- Open the directory interactively
--                require("mini.files").open(path, { allow_changes = true })
--            end)
--        end
--    end
--})

-- auto-open CommandT on vim open
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local path = vim.fn.argv(0)
        if vim.fn.isdirectory(path) == 1 then
            require('wincent.commandt').setup({ height = vim.o.lines }) -- Make it full screen
            vim.cmd("silent! CommandT")
        end
    end
})

-- Auto-Save on BufLeave (Important will warn that buffers aren't saved if not)
vim.api.nvim_create_autocmd("BufLeave", {
    group = auto_save_group,
    pattern = "*",
    command = "silent! write",
})

local function enter_insert_if_zsh()
    -- Check if the buffer is a terminal running zsh
    local bufname = vim.fn.expand('%:p')
    if bufname:match("zsh") then
        vim.cmd("startinsert")
    end
end

-- Autocmd for when a terminal is opened
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "term://*",
    callback = enter_insert_if_zsh,
})

-- Autocmd for when entering a terminal buffer
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "term://*",
    callback = enter_insert_if_zsh,
})

-- Auto-change directory to the file's directory on buffer enter
--vim.api.nvim_create_autocmd("BufEnter", {
--   group = auto_dir_group,
--   pattern = "*",
--   command = "silent! :cd %:p:h",
--})

-- Function to find the nearest directory containing package.json or .git
--[[local function find_project_root()
    local path = vim.fn.expand("%:p:h")

    -- First, look for the nearest package.json
    local package_json_dir = vim.fn.findfile("package.json", path .. ";")
    if package_json_dir ~= "" then
        return vim.fn.fnamemodify(package_json_dir, ":p:h")
    end

    -- If no package.json is found, look for the nearest .git directory
    local git_dir = vim.fn.finddir(".git", path .. ";")
    if git_dir ~= "" then
        -- Return the parent directory of the .git directory
        return vim.fn.fnamemodify(git_dir, ":p:h:h")
    end

    -- If neither is found, fall back to the current file's directory
    return path
end

-- Auto-change directory to the nearest package.json, .git's parent directory, or current file's directory
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        local project_root = find_project_root()
        if project_root then
            vim.cmd("silent! cd " .. project_root)
        end
    end,
})]]

--vim.g.netrw_browse_split = 0
--vim.g.netrw_banner = 0
--vim.g.netrw_winsize = 25
