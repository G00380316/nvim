--- PLUGINS ---

vim.pack.add({
	-- Navigation
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim",          version = "0.1.8" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/voldikss/vim-floaterm" },


	-- UI
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
	{ src = "https://github.com/HiPhish/rainbow-delimiters.nvim" },
	{ src = "https://github.com/3rd/image.nvim" },
	{ src = "https://github.com/goolord/alpha-nvim" },
	{ src = "https://github.com/stevearc/dressing.nvim" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },


	-- LSP
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/nvimdev/lspsaga.nvim" },


	-- Tools
	{ src = "https://github.com/chomosuke/typst-preview.nvim" },
	{ src = "https://github.com/lambdalisue/vim-suda" },
	{ src = "https://github.com/kawre/leetcode.nvim" },
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/G00380316/ssh-launcher.nvim" },
})


--- VIM SETTINGS ---

vim.cmd([[set mouse=]])
vim.cmd([[set noswapfile]])

vim.cmd([[hi @lsp.type.number gui=italic]])
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.cmd(":hi statusline guibg=NONE")
vim.cmd(":hi signcolumn guibg=NONE")
vim.cmd [[
  highlight CursorLine cterm=NONE ctermbg=236 guibg=#2e2e2e
]]
vim.cmd("set completeopt+=noselect")
vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])

vim.o.tabstop = 4
vim.o.autoindent = true

vim.o.matchtime = 2   -- How long to show matching bracket

vim.o.autoread = true -- Auto reload files changed outside vim

vim.o.winborder = "rounded"

vim.o.smartcase = true -- Case sensitive if uppercase in search
vim.o.hlsearch = true  -- `hlsearch = false`: Disables the highlighting of search results after searching.
vim.o.incsearch = true -- `incsearch = true`: Shows incremental search results as you type.

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.guicursor = "n-v-c-sm:block-blinkon1,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/Cursor"
vim.o.signcolumn = "yes"
vim.o.scrolloff = 10 -- Keeps 10 lines of context around the cursor when scrolling.
vim.o.wrap = true
-- Stops words from being broken by wrapping
vim.o.linebreak = true
vim.o.wrapmargin = 0              -- " Disable margin-based line wrapping
vim.o.textwidth = 0               -- " Disable hard wrapping at a fixed width
vim.opt.formatoptions:remove("t") -- " Remove the 't' flag to stop automatic text wrapping


vim.o.termguicolors = true
vim.o.undofile = true
vim.o.clipboard = "unnamedplus" -- Adding clipboard func with wl-clipboard
vim.diagnostic.config({ virtual_text = true })


--- PLUGIN CONFIGS ---

require("kanagawa").setup({
	compile = false, -- enable compiling the colorscheme
	undercurl = true, -- enable undercurls
	commentStyle = { italic = true },
	functionStyle = {},
	keywordStyle = { italic = false },
	statementStyle = { bold = true },
	typeStyle = {},
	transparent = true, -- do not set background color
	dimInactive = false, -- dim inactive window `:h hl-NormalNC`
	terminalColors = true, -- define vim.g.terminal_color_{0,17}
	colors = {      -- add/modify theme and palette colors
		palette = {},
		theme = {
			wave = {},
			dragon = {},
			all = {
				ui = {
					bg_gutter = "none",
					border = "rounded"
				}
			}
		},
	},
	overrides = function(colors) -- add/modify highlights
		local theme = colors.theme
		return {
			NormalFloat = { bg = "none" },
			FloatBorder = { bg = "none" },
			FloatTitle = { bg = "none" },
			Pmenu = { fg = theme.ui.shade0, bg = "NONE", blend = vim.o.pumblend }, -- add `blend = vim.o.pumblend` to enable transparency
			PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
			PmenuSbar = { bg = theme.ui.bg_m1 },
			PmenuThumb = { bg = theme.ui.bg_p2 },

			-- Save an hlgroup with dark background and dimmed foreground
			-- so that you can use it where your still want darker windows.
			-- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
			NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

			-- Popular plugins that open floats will link to NormalFloat by default;
			-- set their background accordingly if you wish to keep them dark and borderless
			LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
			MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
			TelescopeTitle = { fg = theme.ui.special, bold = true },
			TelescopePromptBorder = { fg = theme.ui.special, },
			TelescopeResultsNormal = { fg = theme.ui.fg_dim, },
			TelescopeResultsBorder = { fg = theme.ui.special, },
			TelescopePreviewBorder = { fg = theme.ui.special },
		}
	end,
	theme = "wave", -- Load "wave" theme when 'background' option is not set
	background = { -- map the value of 'background' option to a theme
		dark = "wave", -- try "dragon" !
	},
})


