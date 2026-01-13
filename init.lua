vim.env.TMPDIR = "/tmp"
-- Save original notify function
local original_notify = vim.notify

-- Setup nvim-notify first
local notify_ok, notify = pcall(require, "notify")
if notify_ok then
	vim.notify = function(msg, level, opts)
		local in_startup = vim.fn.has("vim_starting") == 1

		-- Filter noisy messages
		if type(msg) == "string" then
			if
				msg:match("exit code")
				or msg:match("warning: multiple different client offset_encodings")
				or msg:match(".*LSP.*")
				or msg:match("client")
				or msg:match("Pending")
				or msg:match("Judging...")
                or msg:match("Pattern not found")
			then
				return
			end
		end

		-- Only show errors during startup
		if level == vim.log.levels.ERROR and not in_startup then
			return
		end

		-- Use nvim-notify if available
		notify(msg, level, opts)
	end
else
	-- Fallback if nvim-notify is not installed
	vim.notify = function(msg, level, opts)
		local in_startup = vim.fn.has("vim_starting") == 1
		if level == vim.log.levels.ERROR and not in_startup then
			return
		end
		original_notify(msg, level, opts)
	end
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.g.netrw_banner = 0    -- remove the banner
-- vim.g.netrw_browse_split = 0 -- open files in the same window
-- vim.g.netrw_altv = 1      -- vertical split opens on the right
-- vim.g.netrw_liststyle = 3 -- tree-style listing
-- vim.g.netrw_winsize = 25  -- sidebar width (in %)

vim.opt.termguicolors = true

-- Fix PATH for macOS GUI and terminal
vim.env.PATH = vim.env.PATH .. ":/opt/homebrew/bin"
local brew_prefix = "/opt/homebrew/bin"
if not string.find(vim.env.PATH, brew_prefix, 1, true) then
	vim.env.PATH = brew_prefix .. ":" .. vim.env.PATH
end

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

local show_commands = require("custom.commands").show_custom_command_menu

-- Setup the keymap, calling the function directly
vim.keymap.set({ "n", "v", "i", "t" }, "<C-/>", function()
	-- Call the custom command menu function
	show_commands()
end, { desc = "Show Custom Command Menu (vim.ui.select)" })

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
		if not scheme then
			return
		end -- Prevents errors if it's nil

		-- Path to save the colorscheme selection
		local config_path = vim.fn.stdpath("config") .. "/colorscheme.txt"

		-- Write the scheme to the file
		local success, err = pcall(function()
			local file = io.open(config_path, "w")
			if not file then
				return false
			end
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

-- Monkey Patch Load Session to improve error handling
vim.schedule(function()
	local ok, utils = pcall(require, "session_manager.utils")
	if ok then
		-- Patch the `load_session` function if needed, or override the bwipe logic
		local old_load_session = utils.load_session
		utils.load_session = function(...)
			local status, err = pcall(old_load_session, ...)
			if not status and err:match("E517: No buffers were wiped out") then
				-- suppress error
				return
			end
			if not status then
				error(err)
			end
		end
	end
end)

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.fn.setreg("/", "") -- clear the search pattern
		vim.cmd("nohlsearch") -- turn off search highlighting
	end,
})

-- use this if your using hammerspoon
vim.api.nvim_create_autocmd("BufDelete", {
	callback = function()
		if #vim.fn.getbufinfo({ buflisted = 1 }) == 0 then
			vim.cmd("enew")
		end
	end,
})
