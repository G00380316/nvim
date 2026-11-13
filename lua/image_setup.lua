---Configure image.nvim once. Markdown and image files call it when opened;
---notebooks call it too, because molten draws plot outputs through it and
---fails with "image.nvim is not setup" otherwise.
local M = {}
local done = false

function M.setup()
    if done then return end
    done = true
    require("image").setup({
        backend = "kitty",
        processor = "magick_cli",

        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = true,
                only_render_image_at_cursor = false,
                only_render_image_at_cursor_mode = "popup",
                floating_windows = false,
                filetypes = { "markdown", "vimwiki" },
            },
            neorg = {
                enabled = true,
                filetypes = { "norg" },
            },
            typst = {
                enabled = true,
                filetypes = { "typst" },
            },
            html = {
                enabled = false,
            },
            css = {
                enabled = false,
            },
        },

        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,

        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = {
            "cmp_menu",
            "cmp_docs",
            "snacks_notif",
            "scrollview",
            "scrollview_sign",
        },

        editor_only_render_when_focused = false,
        tmux_show_only_in_active_window = false,

        hijack_file_patterns = {
            "*.png",
            "*.jpg",
            "*.jpeg",
            "*.gif",
            "*.webp",
            "*.avif",
        },
    })
    M.guard_render()
end

---A picture whose line is gone (the file got shorter, or was reloaded from disk)
---made image.nvim's screenpos() call fail on every redraw. Such a picture is
---taken off the screen instead, and a failing draw never reaches the user.
function M.guard_render()
    local ok, renderer = pcall(require, "image/renderer")
    if not ok or renderer._guarded then return end
    renderer._guarded = true
    local render = renderer.render
    renderer.render = function(img, ...)
        local fine, result = pcall(function(...)
            local buf = img.buffer
            if buf and vim.api.nvim_buf_is_valid(buf) and img.geometry and img.geometry.y
                and img.geometry.y + 1 > vim.api.nvim_buf_line_count(buf) then
                return false
            end
            return render(img, ...)
        end, ...)
        return fine and result or false
    end
end

local timers = {}

---Put a buffer's images where their text now is. render-markdown draws
---headings, tables and code blocks a moment after the text is on screen, and
---that shifts the lines; image.nvim only looks again when the window scrolls,
---so a picture can stay behind where its line used to be.
---@param buf integer
function M.refresh(buf)
    if not done or not vim.api.nvim_buf_is_valid(buf) then return end
    if timers[buf] then timers[buf]:stop() else timers[buf] = vim.uv.new_timer() end
    timers[buf]:start(120, 0, vim.schedule_wrap(function()
        local ok, image = pcall(require, "image")
        if not ok then return end
        pcall(function()
            for _, img in ipairs(image.get_images({ buffer = buf })) do
                local moved, y, x = img:has_extmark_moved()
                if moved and x and y then
                    img.geometry.y, img.geometry.x = y, x
                    img.extmark.row, img.extmark.col = y, x
                end
                img:render()
            end
        end)
    end))
end

---Take every picture off the screen and draw them again where they belong.
function M.redraw()
    if not done then return end
    pcall(function()
        local image = require("image")
        for _, img in ipairs(image.get_images()) do
            img:clear()
            img:render()
        end
    end)
end

vim.api.nvim_create_autocmd("WinScrolled", {
    group = vim.api.nvim_create_augroup("ImageSettle", { clear = true }),
    callback = function(args)
        local win = tonumber(args.match)
        if win and vim.api.nvim_win_is_valid(win) then M.refresh(vim.api.nvim_win_get_buf(win)) end
    end,
})

vim.api.nvim_create_user_command("ImageRedraw", M.redraw, { desc = "Clear pictures and draw them again where their lines are" })

return M