local telescope = require("telescope")
telescope.setup({
	defaults = {
		preview = { treesitter = true },
		color_devicons = true,
		sorting_strategy = "ascending",
		borderchars = {
			"", -- top
			"", -- right
			"", -- bottom
			"", -- left
			"", -- top-left
			"", -- top-right
			"", -- bottom-right
			"", -- bottom-left
		},
		file_ignore_patterns = {
			"node_modules",
			".git/",
			"dist/",
			"build/",
			"target/",
		},
		mappings = {
			i = {
				["<C-d>"] = "delete_buffer",
			},
			n = {
				["<C-d>"] = "delete_buffer",
			},
		},
		path_displays = { "smart" },
		layout_config = {
			height = 100,
			width = 400,
			prompt_position = "top",
			preview_cutoff = 40,
		},
		pickers = {
			buffers = {
				sort_mru = true,
				ignore_current_buffer = true,
			},
		},
	},
	keys = {
		vim.keymap.set({ "n", "v", "i" }, "<C-f>", ":Telescope find_files<CR>", { desc = "File Lookup" }),
		vim.keymap.set({ "n", "v", "i" }, "<C-g>", ":Telescope live_grep<CR>", { desc = "Grep" }),
		vim.keymap.set("n", "<leader>h", ":Telescope help_tags<CR>", { desc = "I need Help" }),
		vim.keymap.set("n", "zcf", function()
			require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "Find Config Files" }),
		vim.keymap.set({ "n", "x" }, "<C-l>", function()
			local b = require("telescope.builtin")
			if vim.fn.mode():find("[vV]") then
				b.grep_string({ search = vim.fn.getreg('z'), use_regex = false })
			else
				b.grep_string({ search = vim.fn.expand("<cword>") })
			end
		end, { desc = "Search Visual selection or Word" }),
		vim.keymap.set("n", "zkm", ":Telescope keymaps<CR>", { desc = "Search Keymaps" }),
		-- vim.keymap.set("n", "zsb", ":Telescope git_branches<CR>", { desc = "Git Branches" })
		vim.keymap.set({ "n", "v", "i" }, "<C-b>", "<cmd>Telescope buffers<CR>", { desc = "Choose a buffer" }),
	}
})
telescope.load_extension("ui-select")


require("oil").setup({
	default_file_explorer = true, -- Replaces netrw
	watch_for_changes = true,
	delete_to_trash = true,
	columns = {
		"icon",
		-- "permissions",
		-- "size",
		-- "mtime",
	},
	skip_confirm_for_simple_edits = true,
	use_default_keymaps = false,
	view_options = {
		show_hidden = true,
	},
	float = {
		padding = 2,
		max_width = 80,
		max_height = 20,
		border = "rounded",
	},
	keymaps = {
		["g?"] = { "actions.show_help", mode = "n" },
		["<CR>"] = "actions.select",
		["zv"] = { "actions.select", opts = { vertical = true } },
		["zh"] = { "actions.select", opts = { horizontal = true } },
		["<C-t>"] = { "actions.select", opts = { tab = true } },
		["<C-p>"] = "actions.preview",
		["<C-c>"] = { "actions.close", mode = "n" },
		["<C-l>"] = "actions.refresh",
		["<BS>"] = { "actions.parent", mode = "n" },
		["_"] = { "actions.open_cwd", mode = "n" },
		["`"] = { "actions.cd", mode = "n" },
		["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
		["gs"] = { "actions.change_sort", mode = "n" },
		["gx"] = "actions.open_external",
		["g."] = { "actions.toggle_hidden", mode = "n" },
		["g\\"] = { "actions.toggle_trash", mode = "n" },
	},
	keys = {
		vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
			require("oil").toggle_float()
		end, { desc = "Toggle Oil Float" }),
	},
})


