return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
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
        git = {
            -- Return true to automatically git add/mv/rm files
            add = function(path)
                return true
            end,
            mv = function(src_path, dest_path)
                return true
            end,
            rm = function(path)
                return true
            end,
        },
    },
    keys = {
        vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            require("oil").toggle_float()
        end, { desc = "Toggle Oil Float" }),
    },
}
