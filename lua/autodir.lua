local smart_cd_group = vim.api.nvim_create_augroup("SmartCD", { clear = true })

local function find_project_root(file_path)
    -- Get the directory of the current file
    local dir = vim.fn.fnamemodify(file_path, ":h")
    if dir == "" or not vim.fn.isdirectory(dir) then
        return nil
    end

    -- Search upwards for project markers
    local markers = { ".git", "package.json", ".project" }
    local root = vim.fs.find(markers, { path = dir, upward = true, type = "directory" })[1]
        or vim.fs.find(markers, { path = dir, upward = true, type = "file" })[1]

    if root then
        -- Return the directory containing the marker
        return vim.fn.fnamemodify(root, ":h")
    end

    return nil
end

vim.api.nvim_create_autocmd("BufEnter", {
    group = smart_cd_group,
    pattern = "*", -- Run for all files
    callback = function()
        local file_path = vim.api.nvim_buf_get_name(0)
        if file_path == "" then return end

        -- Find the project root using our new function
        local project_root = find_project_root(file_path)

        -- Determine the target directory
        local target_dir
        if project_root then
            target_dir = project_root                        -- Target the discovered project root 🌳
        else
            target_dir = vim.fn.fnamemodify(file_path, ":h") -- Fallback to the file's directory
        end

        -- Change directory only if needed and the target is valid
        if target_dir and vim.fn.isdirectory(target_dir) == 1 and vim.fn.getcwd() ~= target_dir then
            vim.cmd.cd(target_dir)
        end
    end,
    desc = "Smartly change directory to project root or file's directory",
})