require("image").setup({
	backend = "kitty",
	processor = "magick_cli", -- or "magick_rock"
	integrations = {
		markdown = {
			enabled = true,
			clear_in_insert_mode = false,
			download_remote_images = true,
			only_render_image_at_cursor = false,
			only_render_image_at_cursor_mode = "popup",
			floating_windows = false,
			filetypes = { "markdown", "vimwiki" },
		},
		neorg = {
			enabled = true,
			filetypes = { "norg" },
		},
		typst = {
			enabled = true,
			filetypes = { "typst" },
		},
		html = {
			enabled = false,
		},
		css = {
			enabled = false,
		},
	},
	max_width = nil,
	max_height = nil,
	max_width_window_percentage = nil,
	max_height_window_percentage = 50,
	window_overlap_clear_enabled = false,
	window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
	editor_only_render_when_focused = false,
	tmux_show_only_in_active_window = false,
	hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
})


vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits

vim.api.nvim_create_autocmd("FileType", {
	pattern = "floaterm",
	callback = function()
		local opts = { noremap = true, silent = true, buffer = true }

		-- Terminal mode (most important)
		vim.keymap.set("t", "<C-k>", "<C-\\><C-n>:q<CR>", opts)

		-- Normal mode (optional, but useful)
		vim.keymap.set("n", "<C-k>", ":q<CR>", opts)
	end,
})


vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true }) -- Navigate to the previous floating terminal
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true }) -- Open a new floating terminal
vim.api.nvim_set_keymap("v", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-t>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })


require("gitsigns").setup({
	signs = {
		add = { text = "+" }, -- Symbol for added lines
		change = { text = "~" }, -- Symbol for changed lines
		delete = { text = "_" }, -- Symbol for deleted lines
		topdelete = { text = "‾" }, -- Symbol for deleted lines at the top
		changedelete = { text = "~" }, -- Symbol for changed and deleted lines
	},
	update_debounce = 100, -- Debounce time in milliseconds for updates
	status_formatter = nil,
})


require("leetcode").setup({
	-- configuration goes here
	---@type lc.lang
	lang = "python3",
	---@type boolean
	image_support = true,
	---@type lc.storage
	storage = {
		home = "~/Documents/Github/Leetcode",
		cache = vim.fn.stdpath("cache") .. "/leetcode",
	},
})

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
	"                                                 ",
	" ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
	" ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
	" ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
	" ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
	" ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
	" ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
	"                                                 ",
}

dashboard.section.header.opts.position = "center"
dashboard.section.footer.opts.position = "center"
dashboard.section.buttons.val = {
	dashboard.button("o", "  Open Folder", function()
		vim.ui.input({
			prompt = "Open directory: ",
			default = "~/",
			completion = "dir",
		}, function(input)
			if input and input ~= "" then
				local dir = vim.fn.expand(input)

				-- Open with Oil instead of a plain buffer
				require("oil").open(dir)
			end
		end)
	end),
	dashboard.button("r", "  Connect to Remote", "<cmd>SshLauncher<CR>"),
	dashboard.button(
		"l",
		"  LeetCode",
		"<cmd>silent !kitty @ launch --type=os-window nvim +'Leet'<CR>"
	),
	dashboard.button("t", "  Terminal", "<cmd>term<CR>"),
}
local fortune = require("alpha.fortune")
dashboard.section.footer.val = fortune()

dashboard.section.header.opts.hl = "Statement"
dashboard.section.buttons.opts.hl = "Type"
dashboard.section.footer.opts.hl = "Type"

table.insert(dashboard.opts.layout, 1, { type = "padding", val = 5 })

alpha.setup(dashboard.opts)


require("ssh_launcher").setup()


local lualine = require("lualine")

local function floaterm_tabline()
	local tabs = {}
	local current = vim.api.nvim_get_current_buf()

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf)
		    and vim.bo[buf].filetype == "floaterm"
		then
			local name = vim.fn.fnamemodify(
				vim.api.nvim_buf_get_name(buf),
				":t"
			)

			local label = (buf == current and " " or " ")
			    .. (name ~= "" and name or "Terminal")

			table.insert(tabs, label)
		end
	end

	return table.concat(tabs, " | ")
end


--- AUTOCMDS ---

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
			target_dir = project_root   -- Target the discovered project root 🌳
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

local autoclose_group =
    vim.api.nvim_create_augroup("AutoCloseFloats", { clear = true })

