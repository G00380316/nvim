return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        default_file_explorer = true, -- Replaces netrw
        view_options = {
            show_hidden = true,
        },
        float = {
            padding = 2,
            max_width = 80,
            max_height = 20,
            border = "rounded",
        },
    },
    keys = {
        vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            require("oil").toggle_float()
        end, { desc = "Toggle Oil Float" })
    },
}
