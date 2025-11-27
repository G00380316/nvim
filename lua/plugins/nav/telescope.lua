return {
    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        config = function()
            local builtin = require("telescope.builtin")

            -- Keymaps
            vim.keymap.set({ "n", "v", "i" }, "<C-f>", builtin.find_files, {})
            vim.keymap.set({ "n", "v", "i" }, "<C-g>", builtin.live_grep, {})
            vim.keymap.set("n", "H", builtin.help_tags, {})
            vim.keymap.set("n", "T", "<cmd>Telescope<CR>", {})
            vim.keymap.set("n", "zcf", function()
                require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
            end, { desc = "Find Config Files" })
            vim.keymap.set({ "n", "x" }, "zwg", function()
                local b = require("telescope.builtin")
                if vim.fn.mode():find("[vV]") then
                    b.grep_string({ search = vim.fn.getreg('z'), use_regex = false })
                else
                    b.grep_string({ search = vim.fn.expand("<cword>") })
                end
            end, { desc = "Search Visual selection or Word" })
            vim.keymap.set("n", "zkm", builtin.keymaps, { desc = "Search Keymaps" })
            vim.keymap.set("n", "zsb", builtin.git_branches, { desc = "Git Branches" })
            vim.keymap.set("n", "zcs", builtin.colorscheme, { desc = "Choose Colorscheme" })
            vim.keymap.set({ "n", "v", "i" }, "<C-b>", "<cmd>Telescope buffers<CR>", { desc = "Pick a buffer" })

            -- Telescope setup with ignore patterns
            require("telescope").setup {
                defaults = {
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
                },
                pickers = {
                    buffers = {
                        sort_mru = true,
                        ignore_current_buffer = true,
                        previewer = true,
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
            }

            require("telescope").load_extension("ui-select")
        end,
    },
}
