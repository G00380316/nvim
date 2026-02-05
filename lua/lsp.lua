
--- LSP ---

vim.lsp.enable({
    "lua_ls", -- Lua language server
    -- Used mainly for Neovim config & plugins
    -- Provides completion, diagnostics, Neovim API awareness

    -- "basedpyright", -- Python type checker (Pyright fork)
    -- Full, strict static typing
    -- Slower but very accurate (large Python projects)

    "ts_ls", -- TypeScript / JavaScript language server
    -- Core JS/TS intelligence: types, refs, refactors
    -- Overlaps with quick-lint-js / oxlint
    -- Disable formatting if using dprint

    "bashls", -- Bash / shell script language server
    -- Syntax checking, basic completion for .sh files

    -- "css_variables",-- CSS variables language server
    -- Specialised support for CSS custom properties (--vars)
    -- Autocomplete + go-to-definition for variables

    "cssls", -- CSS / SCSS / LESS language server
    -- Property & value completion, validation
    -- Weak CSS variable support
    -- Disable formatting if using dprint

    "cssmodules_ls", -- CSS Modules language server
    -- Enables class name completion between CSS modules
    -- Useful for React / frontend projects

    "texlab", -- LaTeX language server
    -- Completion, diagnostics, references, build integration
    -- Best general-purpose LaTeX LSP

    -- "harper_ls", -- Grammar & style checker
    -- Markdown / prose linting (clarity, grammar, wording)
    -- Not a code intelligence server

    "jdtls", -- Java language server
    -- Full IDE-level Java support
    -- Heavy but required for serious Java work

    "markdown_oxide", -- Markdown language server
    -- Link navigation, references, wiki-style notes
    -- Great for docs and knowledge bases

    "oxlint", -- JS / TS linter (ESLint-like)
    -- Rules-based diagnostics
    -- Overlaps with ts_ls and quick-lint-js

    "phptools", -- PHP language server
    -- Completion, diagnostics, symbol navigation
    -- Lightweight PHP support

    -- "pyrefly",      -- Experimental Python type checker
    -- Research-focused, not very common in practice

    "quick-lint-js", -- Ultra-fast JavaScript linter
    -- Syntax errors only, instant feedback
    -- JS-only, no types, no formatting

    "ruff", -- Python linter (and optional formatter)
    -- Extremely fast
    -- Replaces flake8, isort, pycodestyle
    -- Disable formatting if using dprint

    "sourcekit", -- Swift / Objective-C language server
    -- Apple's official language intelligence
    -- Required for Swift development (macOS)

    "superhtml", -- HTML language server
    -- HTML tag/attribute completion & validation
    -- Lightweight, framework-agnostic

    "tailwindcss", -- Tailwind CSS language server
    -- Utility class completion, hover docs, validation
    -- Works in HTML, JSX, TSX, CSS

    "tinymist", -- Typst language server
    -- Completion, diagnostics, document tooling
    -- Best LSP for Typst

    "clangd", -- C / C++ / Objective-C language server
    -- Fast, accurate diagnostics & completion
    -- Requires compile_commands.json

    "ty", -- Python type checker (Rust-based, by Astral)
    -- Very fast, editor-focused
    -- Less complete than basedpyright, but much faster

    "sqruff", -- SQL language server / linter / formatter
    -- SQL diagnostics, linting, and optional formatting
    -- Supports multiple SQL dialects
    -- Disable formatting if dprint or another formatter is used

    "docker_language_server", -- Dockerfile language server
    -- Provides validation, completion, and hover for Dockerfiles
    -- Requires 'dockerfile' filetype to trigger

    "yamlls", -- YAML language server
    -- Unified support for YAML, Docker Compose, K8s, etc.
    -- Requires schemaStore enabled for Docker Compose intelligence
    -- Triggered by: .yml, .yaml
})

--     Enables or disables inlay hints for the {filter}ed scope.
vim.lsp.inlay_hint.enable()
-- vim.api.nvim_create_autocmd('LspAttach', {
-- 	group = vim.api.nvim_create_augroup('my.lsp', {}),
-- 	callback = function(args)
-- 		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
--
-- 		if client:supports_method('textDocument/completion') then
-- 			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
-- 		end
-- 	end,
-- })

-- vim.keymap.set('i', '<C-Space>', function()
-- 	vim.lsp.completion.get()
-- end)

vim.keymap.set("n", "<C-Space>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    -- If on whitespace or end of line, move to next word first
    if char == "" or char:match("%s") then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("wciw", true, false, true),
            "n",
            true
        )
    else
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("ciw", true, false, true),
            "n",
            true
        )
    end

    -- Trigger completion after entering insert mode
    -- vim.schedule(function()
    -- 	vim.lsp.completion.get()
    -- end)
end, {
    noremap = true,
    silent = true,
    desc = "Change word (or next word) and trigger completion",
})

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
            diagnostics = {
                globals = {
                    "vim",
                    "require",
                },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,
            },
        },
    },
})
require("blink.cmp").setup({
    signature = { enabled = true },

    completion = {
        documentation = { auto_show = true },

        menu = {
            auto_show = true,
            draw = {
                treesitter = { "lsp" },
                columns = {
                    { "kind_icon", "label", "label_description", gap = 1 },
                    { "kind" },
                },
            },
        },
    },

    fuzzy = {
        implementation = "lua"
    },

    keymap = {
        preset = 'default',
        -- Trigger completion (Ctrl-Space)
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },

        -- Accept completion
        ["<CR>"] = { "accept", "fallback" },

        -- Abort
        ["<Space>"] = { "hide", "fallback" },
    },
})
-- Note that commented code above is to nuetralise Native Completion and opt for blink


vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("XcodebuildLSP", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        -- Only attach these to SourceKit (Swift/Obj-C) buffers
        if client and client.name == "sourcekit" then
            local bufnr = args.buf

            if not _G.xcodebuild_initialized then
                require("xcodebuild").setup({
                    show_build_progress_bar = true,
                    logs = {
                        auto_open_on_success = false,
                        auto_open_on_error = true,
                    },
                })
                _G.xcodebuild_initialized = true
            end

            local opts = { buffer = bufnr, silent = true }

            vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildPicker<cr>", opts)
            vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", opts)
            vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", opts)
            vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", opts)
            vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectScheme<cr>", opts)

            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                    vim.cmd("XcodebuildBuildRun")
                end,
            })
        end
    end,
})
