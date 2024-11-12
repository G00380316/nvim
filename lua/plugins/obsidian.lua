-- still need to add custom highlight colors D^:
return {
    {
        -- obsidian
        'epwalsh/obsidian.nvim',
        version = '*',
        lazy = true,
        ft = 'markdown',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        opts = {
            workspaces = {
                {
                    name = 'Projects',
                    path = '~/OneDrive/Apps/remotely-save/Projects',
                },
            },
            ui = {
                enable = true,
                checkboxes = {
                    -- [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                    -- ["x"] = { char = "", hl_group = "ObsidianDone" },
                    -- ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
                    -- ["!"] = { char = "", hl_group = "ObsidianImportant" },
                    [' '] = { char = '☐', hl_group = 'ObsidianTodo' },
                    ['x'] = { char = '', hl_group = 'ObsidianDone' },
                    ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
                },
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
        },
    },

    {
        -- pretty markdown
        'MeanderingProgrammer/render-markdown.nvim',
        -- enabled = false,
        opts = {
            heading = {
                width = 'block',
                min_width = 50,
                border = true,
                backgrounds = {
                    'RenderMarkdownH1Bg',
                    'RenderMarkdownH2Bg',
                    'RenderMarkdownH3Bg',
                    'RenderMarkdownH4Bg',
                    'RenderMarkdownH5Bg',
                    'RenderMarkdownH6Bg',
                },
                foregrounds = {
                    'RenderMarkdownH1',
                    'RenderMarkdownH2',
                    'RenderMarkdownH3',
                    'RenderMarkdownH4',
                    'RenderMarkdownH5',
                    'RenderMarkdownH6',
                },
            },
            render_modes = { 'n', 'v', 'i', 'c' },
            checkbox = {
                unchecked = { icon = '󰄱 ' },
                checked = { icon = ' ' },
                custom = { todo = { raw = '[>]', rendered = '󰥔 ' } },
            },
            code = {
                position = 'right',
                width = 'block',
                left_pad = 2,
                right_pad = 4,
            },
        },
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
    },
}