local function limit_buffers(max)
	local bufs = vim.tbl_filter(function(buf)
		return vim.api.nvim_buf_is_loaded(buf)
		    and vim.bo[buf].buflisted
	end, vim.api.nvim_list_bufs())

	if #bufs > max then
		table.sort(bufs) -- older buffers first
		for i = 1, #bufs - max do
			vim.api.nvim_buf_delete(bufs[i], { force = true })
		end
	end
end

-- Limit total buffers
vim.api.nvim_create_autocmd("BufEnter", {
	group = autoclose_group,
	callback = function()
		limit_buffers(20)
	end,
})

-- Remove empty unnamed buffers
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

-- Remove directory buffers
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

-- Extra safety pass on BufEnter (kept intentionally)
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
	"Leet"
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

local augroup = vim.api.nvim_create_augroup("UserConfig", {})

-- Auto-close terminal when process exits
vim.api.nvim_create_autocmd("TermClose", {
	group = augroup,
	callback = function()
		if vim.v.event.status == 0 then
			vim.api.nvim_buf_delete(0, {})
		end
	end,
})

-- Return to last edit position when opening files
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


-- A function to search for the word under the cursor and then jump
-- Sticky smart search state
local sticky_active = false
local sticky_word = nil
local case_sensitive = false

-- A function to clear search highlighting and the search pattern
local function clear_search()
	vim.fn.setreg('/', '')
	sticky_active = false
	sticky_word = nil

	-- vim.notify("Search cleared", vim.log.levels.INFO, { timeout = 1000 })
end

local function build_search_pattern(word)
	local escaped = vim.fn.escape(word, "\\")
	local prefix = case_sensitive and "" or "\\c"
	return prefix .. "\\<" .. escaped .. "\\>"
end

local function smart_search_and_jump(direction)
	-- If no sticky search is active, initialize it using <cword>
	if not sticky_active then
		local word = vim.fn.expand("<cword>")
		if word == "" then
			print("No word under cursor to search")
			return
		end

		sticky_word = word
		sticky_active = true
		vim.fn.setreg("/", build_search_pattern(sticky_word))
	end

	-- Before jumping, make sure the search register is not empty
	local search_reg = vim.fn.getreg("/")
	if search_reg == "" then
		print("No active search pattern")
		return
	end

	-- Jump to next/previous match
	vim.cmd("normal! " .. direction)
end


-- local web_dev_autosave = vim.api.nvim_create_augroup("WebDevAutoSave", { clear = true })
local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

-- vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
--     group = web_dev_autosave,
--     pattern = { "*.html", "*.css", "*.js" }, -- File types to target
--     callback = function()
--         -- Check if the buffer has a file name and has been modified
--         if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 and vim.bo.modified then
--             vim.cmd("update") -- Use "update" to save only if there are changes
--         end
--     end,
--     desc = "Auto save for html, css, and js files",
-- })

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
	group = auto_save_group,
	pattern = { "*" }, -- File types to target
	callback = function()
		-- Check if the buffer has a file name and has been modified
		if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1 and vim.bo.modified then
			vim.cmd("update") -- Use "update" to save only if there are changes
		end
	end,
	desc = "AutoSave All files",
})


local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			higroup = "Visual",
			timeout = 120,
		})
	end,
})
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


--- SPECIAL MAPPINGS ---

vim.keymap.set("n", "<C-d>", "<C-d>zz")                            -- Scroll Half-Page and Center
vim.keymap.set("n", "<C-u>", "<C-u>zz")                            -- Scroll Half-Page and Center
vim.keymap.set("n", "n", "nzzzv")                                  -- Center Search Results
vim.keymap.set("n", "N", "Nzzzv")                                  -- Center Search Results
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true }) -- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true }) -- Outdent selected block of text

