return {
    -- HACK: docs @ https://github.com/folke/snacks.nvim/blob/main/docs
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        -- NOTE: Options
        opts = {
            explorer = {
                enabled = true,
                layout = {
                    cycle = false,
                }
            },
            quickfile = {
                enabled = true,
                exclude = { "latex" },
            },
            -- HACK: read picker docs @ https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
            picker = {
                enabled = true,
                layout = {
                    -- presets options : "default" , "ivy" , "ivy-split" , "telescope" , "vscode", "select" , "sidebar"
                    -- override picker layout in keymaps function as a param below
                    preset = "telescope", -- defaults to this layout unless overidden
                    cycle = false,
                },
                layouts = {
                    select = {
                        preview = false,
                        layout = {
                            backdrop = false,
                            width = 0.6,
                            min_width = 80,
                            height = 0.4,
                            min_height = 10,
                            box = "vertical",
                            border = "rounded",
                            title = "{title}",
                            title_pos = "center",
                            { win = "input",   height = 1,          border = "bottom" },
                            { win = "list",    border = "none" },
                            { win = "preview", title = "{preview}", width = 0.6,      height = 0.4, border = "top" },
                        }
                    },
                    telescope = {
                        reverse = true, -- set to false for search bar to be on top
                        layout = {
                            box = "horizontal",
                            backdrop = false,
                            width = 0.8,
                            height = 0.9,
                            border = "none",
                            {
                                box = "vertical",
                                { win = "list",  title = " Results ", title_pos = "center", border = "rounded" },
                                { win = "input", height = 1,          border = "rounded",   title = "{title} {live} {flags}", title_pos = "center" },
                            },
                            {
                                win = "preview",
                                title = "{preview:Preview}",
                                width = 0.50,
                                border = "rounded",
                                title_pos = "center",
                            },
                        },
                    },
                    ivy = {
                        layout = {
                            box = "vertical",
                            backdrop = false,
                            width = 0,
                            height = 0.4,
                            position = "bottom",
                            border = "top",
                            title = " {title} {live} {flags}",
                            title_pos = "left",
                            { win = "input", height = 1, border = "bottom" },
                            {
                                box = "horizontal",
                                { win = "list",    border = "none" },
                                { win = "preview", title = "{preview}", width = 0.5, border = "left" },
                            },
                        },
                    },
                }
            },
            dashboard = {
                enabled = true,
                sections = {
                    { section = "header", padding = 4 },
                    { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                    { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                    { section = "startup" },
                },
            },
        },
        -- NOTE: Keymaps
        keys = {
            { "zg",  function() require("snacks").lazygit() end,                                        desc = "Lazygit" },
            { "zsl", function() require("snacks").lazygit.log() end,                                    desc = "Lazygit Logs" },
            -- { "ze",  function() require("snacks").explorer() end,                                       desc = "Open Snacks Explorer" },
            { "rN",  function() require("snacks").rename.rename_file() end,                             desc = "Fast Rename Current File" },
            { "dB",  function() require("snacks").bufdelete() end,                                      desc = "Delete or Close Buffer  (Confirm)" },

            -- Snacks Picker
            { "zcf", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
            { "zwg", function() require("snacks").picker.grep_word() end,                               desc = "Search Visual selection or Word",  mode = { "n", "x" } },
            { "zkm", function() require("snacks").picker.keymaps({ layout = "ivy" }) end,               desc = "Search Keymaps (Snacks Picker)" },

            -- Git Stuff
            { "zsb", function() require("snacks").picker.git_branches({ layout = "select" }) end,       desc = "Pick and Switch Git Branches" },

            -- Other Utils
            { "zcs", function() require("snacks").picker.colorschemes({ layout = "ivy" }) end,          desc = "Pick Color Schemes" },
            { "zh",  function() require("snacks").picker.help() end,                                    desc = "Help Pages" },
        }
    }
}
