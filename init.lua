vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.g.netrw_banner = 0    -- remove the banner
-- vim.g.netrw_browse_split = 0 -- open files in the same window
-- vim.g.netrw_altv = 1      -- vertical split opens on the right
-- vim.g.netrw_liststyle = 3 -- tree-style listing
-- vim.g.netrw_winsize = 25  -- sidebar width (in %)

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
require("autodir")
require("autosave")
require("autoformat")
require("buffer")
require("copy")
require("findReplace")
require("misc")
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