vim.keymap.set({ 'n', 'v' }, 'y', '"+y')
vim.keymap.set({ "n", "v" }, "d", [["_d]]) -- Delete Without Affecting Clipboard
-- Standard-editor-style visual paste
vim.keymap.set("x", "p", function()
	return '"_dP'
end, { expr = true, silent = true })

-- Open lazygit in floating terminal (main UI)
vim.keymap.set("n", "zg", function()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
	vim.fn.jobstart({ "lazygit" }, { term = true })
	vim.cmd("startinsert")
end, { desc = "Open Lazygit in floating terminal" })

vim.keymap.set("n", "<CR>", function()
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	local char = line:sub(col, col)

	if char == "" or char:match("%s") then
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes("w", true, false, true),
			"n",
			true
		)
	else
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes("ciw", true, false, true),
			"n",
			true
		)
	end
end, { noremap = true, silent = true, desc = "Enter: o or ciw" })

vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", { noremap = true, desc = "Exit Terminal mode in Terminal" })

--- LSP ---

vim.lsp.enable({ "lua_ls", "basedpyright","ts_ls" })


--- KEYMAPS ---

vim.g.mapleader = " "

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>', { desc = "Update Source" })
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = "Format Code" })
vim.keymap.set({ "n", "i", "v" }, "<C-s>", function()
	if vim.fn.mode() == "i" then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	end
	if vim.bo.filetype ~= "oil" then
		vim.lsp.buf.format({ async = false })
	end
	vim.cmd("write")
	vim.fn.setreg("/", "")
end, { noremap = true, silent = true, desc = "Save" })
vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", function()
	-- Leave insert / terminal mode cleanly
	if vim.fn.mode() == "i" then
		vim.cmd("stopinsert")
	elseif vim.fn.mode() == "t" then
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
			"n",
			false
		)
	end

	local buf = vim.api.nvim_get_current_buf()
	local wins = vim.fn.win_findbuf(buf)

	if #wins > 1 then
		-- Buffer is visible in multiple windows → close only this window
		vim.cmd("close")
	else
		-- Only one window shows this buffer → delete buffer
		vim.cmd("bd!")
	end
end, { noremap = true, silent = true, desc = "Smart close window / buffer" })
vim.keymap.set({ "n", "v" }, "zv", "<cmd>vsplit<CR>", { noremap = true, silent = true, desc = "Split Vertically" })
vim.keymap.set({ "n", "v" }, "zh", "<cmd>split<CR>", { noremap = true, silent = true, desc = "Split Horizontally" })
vim.keymap.set("n", "<C-w>", "<C-w>w", { noremap = true, silent = true, desc = "Switch to next window" })
vim.keymap.set(
	"i",
	"<C-w>",
	"<Esc><C-w>w",
	{ noremap = true, silent = true, desc = "Switch to next window from insert mode" }
)
vim.keymap.set("v", "<C-w>", "<C-w>w", { noremap = true, silent = true, desc = "Switch to next window in visual mode" })
vim.keymap.set(
	"t",
	"<C-w>",
	[[<C-\><C-n><C-w>w]],
	{ noremap = true, silent = true, desc = "Switch to next window in terminal mode" }
)

vim.keymap.set('n', '<leader>c', clear_search, {
	desc = "Clear search highlight and pattern"
})
vim.keymap.set("n", "n", function()
	smart_search_and_jump("n")
end, { desc = "Sticky search: next occurrence" })
vim.keymap.set("n", "N", function()
	smart_search_and_jump("N")
end, { desc = "Sticky search: previous occurrence" })
vim.keymap.set("n", "<leader>s", function()
	case_sensitive = not case_sensitive

	if sticky_active and sticky_word then
		vim.fn.setreg("/", build_search_pattern(sticky_word))
	end

	vim.notify("Sticky search case-sensitive: " .. tostring(case_sensitive), vim.log.levels.INFO, { timeout = 1000 })
end, { desc = "Toggle case sensitivity for sticky search" })
-- 1. A keymap to START the interactive replace
-- This finds the word under the cursor and readies the first replacement.
vim.keymap.set('n', '<leader>r', '*Ncgn', {
	noremap = true,
	silent = true,
	desc = "Start interactive replace for word under cursor"
})
vim.keymap.set({ 'n', 'i' }, '<C-n>', function()
	local function do_repeat()
		vim.api.nvim_feedkeys('.', 'n', false)
		-- Uncomment below to return to insert mode after replacing
		-- vim.api.nvim_feedkeys('i', 'n', false)
	end

	if vim.fn.mode() == 'i' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>n', true, false, true), 'n', false)
		vim.defer_fn(do_repeat, 30)
	else
		vim.api.nvim_feedkeys('n', 'n', false)
		vim.defer_fn(do_repeat, 30)
	end
end, {
	noremap = true,
	silent = true,
	desc = "Replace current match and find next (with delay fix)"
})
-- 2. A keymap for "Replace and Find Previous"
-- This repeats the last change (.) and jumps to the previous match (N).
vim.keymap.set({ 'n', 'i' }, '<C-p>', function()
	local function do_repeat()
		vim.api.nvim_feedkeys('.', 'n', false)
	end

	if vim.fn.mode() == 'i' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>N', true, false, true), 'n', false)
		vim.defer_fn(do_repeat, 30) -- delay 30ms
	else
		vim.api.nvim_feedkeys('N', 'n', false)
		vim.defer_fn(do_repeat, 30)
	end
end, {
	noremap = true,
	silent = true,
	desc = "Replace previous match properly"
})
vim.keymap.set({ "n" }, "/", function()
	require("telescope.builtin").current_buffer_fuzzy_find({
		layout_strategy = "vertical",
		layout_config = {
			width = 0.4,
			height = 0.3,
			prompt_position = "top",
		},
		winblend = 1,
		border = true,
		borderchars = {
			"─", "│", "─", "│",
			"┌", "┐", "┘", "└",
		},
		prompt_prefix = case_sensitive and " 	" or " 	",
	})
end, { desc = "Find in current buffer (minimal)" })


