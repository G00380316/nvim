return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = {"markdown"},
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",

        -- see below for full list of optional dependencies 👇
    },
    opts = {
        -- This workspace corresponds to my own file-system
        workspaces = {
            {
                name = "Projects",
                path = "~/OneDrive/Apps/remotely-save/Projects/",
            }
        },
        ui = {
            enable = true,
            -- Define how various check-boxes are displayed
            checkboxes = {
                -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
                [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                ["x"] = { char = "", hl_group = "ObsidianDone" },
                [">"] = { char = "", hl_group = "ObsidianRightArrow" },
                ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
                ["!"] = { char = "", hl_group = "ObsidianImportant" },
                -- Replace the above with this if you don't have a patched font:
                -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
                -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

                -- You can also add more custom ones...
            },
            -- Use bullet marks for non-checkbox lists.
            bullets = { char = "•", hl_group = "ObsidianBullet" },
            external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
            -- Replace the above with this if you don't have a patched font:
            -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
            reference_text = { hl_group = "ObsidianRefText" },
            highlight_text = { hl_group = "ObsidianHighlightText" },
            tags = { hl_group = "ObsidianTag" },
            block_ids = { hl_group = "ObsidianBlockID" },
            hl_groups = {
                -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
                ObsidianTodo = { bold = true, fg = "#f78c6c" },
                ObsidianDone = { bold = true, fg = "#89ddff" },
                ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
                ObsidianTilde = { bold = true, fg = "#ff5370" },
                ObsidianImportant = { bold = true, fg = "#d73128" },
                ObsidianBullet = { bold = true, fg = "#89ddff" },
                ObsidianRefText = { underline = true, fg = "#c792ea" },
                ObsidianExtLinkIcon = { fg = "#c792ea" },
                ObsidianTag = { italic = true, fg = "#89ddff" },
                ObsidianBlockID = { italic = true, fg = "#89ddff" },
                ObsidianHighlightText = { bg = "#75662e" },
            },
            -- Specify how to handle attachments.
            attachments = {
                -- The default folder to place images in via `:ObsidianPasteImg`.
                -- If this is a relative path it will be interpreted as relative to the vault root.
                -- You can always override this per image by passing a full path to the command instead of just a filename.
                img_folder = "assets/imgs", -- This is the default

                -- Optional, customize the default name or prefix when pasting images via `:ObsidianPasteImg`.
                ---@return string
                img_name_func = function()
                    -- Prefix image names with timestamp.
                    return string.format("%s-", os.time())
                end,

                -- A function that determines the text to insert in the note when pasting an image.
                -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
                -- This is the default implementation.
                ---@param client obsidian.Client
                ---@param path obsidian.Path the absolute path to the image file
                ---@return string
                img_text_func = function(client, path)
                    path = client:vault_relative_path(path) or path
                    return string.format("![%s](%s)", path.name, path)
                end,
            },
        }
        -- see below for full list of options 👇
    },
}
