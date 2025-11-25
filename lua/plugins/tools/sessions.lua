return {
    "Shatur/neovim-session-manager",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local config = require("session_manager.config")
        local session_manager = require("session_manager")
        local Path = require("plenary.path")

        --------------------------------------------------------------------
        -- Session Manager Setup (your regular settings)
        --------------------------------------------------------------------
        session_manager.setup({
            autoload_mode = config.AutoloadMode.CurrentDir,      -- Load a session automatically based on the current directory.
            autosave_last_session = true,                        -- Save the last used session when exiting or switching sessions.
            autosave_ignore_dirs = { vim.loop.os_homedir() },    -- Never save a session when you're in your home directory.
            autosave_ignore_filetypes = { "gitcommit", "oil" },  -- Close buffers with these filetypes before saving the session.
            autosave_ignore_buftypes = { "nofile", "quickfix" }, -- Same as above but for buffer "types".
            load_include_current = true,                         -- Show the current session in the session picker.
            autosave_only_in_session = true,                     -- Only autosave if you're actually inside a session.
            max_path_length = 50,                                -- Shorten long paths in the UI.
        })

        --------------------------------------------------------------------
        -- Prevent sessions being created inside nested directories.
        --
        -- The goal:
        -- If you already have a session for a folder, we don't want another
        -- one being created for a subdirectory inside it. This keeps your
        -- session folder clean and avoids "session spam".
        --------------------------------------------------------------------

        -- Folder where session files are stored
        local sessions_dir = vim.fn.stdpath("data") .. "/sessions"

        -- Check if any parent directory already has a session file
        local function parent_session_exists(dir)
            local path = Path:new(dir)

            while true do
                path = path:parent()

                -- Stop when we reach the top of the filesystem
                if not path or path.filename == "/" or path.filename == "" then
                    return false
                end

                -- Session files use "path%to%dir.vim" style naming
                local session_filename = path.filename:gsub("/", "%%") .. ".vim"
                local session_path = Path:new(sessions_dir .. "/" .. session_filename)

                -- If a session exists for a parent folder, we treat this as nested
                if session_path:exists() then
                    return true
                end
            end
        end

        --------------------------------------------------------------------
        -- Autocommand that runs right before a session is saved.
        --
        -- If we're inside a folder whose parent already has a session,
        -- we cancel the save. This is the cleanest way to prevent nested
        -- sessions while still letting the plugin autosave normally.
        --------------------------------------------------------------------
        local group = vim.api.nvim_create_augroup("SessionManager_NestedBlock", {})

        vim.api.nvim_create_autocmd("User", {
            pattern = "SessionSavePre",  -- Triggered right before saving a session
            group = group,
            callback = function()
                local cwd = vim.fn.getcwd()

                -- If a parent session exists, block the save for this directory
                if parent_session_exists(cwd) then
                    vim.v.event.cancel = true
                end
            end,
        })
    end,
}