vim.keymap.set({ "n", "t" }, "<C-a>", "<cmd>Alpha<CR>", { noremap = true, silent = true })

-- Lua Configuration for Neovim
-- vim.keymap.set("n", "<C-Space>", 'ciw<cmd>lua vim.schedule(function() require("cmp").complete() end)<CR>', {
-- 	noremap = true,
-- 	silent = true,
-- 	desc = "Change word and trigger completion",
-- })



--- Most be Last ---

vim.cmd("colorscheme kanagawa")

local highlight = {
	"RainbowDelimiterRed",
	"RainbowDelimiterYellow",
	"RainbowDelimiterBlue",
	"RainbowDelimiterOrange",
	"RainbowDelimiterGreen",
	"RainbowDelimiterViolet",
}

-- Ensure the highlight groups exist
local hooks = require("ibl.hooks")

hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { link = "Red" })
	vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { link = "Yellow" })
	vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { link = "Blue" })
	vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { link = "Orange" })
	vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { link = "Green" })
	vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { link = "Purple" })
end)

require("rainbow-delimiters.setup").setup({
	highlight = highlight,
})

vim.g.rainbow_delimiters = {
	highlight = highlight,
}

require("ibl").setup({
	indent = { highlight = highlight },
	scope = {
		highlight = highlight,
		show_start = false,
		show_end = false,
	},
})

local kanagawa = require("lualine.themes.auto")

-- for _, m in pairs(kanagawa) do
-- 	if m.x then
-- 		m.x.bg = "none"
-- 	end
-- end

local mode = {
	"mode",
	fmt = function(str)
		return " " .. str
	end,
}

local diff = {
	"diff",
	symbols = {
		added = " ",
		modified = " ",
		removed = " ",
	},
}

local filename = {
	"filename",
	file_status = true,
	path = 0,
}

local branch = {
	"branch",
	icon = "",
}

local lsp_status = {
	'lsp_status',
	icon = '', -- f013
	symbols = {
		-- Standard unicode symbols to cycle through for LSP progress:
		spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
		-- Standard unicode symbol for when LSP is done:
		done = '✓',
		-- Delimiter inserted between LSP names:
		separator = ' ',
	},
	-- List of LSP names to ignore (e.g., `null-ls`):
	ignore_lsp = {},
	-- Display the LSP name
	show_name = true,
}

lualine.setup({
	options = {
		icons_enabled = true,
		theme = kanagawa,
		component_separators = { left = "|", right = "|" },
		section_separators = { left = "|", right = "" },
	},
	sections = {
		lualine_a = { mode },
		lualine_b = { branch },
		lualine_c = { diff, filename },
		lualine_x = {
			{
				floaterm_tabline,
				cond = function()
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.bo[buf].filetype == "floaterm" then
							return true
						end
					end
					return false
				end,
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				sections = { "error", "warn", "info", "hint" },
				symbols = {
					error = " ",
					warn  = " ",
					info  = " ",
					hint  = "󰌵 ",
				},
				update_in_insert = true,
			},
			{ "filetype" },
			lsp_status
		},
	},
})
