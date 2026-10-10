---Plugin management through Neovim's built-in vim.pack, as palette commands.
---Updating always goes through the review buffer unless you ask otherwise: it
---lists what changed in each plugin, `:w` applies it and `:q` throws it away.
local M = {}

local function names(filter)
    local out = {}
    for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
        if not filter or filter(plugin) then out[#out + 1] = plugin.spec.name end
    end
    table.sort(out)
    return out
end

---Plugins on disk that the config no longer asks for.
function M.unused() return names(function(p) return not p.active end) end

---Pick one plugin and update just it.
function M.update_one()
    vim.ui.select(names(), { prompt = "Update which plugin?" }, function(choice)
        if choice then vim.pack.update({ choice }) end
    end)
end

---Delete the plugins the config no longer uses, after asking.
function M.clean()
    local unused = M.unused()
    if #unused == 0 then
        vim.notify("No unused plugins", vim.log.levels.INFO, { title = "Plugins" })
        return
    end
    vim.ui.select({ "Delete them", "Keep them" }, {
        prompt = ("Unused plugins: %s"):format(table.concat(unused, ", ")),
    }, function(choice)
        if choice == "Delete them" then
            vim.pack.del(unused)
            vim.notify("Deleted " .. #unused .. " unused plugin(s)", vim.log.levels.INFO, { title = "Plugins" })
        end
    end)
end

---Every installed plugin with the version it is on; Enter opens its page.
function M.list()
    local items = {}
    for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
        local version = plugin.spec.version
        items[#items + 1] = {
            text = plugin.spec.name .. " " .. plugin.spec.src,
            name = plugin.spec.name,
            src = plugin.spec.src,
            rev = (plugin.rev or ""):sub(1, 8),
            version = version and tostring(version) or "default branch",
            active = plugin.active,
        }
    end
    table.sort(items, function(a, b) return a.name < b.name end)

    Snacks.picker.pick({
        title = ("Plugins (%d)  ·  Enter opens the page  ·  Ctrl-Q closes"):format(#items),
        items = items,
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            local align = Snacks.picker.util.align
            return {
                { align(item.name, 28), "SnacksPickerFile" },
                { "  " },
                { align(item.rev, 9), "SnacksPickerDesc" },
                { align(item.version, 16), "SnacksPickerDesc" },
                { item.active and "" or "  unused", "WarningMsg" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if item and item.src then vim.ui.open(item.src) end
        end,
    })
end

function M.open_lockfile()
    vim.cmd("EditorFocus")
    vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/nvim-pack-lock.json"))
end

function M.setup()
    local commands = {
        { "PackUpdate", function() vim.cmd("packupdate") end, "Check every plugin for updates and review them before applying (:w applies, :q discards)" },
        { "PackUpdateNow", function() vim.cmd("packupdate!") end, "Update every plugin immediately, without the review" },
        { "PackStatus", function() vim.cmd("packupdate ++offline") end, "Show what each plugin is on now, without fetching anything" },
        { "PackRestore", function() vim.cmd("packupdate ++lockfile") end, "Put every plugin back to the version in the lockfile" },
        { "PackUpdateOne", M.update_one, "Pick one plugin and update just that" },
        { "PackList", M.list, "List the installed plugins and their versions" },
        { "PackClean", M.clean, "Delete plugins the config no longer uses" },
        { "PackLockfile", M.open_lockfile, "Open the plugin lockfile (nvim-pack-lock.json)" },
        { "ParsersUpdate", function() vim.cmd("TSUpdate") end, "Update the Treesitter language parsers" },
    }
    for _, c in ipairs(commands) do
        vim.api.nvim_create_user_command(c[1], c[2], { nargs = 0, desc = c[3] })
    end
end

return M
