return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.6",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set({ "n", "v", "i" }, "<C-f>", builtin.find_files, {})
            vim.keymap.set({ "n", "v", "i", "t"}, "<C-g>", builtin.live_grep, {})
            vim.keymap.set("n", "H", builtin.help_tags, {})
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}
