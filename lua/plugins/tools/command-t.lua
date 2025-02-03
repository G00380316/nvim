return {
    {
        -- To make sure this work you might have to build it manually so to do
        -- so ❯ cd ~/.local/share/nvim/lazy/command-t/lua/wincent/commandt/lib
        -- then ❯ make clean then ❯ make
        "wincent/command-t",
        run = 'cd lua/wincent/commandt/lib && make',
        config = function()
            require('wincent.commandt').setup({
                always_show_dot_files = false,
                height = 5,
                ignore_case = nil, -- If nil, will infer from Neovim's `'ignorecase'`.
                margin = 0,
                match_listing = {
                    -- 'double', 'none', 'rounded', 'shadow', 'single', 'solid', or a
                    -- list of strings.
                    border = { '', '', '', '│', '┘', '─', '└', '│' },
                    truncate = 'middle', -- 'beginning', 'end', true, false.
                },
                never_show_dot_files = false,
                order = 'forward',   -- 'forward' or 'reverse'.
                position = 'bottom', -- 'bottom', 'center' or 'top'.
                prompt = {
                    -- 'double', 'none', 'rounded', 'shadow', 'single', 'solid', or a
                    -- list of strings.
                    border = { '┌', '─', '┐', '│', '┤', '─', '├', '│' },

                },
                open = function(item, kind)
                    require('wincent.commandt').open(item, kind)
                end,
                root_markers = { '.git', '.hg', '.svn', '.bzr', '_darcs' },
                scanners = {
                    file = {
                        max_files = 0,
                    },
                    find = {
                        max_files = 0,
                    },
                    git = {
                        max_files = 0,
                        submodules = true,
                        untracked = false,
                    },
                    rg = {
                        max_files = 0,
                    },
                },
                selection_highlight = 'PmenuSel',
                smart_case = nil,  -- If nil, will infer from Neovim's `'smartcase'`.
                threads = nil,     -- Let heuristic apply.
                traverse = 'none', -- 'file', 'pwd' or 'none'.
            })
        end,
    }
}
