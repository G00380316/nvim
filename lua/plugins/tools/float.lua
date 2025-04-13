return {
    {
        "voldikss/vim-floaterm",
        config = function()
            vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits

            -- Close the current floating terminal
            vim.api.nvim_set_keymap("t", "<C-k>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "<C-k>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "<C-k>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-k>", [[<C-\><C-n>:FloatermKill<CR>]], { noremap = true, silent = true })
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "floaterm",
                callback = function()
                    local opts = { noremap = true, silent = true, buffer = true }
                    vim.keymap.set("n", "<C-q>", ":q<CR>", opts)
                    vim.keymap.set("v", "<C-q>", "<C-\\><C-n>:q<CR>", opts)
                    vim.keymap.set("i", "<C-q>", "<C-\\><C-n>:q<CR>", opts)
                end,
            })
            -- Open lazygit in a floating terminal
            -- vim.cmd("command! LazyGitFloaterm FloatermNew lazygit")
            -- vim.api.nvim_set_keymap("n", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("v", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("i", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("t", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })

            -- Navigate to the previous floating terminal
            vim.api.nvim_set_keymap("n", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-p>", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "<C-p>", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })

            -- Open a new floating terminal
            vim.api.nvim_set_keymap("n", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "<C-z>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("v", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("i", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("t", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
        end,
    },
}
