return {
    {
        'windwp/nvim-ts-autotag',
        event = "InsertEnter",
        config = function()
            require('nvim-ts-autotag').setup({
                opts = {
                    -- Defaults
                    enable_close = true,          -- Auto close tags
                    enable_rename = true,         -- Auto rename pairs of tags
                    enable_close_on_slash = false -- Auto close on trailing </
                },
                -- Also override individual filetype configs, these take priority.
                -- Empty by default, useful if one of the "opts" global settings
                -- doesn't work well in a specific filetype
                per_filetype = {
                    ["html"] = {
                        enable_close = false
                    }
                }
            })
        end,
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = function()
            local npairs = require('nvim-autopairs')
            local Rule = require('nvim-autopairs.rule')
            local cond = require('nvim-autopairs.conds')

            -- Basic setup
            npairs.setup({
                check_ts = true, -- Enables Treesitter integration
            })

            -- Add custom rules
            npairs.add_rules({
                -- Lua: Pair [[ and ]]
                Rule("[[", "]]", "lua"),

                -- Python: Triple quotes for docstrings
                Rule('"""', '"""', "python"),

                -- TypeScript/JavaScript: Template literals with ${} inside backticks
                Rule("`", "`", { "typescript", "javascript" })
                    :with_pair(function(opts)
                        local pair = opts.line:sub(opts.col, opts.col + 1)
                        return pair ~= "``"
                    end)
                    :with_move(cond.none()),

                -- Rust: Pair < and > for generics
                Rule("<", ">", "rust"),

                -- Java: Pair < and > for generics
                Rule("<", ">", "java"),

                -- CSS & TailwindCSS: Pair curly braces
                Rule("{", "}", { "css", "tailwindcss" }),

                -- JSON: Disable pairing for : and ,
                Rule(":", ":", "json"):with_pair(cond.none()),
                Rule(",", ",", "json"):with_pair(cond.none()),

                -- Arduino: Include directives
                Rule("#include <", ">", "arduino"),

                -- C/C++: Include directives and generics
                Rule("<", ">", { "c", "cpp" }),
                Rule("#include <", ">", { "c", "cpp" }),
            })
        end,
    },
}