return {
	"google/executor.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("executor").setup({
			-- Use popup window instead of split
			use_split = false,

			-- Popup configuration
			popup = {
				width = math.floor(vim.o.columns * 0.6),
				height = vim.o.lines - 20,
				border = {
					padding = { top = 2, bottom = 2, left = 3, right = 3 },
					style = "rounded",
				},
			},

			-- Notification configuration
			notifications = {
				task_started = true,
				task_completed = true,
				border = {
					padding = { top = 0, bottom = 0, left = 1, right = 1 },
					style = "rounded",
				},
			},

			-- Optional: filter output (pass-through example)
			output_filter = function(command, lines)
				-- modify output here if needed
				return lines
			end,

			-- Statusline (optional)
			statusline = {
				prefix = "Exec: ",
				icons = {
					in_progress = "…",
					failed = "✖",
					passed = "✓",
				},
			},

			-- Optional presets based on working directory
			preset_commands = {
				["myproject"] = {
					"cargo test",
					"cargo run",
					{ partial = true, cmd = "cargo test -- --nocapture " },
				},
			},
		})

		-- Keybindings
		local executor = require("executor")
		local function auto_command_for_file()
			local ft = vim.bo.filetype
			local file = vim.fn.expand("%")
			local out = vim.fn.expand("%:r")

			if ft == "python" then
				return "python3 " .. vim.fn.shellescape(file)
			elseif ft == "java" then
				local class = vim.fn.expand("%:t:r") -- filename without extension
				local dir = vim.fn.expand("%:p:h") -- parent directory

				return "cd " .. dir .. " && javac " .. file .. " && java " .. class
			elseif ft == "c" then
				return "gcc " .. file .. " -o " .. out .. " && ./" .. out
			elseif ft == "cpp" or ft == "cxx" or ft == "hpp" then
				return "g++ " .. file .. " -o " .. out .. " && ./" .. out
			elseif ft == "sh" then
				return "bash " .. file
			elseif ft == "go" then
				return "go run " .. file
			end

			-- fallback: prompt user
			return nil
		end

		-- Run saved command (prompts first time)
		vim.keymap.set("n", "zr", function()
			local cmd = auto_command_for_file()

			if cmd then
				-- overwrite executor’s stored command
				executor.commands.run_one_off(cmd)

				-- Auto-show output window
				vim.defer_fn(function()
					executor.commands.show_detail()
				end, 50)
			else
				-- fallback to normal executor behavior
				executor.commands.run()
			end
		end, { desc = "Auto Executor Run" })

		-- Set a new command without running it
		-- vim.keymap.set("n", "znr", function()
		-- 	executor.commands.set_command()
		-- end, { desc = "Executor Set Command" })

		-- Run with a new command immediately
		vim.keymap.set("n", "znr", function()
			executor.commands.run_with_new_command()
		end, { desc = "Executor Run With New Command" })

		-- Toggle detail view
		vim.keymap.set("n", "zrd", function()
			executor.commands.toggle_detail()
		end, { desc = "Executor Toggle Detail View" })

		-- History of executed commands
		-- vim.keymap.set("n", "<leader>eh", function()
		-- 	executor.commands.show_history()
		-- end, { desc = "Executor History" })

		-- Show preset commands
		-- vim.keymap.set("n", "zep", function()
		-- 	executor.commands.show_presets()
		-- end, { desc = "Executor Presets" })

		-- Reset executor state
		-- vim.keymap.set("n", "<leader>ex", function()
		-- 	executor.commands.reset()
		-- end, { desc = "Executor Reset" })

		-- One-off command (does not overwrite stored command)
		-- vim.keymap.set("n", "zro", ":ExecutorOneOff ", {
		-- 	desc = "Executor One-Off Command",
		-- })
	end,
}
