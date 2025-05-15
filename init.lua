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


-- Auto-Format on "BufEnter"
vim.api.nvim_create_autocmd("BufEnter", {
    group = auto_dir_group,
    pattern = "*",
    callback = function()
        vim.lsp.buf.format()
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
    limit_buffers(4)
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

--vim.g.netrw_browse_split = 0
--vim.g.netrw_banner = 0
--vim.g.netrw_winsize = 25
