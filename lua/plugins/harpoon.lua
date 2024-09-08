return {
	"ThePrimeagen/harpoon",
	config = function()
		local harpoon_mark = require("harpoon.mark")
		local harpoon_ui = require("harpoon.ui")

		-- Keybindings to add and navigate files
		vim.keymap.set("n", "<C-a>", harpoon_mark.add_file, { desc = "Add file to Harpoon" })
		vim.keymap.set("n", "<C-m>", harpoon_ui.toggle_quick_menu, { desc = "Toggle Harpoon menu" })

		-- Navigate between files using Harpoon's index
		vim.keymap.set("n", "<C-1>", function()
			harpoon_ui.nav_file(1)
		end, { desc = "Go to Harpoon file 1" })
		vim.keymap.set("n", "<C-2>", function()
			harpoon_ui.nav_file(2)
		end, { desc = "Go to Harpoon file 2" })
		vim.keymap.set("n", "<C-3>", function()
			harpoon_ui.nav_file(3)
		end, { desc = "Go to Harpoon file 3" })
		vim.keymap.set("n", "<C-4>", function()
			harpoon_ui.nav_file(4)
		end, { desc = "Go to Harpoon file 4" })

		-- Replace files in specific Harpoon slots
		--vim.keymap.set("n", "<leader><C-h>", function()
		--    harpoon_mark.set_current_at(1)
		--end, { desc = "Replace Harpoon file 1" })
		--vim.keymap.set("n", "<leader><C-t>", function()
		--    harpoon_mark.set_current_at(2)
		--end, { desc = "Replace Harpoon file 2" })
		--vim.keymap.set("n", "<leader><C-n>", function()
		--   harpoon_mark.set_current_at(3)
		--end, { desc = "Replace Harpoon file 3" })
		--vim.keymap.set("n", "<leader><C-s>", function()
		--    harpoon_mark.set_current_at(4)
		--end, { desc = "Replace Harpoon file 4" })
	end,
}
