local M = {}
local Snacks = require("snacks")

local state = {
    buf = nil,
    win = nil,
    term_buf = nil,
    term_win = nil,
    devices = {},
    line_devices = {},
    loading = false,
    errors = {},
    generation = 0,
    filter = nil,
    last_device = nil,
}

local function executable(name)
    local path = vim.fn.exepath(name)
    return path ~= "" and path or nil
end

-- android-emulator-setup.sh installs to $(brew --prefix)/share/android-commandlinetools,
-- not the AS-default ~/Library/Android/sdk, and neovim's own $PATH won't pick up
-- the ~/.zshrc block it appends until a new shell (and nvim) is started. Search
-- the known install locations directly so tools are found the moment the script
-- finishes, without requiring a restart.
local function android_sdk_root()
    if vim.env.ANDROID_SDK_ROOT and vim.fn.isdirectory(vim.env.ANDROID_SDK_ROOT) == 1 then
        return vim.env.ANDROID_SDK_ROOT
    end
    if vim.env.ANDROID_HOME and vim.fn.isdirectory(vim.env.ANDROID_HOME) == 1 then
        return vim.env.ANDROID_HOME
    end
    for _, prefix in ipairs({ "/opt/homebrew", "/usr/local" }) do
        local root = prefix .. "/share/android-commandlinetools"
        if vim.fn.isdirectory(root) == 1 then
            return root
        end
    end
    local fallback = vim.fn.expand("~/Library/Android/sdk")
    if vim.fn.isdirectory(fallback) == 1 then
        return fallback
    end
end

local function android_tool(name)
    local on_path = executable(name)
    if on_path then
        return on_path
    end

    local root = android_sdk_root()
    if not root then
        return nil
    end

    for _, subdir in ipairs({ "emulator", "platform-tools", "cmdline-tools/latest/bin" }) do
        local path = root .. "/" .. subdir .. "/" .. name
        if vim.fn.executable(path) == 1 then
            return path
        end
    end
end

local function emulator_path()
    return android_tool("emulator")
end

local function decode_json(text)
    if not text or text == "" then
        return nil
    end

    local ok, value = pcall(vim.json.decode, text)
    return ok and value or nil
end

local function system(command, callback)
    vim.system(command, { text = true }, vim.schedule_wrap(function(result)
        callback(result.code == 0 and result.stdout or nil, result.stderr, result.code)
    end))
end

-- Surface *why* a source failed instead of a bare "unavailable" label, so a
-- transient/environment-specific failure (stale PATH, no network, daemon not
-- running) is diagnosable from the hub itself.
local function describe_failure(label, err, code)
    local detail = (err or ""):match("^%s*(.-)%s*$")
    detail = detail:match("^[^\r\n]*") or detail
    if detail == "" and code then
        detail = "exit " .. tostring(code)
    end
    if detail == "" then
        return label
    end
    return label .. " — " .. detail
end

function M._parse_android_devices(text)
    local devices = {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        local serial, connection, details = line:match("^(%S+)%s+(%S+)%s*(.*)$")
        if serial and serial ~= "List" and connection == "device" then
            local model = details:match("model:(%S+)") or serial
            devices[#devices + 1] = {
                kind = "android_device",
                id = serial,
                name = model:gsub("_", " "),
                state = "Connected",
                physical = not serial:match("^emulator%-"),
            }
        end
    end
    return devices
end

function M._parse_android_avds(text)
    local devices = {}
    for name in (text or ""):gmatch("[^\r\n]+") do
        name = vim.trim(name)
        if name ~= "" then
            devices[#devices + 1] = {
                kind = "android_avd",
                id = name,
                name = name:gsub("_", " "),
                state = "Shutdown",
                physical = false,
            }
        end
    end
    return devices
end

function M._parse_ios_simulators(text)
    local devices = {}
    local data = decode_json(text)
    for runtime, runtime_devices in pairs(data and data.devices or {}) do
        if runtime:match("%.iOS%-") then
            local version = runtime:match("iOS%-(.+)$") or ""
            version = version:gsub("%-", ".")
            for _, device in ipairs(runtime_devices) do
                if device.isAvailable ~= false then
                    devices[#devices + 1] = {
                        kind = "ios_simulator",
                        id = device.udid,
                        name = device.name,
                        os = version,
                        state = device.state,
                        physical = false,
                    }
                end
            end
        end
    end
    return devices
end

function M._parse_ios_devices(text)
    local devices = {}
    local data = decode_json(text)
    for _, device in ipairs(data and data.result and data.result.devices or {}) do
        local connection = device.connectionProperties or {}
        local properties = device.deviceProperties or {}
        local hardware = device.hardwareProperties or {}
        -- devicectl reports "disconnected" for most paired devices until a
        -- build actively opens a tunnel; only "unavailable" means unusable.
        if hardware.platform == "iOS"
            and connection.pairingState == "paired"
            and connection.tunnelState ~= "unavailable"
        then
            local state
            if connection.tunnelState == "connected" then
                state = connection.transportType == "wired" and "Wired" or "Wi-Fi"
            else
                state = "Available"
            end
            devices[#devices + 1] = {
                kind = "ios_device",
                id = hardware.udid or device.identifier,
                core_id = device.identifier,
                udid = hardware.udid,
                name = properties.name or hardware.marketingName or hardware.udid or device.identifier,
                model = hardware.marketingName,
                os = properties.osVersionNumber,
                state = state,
                physical = true,
            }
        end
    end
    return devices
end

local function sort_devices(devices)
    table.sort(devices, function(a, b)
        local a_running = a.state == "Booted" or a.state == "Connected" or a.state == "Wired" or a.state == "Wi-Fi"
        local b_running = b.state == "Booted" or b.state == "Connected" or b.state == "Wired" or b.state == "Wi-Fi"
        if a_running ~= b_running then
            return a_running
        end
        if (a.os or "") ~= (b.os or "") then
            return (a.os or "") > (b.os or "")
        end
        return a.name < b.name
    end)
end

local function is_open()
    return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function render()
    if not is_open() then
        return
    end

    local root = require("workspace").get()
    local lines = {
        " Mobile Device Hub",
        " Workspace  " .. root,
        " <Enter> boot/focus   R run project   x stop   r refresh   q hide",
        " u update packages    c reset package caches    p pin package version   a android SDK setup",
        " s screenshot   U uninstall   e erase/wipe   o open URL   l logs   / filter",
    }
    if state.filter then
        lines[#lines + 1] = " Filter: " .. state.filter .. "  (/ to change, <C-l> to clear)"
    end
    lines[#lines + 1] = ""
    state.line_devices = {}

    local function matches_filter(device)
        if not state.filter then
            return true
        end
        local haystack = table.concat({
            device.name or "", device.model or "", device.state or "", device.os or "",
        }, " "):lower()
        return haystack:find(state.filter:lower(), 1, true) ~= nil
    end

    local sections = {
        { title = "iOS — Connected Devices", kind = "ios_device" },
        { title = "iOS — Simulators", kind = "ios_simulator" },
        { title = "Android — Connected Devices", kind = "android_device" },
        { title = "Android — Virtual Devices", kind = "android_avd" },
    }

    for _, section in ipairs(sections) do
        lines[#lines + 1] = " " .. section.title
        local found = false
        for _, device in ipairs(state.devices) do
            if device.kind == section.kind and matches_filter(device) then
                found = true
                local active = device.state ~= "Shutdown"
                local icon = active and "●" or "○"
                local detail = device.state
                if device.os and device.os ~= "" then
                    detail = detail .. " · " .. device.os
                end
                if device.model and device.model ~= device.name then
                    detail = detail .. " · " .. device.model
                end
                lines[#lines + 1] = string.format("   %s %-34s %s", icon, device.name, detail)
                state.line_devices[#lines] = device
            end
        end
        if not found then
            lines[#lines + 1] = state.loading and "   … checking"
                or (state.filter and "   — no matches" or "   — none available")
        end
        lines[#lines + 1] = ""
    end

    if #state.errors > 0 then
        lines[#lines + 1] = " Notes"
        for _, message in ipairs(state.errors) do
            lines[#lines + 1] = "   " .. message
        end
    end

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modifiable = false

    local namespace = vim.api.nvim_create_namespace("mobile_device_hub")
    vim.api.nvim_buf_clear_namespace(state.buf, namespace, 0, -1)
    vim.api.nvim_buf_add_highlight(state.buf, namespace, "Title", 0, 1, -1)
    vim.api.nvim_buf_add_highlight(state.buf, namespace, "Comment", 1, 1, -1)
    vim.api.nvim_buf_add_highlight(state.buf, namespace, "Comment", 2, 1, -1)
    for index, line in ipairs(lines) do
        if line:match("^ iOS —") or line:match("^ Android —") or line == " Notes" then
            vim.api.nvim_buf_add_highlight(state.buf, namespace, "Special", index - 1, 1, -1)
        elseif line:match("   ●") then
            vim.api.nvim_buf_add_highlight(state.buf, namespace, "DiagnosticOk", index - 1, 3, 6)
        elseif line:match("   ○") then
            vim.api.nvim_buf_add_highlight(state.buf, namespace, "Comment", index - 1, 3, 6)
        end
    end
end

function M.refresh(on_done)
    state.generation = state.generation + 1
    local generation = state.generation

    state.loading = true
    state.devices = {}
    state.errors = {}
    render()

    local pending = 0
    local function begin()
        pending = pending + 1
    end
    -- Boot/stop actions and manual refreshes can overlap; a stale in-flight
    -- call landing after a newer refresh has reset state would otherwise mix
    -- results from two different runs (e.g. a real device list alongside a
    -- leftover failure note from an earlier, since-superseded request).
    local function finish(devices, error_message)
        if generation ~= state.generation then
            return
        end
        vim.list_extend(state.devices, devices or {})
        if error_message then
            state.errors[#state.errors + 1] = error_message
        end
        pending = pending - 1
        if pending == 0 then
            state.loading = false
            sort_devices(state.devices)
            render()
            if on_done then on_done() end
        end
    end

    -- `output and nil or describe_failure(...)` looks like a ternary but
    -- always evaluates to describe_failure(...): Lua's and/or trick breaks
    -- the moment the "true" branch is itself falsy (nil). That silently
    -- attached a failure note to every refresh regardless of success.
    local function failure_or_nil(output, label, err, code)
        if output then
            return nil
        end
        return describe_failure(label, err, code)
    end

    if executable("xcrun") then
        begin()
        system({ "xcrun", "simctl", "list", "devices", "available", "--json" }, function(output, err, code)
            finish(M._parse_ios_simulators(output), failure_or_nil(output, "iOS Simulator service unavailable", err, code))
        end)

        begin()
        local json_path = vim.fn.tempname() .. ".json"
        system({ "xcrun", "devicectl", "list", "devices", "--json-output", json_path }, function(_, err, code)
            local output
            if code == 0 and vim.fn.filereadable(json_path) == 1 then
                output = table.concat(vim.fn.readfile(json_path), "\n")
            end
            vim.uv.fs_unlink(json_path)
            finish(M._parse_ios_devices(output), failure_or_nil(output, "Connected iOS devices unavailable", err, code))
        end)
    else
        state.errors[#state.errors + 1] = "Xcode command-line tools not found"
    end

    local adb = android_tool("adb")
    if adb then
        begin()
        system({ adb, "devices", "-l" }, function(output, err, code)
            finish(M._parse_android_devices(output), failure_or_nil(output, "ADB server unavailable", err, code))
        end)
    else
        state.errors[#state.errors + 1] = "ADB not found"
    end

    local emulator = emulator_path()
    if emulator then
        begin()
        system({ emulator, "-list-avds" }, function(output, err, code)
            finish(M._parse_android_avds(output), failure_or_nil(output, "Android emulator list unavailable", err, code))
        end)
    else
        state.errors[#state.errors + 1] = "Android emulator not found"
    end

    if pending == 0 then
        state.loading = false
        render()
        if on_done then on_done() end
    end
end

local function selected_device()
    if not is_open() then
        return nil
    end
    local device = state.line_devices[vim.api.nvim_win_get_cursor(state.win)[1]]
    if device then
        state.last_device = { kind = device.kind, id = device.id }
    end
    return device
end

-- Best-effort bundle/package id to prefill uninstall/deep-link prompts, from
-- whatever project xcodebuild.nvim already has configured (if any).
local function default_bundle_id()
    local ok, config = pcall(require, "xcodebuild.project.config")
    return (ok and config.settings and config.settings.bundleId) or ""
end

-- vim.fn.input() raises a Lua error on <C-c> (keyboard-interrupt) instead of
-- returning cleanly like Escape does; treat both as "cancelled" uniformly.
local function safe_input(prompt, default)
    local ok, value = pcall(vim.fn.input, prompt, default or "")
    if not ok or value == "" then
        return nil
    end
    return value
end

local function safe_confirm(prompt, choices)
    local ok, choice = pcall(vim.fn.confirm, prompt, choices)
    if not ok then
        return 0
    end
    return choice
end

-- Discover installed apps so bundle-id prompts can offer a picker instead of
-- free typing. Each platform needs a different source and shape:
--   simulator: `simctl listapps` prints an OpenStep-style plist (not JSON),
--     but `plutil -convert json` normalizes it; keep only user-installed apps.
--   physical iOS: `devicectl device info apps --json-output` is already JSON
--     and already excludes non-removable system apps by default.
--   Android: `pm list packages -3` lists third-party packages only.
local function discover_bundle_ids(device, callback)
    if device.kind == "ios_simulator" then
        local plist_path = vim.fn.tempname() .. ".plist"
        local json_path = vim.fn.tempname() .. ".json"
        local script = string.format(
            "xcrun simctl listapps %s > %s && plutil -convert json -o %s %s",
            vim.fn.shellescape(device.id), vim.fn.shellescape(plist_path),
            vim.fn.shellescape(json_path), vim.fn.shellescape(plist_path)
        )
        system({ "sh", "-c", script }, function(_, _, code)
            local apps = {}
            if code == 0 and vim.fn.filereadable(json_path) == 1 then
                local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(json_path), "\n"))
                if ok and type(data) == "table" then
                    for bundle_id, info in pairs(data) do
                        if info.ApplicationType == "User" then
                            apps[#apps + 1] = { id = bundle_id, label = info.CFBundleDisplayName or info.CFBundleName or bundle_id }
                        end
                    end
                end
            end
            vim.uv.fs_unlink(plist_path)
            vim.uv.fs_unlink(json_path)
            callback(apps)
        end)
    elseif device.kind == "ios_device" then
        local json_path = vim.fn.tempname() .. ".json"
        system({ "xcrun", "devicectl", "device", "info", "apps", "--device", device.id, "--json-output", json_path }, function(_, _, code)
            local apps = {}
            if code == 0 and vim.fn.filereadable(json_path) == 1 then
                local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(json_path), "\n"))
                if ok and data.result and data.result.apps then
                    for _, info in ipairs(data.result.apps) do
                        apps[#apps + 1] = { id = info.bundleIdentifier, label = info.name or info.bundleIdentifier }
                    end
                end
            end
            vim.uv.fs_unlink(json_path)
            callback(apps)
        end)
    elseif device.kind == "android_device" or device.kind == "android_avd" then
        local adb = android_tool("adb")
        if not adb then
            callback({})
            return
        end
        system({ adb, "-s", device.id, "shell", "pm", "list", "packages", "-3" }, function(output)
            local apps = {}
            for line in (output or ""):gmatch("[^\r\n]+") do
                local pkg = line:match("^package:(.+)$")
                if pkg then apps[#apps + 1] = { id = pkg, label = pkg } end
            end
            callback(apps)
        end)
    else
        callback({})
    end
end

-- Shows a picker of installed apps; falls back to a free-text prompt when
-- discovery finds nothing (empty device, adb/devicectl hiccup) or the user
-- explicitly wants to type one (e.g. an app not yet installed).
local function pick_bundle_id(device, prompt, on_pick)
    local function fallback()
        local bundle_id = safe_input(prompt, default_bundle_id())
        if bundle_id then on_pick(bundle_id) end
    end

    discover_bundle_ids(device, function(apps)
        if #apps == 0 then
            fallback()
            return
        end

        table.sort(apps, function(a, b) return a.label < b.label end)
        Snacks.picker.pick({
            title = "Apps on " .. device.name,
            finder = function()
                local items = {}
                for _, app in ipairs(apps) do
                    items[#items + 1] = { text = app.label .. " " .. app.id, label = app.label, id = app.id }
                end
                items[#items + 1] = { text = "Type a bundle id manually", label = "Type a bundle id manually…", id = nil }
                return items
            end,
            format = function(item)
                if not item.id then
                    return { { item.label, "Comment" } }
                end
                return {
                    { item.label,      "Function" },
                    { "  " .. item.id, "Comment" },
                }
            end,
            confirm = function(picker, item)
                picker:close()
                if not item then return end
                vim.schedule(function()
                    if item.id then
                        on_pick(item.id)
                    else
                        fallback()
                    end
                end)
            end,
        })
    end)
end

local function focus_or_boot()
    local device = selected_device()
    if not device then
        return
    end

    if device.kind == "ios_simulator" then
        if device.state ~= "Booted" then
            system({ "xcrun", "simctl", "boot", device.id }, function(_, error, code)
                if code ~= 0 and not (error or ""):match("current state: Booted") then
                    vim.notify(error or "Could not boot simulator", vim.log.levels.ERROR)
                end
                M.refresh()
            end)
        end
        vim.fn.jobstart({ "open", "-a", "Simulator" }, { detach = true })
    elseif device.kind == "android_avd" then
        local emulator = emulator_path()
        if emulator then
            -- Explicit host GPU acceleration even for AVDs not created by
            -- android-emulator-setup.sh (its config.ini already defaults to
            -- this, but a stale/manually-created AVD may not).
            vim.fn.jobstart({
                emulator, "-avd", device.id,
                "-gpu", "host",
                "-no-boot-anim",
                "-netdelay", "none",
                "-netspeed", "full",
            }, { detach = true })
            vim.notify("Starting " .. device.name, vim.log.levels.INFO)
            vim.defer_fn(M.refresh, 2500)
        end
    else
        vim.notify(device.name .. " is ready for this workspace", vim.log.levels.INFO)
    end
end

local function stop_device()
    local device = selected_device()
    if not device then
        return
    end

    if device.kind == "ios_simulator" and device.state == "Booted" then
        system({ "xcrun", "simctl", "shutdown", device.id }, function(_, error, code)
            if code ~= 0 then
                vim.notify(error or "Could not stop simulator", vim.log.levels.ERROR)
            end
            M.refresh()
        end)
    elseif device.kind == "android_device" and not device.physical then
        system({ android_tool("adb") or "adb", "-s", device.id, "emu", "kill" }, function(_, error, code)
            if code ~= 0 then
                vim.notify(error or "Could not stop emulator", vim.log.levels.ERROR)
            end
            M.refresh()
        end)
    else
        vim.notify("Real devices are disconnected physically, not stopped here", vim.log.levels.INFO)
    end
end

local function set_filter()
    -- Cancelling (<C-c> or empty Enter) leaves the current filter untouched;
    -- <C-l> is the explicit way to clear it.
    local filter = safe_input("Filter devices: ", state.filter or "")
    if filter then
        state.filter = filter
        render()
    end
end

local function clear_filter()
    if state.filter then
        state.filter = nil
        render()
    end
end

local function screenshot_device()
    local device = selected_device()
    if not device then return end

    local path = string.format(
        "%s/%s-%s.png",
        vim.fn.expand("~/Desktop"),
        (device.name:gsub("%s+", "-")),
        os.date("%Y%m%d-%H%M%S")
    )

    local function report(code, err)
        if code == 0 then
            vim.notify("Screenshot saved: " .. path, vim.log.levels.INFO)
            vim.fn.jobstart({ "open", path }, { detach = true })
        else
            vim.notify(err or "Screenshot failed", vim.log.levels.ERROR)
        end
    end

    if device.kind == "ios_simulator" then
        system({ "xcrun", "simctl", "io", device.id, "screenshot", path }, function(_, err, code)
            report(code, err)
        end)
    elseif device.kind == "android_device" or device.kind == "android_avd" then
        local adb = android_tool("adb")
        if not adb then
            vim.notify("adb not found", vim.log.levels.ERROR)
            return
        end
        local script = string.format(
            "%s -s %s exec-out screencap -p > %s",
            vim.fn.shellescape(adb), vim.fn.shellescape(device.id), vim.fn.shellescape(path)
        )
        system({ "sh", "-c", script }, function(_, err, code)
            report(code, err)
        end)
    else
        vim.notify("Screenshots aren't available for physical iOS devices from the CLI — use Xcode's Devices window", vim.log.levels.WARN)
    end
end

local function uninstall_app()
    local device = selected_device()
    if not device then return end

    pick_bundle_id(device, "Bundle/package identifier to uninstall: ", function(bundle_id)
        if safe_confirm("Uninstall " .. bundle_id .. " from " .. device.name .. "?", "&Uninstall\n&Cancel") ~= 1 then
            return
        end

        local function report(ok, err)
            vim.notify(ok and ("Uninstalled " .. bundle_id) or (err or "Uninstall failed"),
                ok and vim.log.levels.INFO or vim.log.levels.ERROR)
        end

        if device.kind == "ios_simulator" then
            system({ "xcrun", "simctl", "uninstall", device.id, bundle_id }, function(_, err, code)
                report(code == 0, err)
            end)
        elseif device.kind == "ios_device" then
            system({ "xcrun", "devicectl", "device", "uninstall", "app", "--device", device.id, bundle_id }, function(_, err, code)
                report(code == 0, err)
            end)
        elseif device.kind == "android_device" or device.kind == "android_avd" then
            local adb = android_tool("adb")
            if not adb then
                vim.notify("adb not found", vim.log.levels.ERROR)
                return
            end
            system({ adb, "-s", device.id, "uninstall", bundle_id }, function(output, err, code)
                report(code == 0 and output and output:find("Success", 1, true) ~= nil, err or output)
            end)
        end
    end)
end

local function erase_device()
    local device = selected_device()
    if not device then return end

    if device.kind == "ios_simulator" then
        if safe_confirm("Erase all content and settings on " .. device.name .. "?", "&Erase\n&Cancel") ~= 1 then
            return
        end
        local function do_erase()
            system({ "xcrun", "simctl", "erase", device.id }, function(_, err, code)
                vim.notify(code == 0 and ("Erased " .. device.name) or (err or "Erase failed"),
                    code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
                M.refresh()
            end)
        end
        if device.state == "Booted" then
            system({ "xcrun", "simctl", "shutdown", device.id }, function() do_erase() end)
        else
            do_erase()
        end
    elseif device.kind == "android_avd" then
        if device.state ~= "Shutdown" then
            vim.notify("Stop the emulator first, then erase", vim.log.levels.WARN)
            return
        end
        if safe_confirm("Wipe data on " .. device.name .. " and boot fresh?", "&Wipe\n&Cancel") ~= 1 then
            return
        end
        local emulator = emulator_path()
        if emulator then
            vim.fn.jobstart({
                emulator, "-avd", device.id, "-wipe-data",
                "-gpu", "host", "-no-boot-anim",
            }, { detach = true })
            vim.notify("Wiping and starting " .. device.name, vim.log.levels.INFO)
            vim.defer_fn(M.refresh, 2500)
        end
    else
        vim.notify("Erase isn't available for this device type from the CLI", vim.log.levels.WARN)
    end
end

local function open_deep_link()
    local device = selected_device()
    if not device then return end

    local url = safe_input("URL to open on " .. device.name .. ": ")
    if not url then return end

    if device.kind == "ios_simulator" then
        system({ "xcrun", "simctl", "openurl", device.id, url }, function(_, err, code)
            if code ~= 0 then vim.notify(err or "Could not open URL", vim.log.levels.ERROR) end
        end)
    elseif device.kind == "android_device" or device.kind == "android_avd" then
        local adb = android_tool("adb")
        if not adb then
            vim.notify("adb not found", vim.log.levels.ERROR)
            return
        end
        system({ adb, "-s", device.id, "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", url }, function(_, err, code)
            if code ~= 0 then vim.notify(err or "Could not open URL", vim.log.levels.ERROR) end
        end)
    else
        vim.notify("Opening URLs isn't available for physical iOS devices from the CLI", vim.log.levels.WARN)
    end
end

local function package_info(root)
    local path = root .. "/package.json"
    if vim.fn.filereadable(path) ~= 1 then
        return {}
    end
    local data = decode_json(table.concat(vim.fn.readfile(path), "\n")) or {}
    return vim.tbl_extend("force", data.dependencies or {}, data.devDependencies or {})
end

local function close_hub_terminal()
    -- Closing the window alone leaves long-running jobs (log stream, logcat)
    -- orphaned in the background; stop the job explicitly too.
    if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
        local job = vim.b[state.term_buf].terminal_job_id
        if job then pcall(vim.fn.jobstop, job) end
    end
    if state.term_win and vim.api.nvim_win_is_valid(state.term_win) then
        vim.api.nvim_win_close(state.term_win, true)
    end
    state.term_win = nil
    state.term_buf = nil
end

-- Docked as a floating window directly under the hub's own floating window
-- (relative="win", anchored to state.win) so command output reads as part of
-- the hub instead of a disconnected split elsewhere on screen.
local function open_hub_terminal(root, title, command, on_exit)
    close_hub_terminal()

    local hub_config = vim.api.nvim_win_get_config(state.win)
    local available = vim.o.lines - (hub_config.row + hub_config.height) - 4
    local height = math.max(6, math.min(16, available))

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",
        win = state.win,
        row = hub_config.height + 2,
        col = 0,
        width = hub_config.width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })
    vim.wo[win].winhighlight = "WinSeparator:OilWinSeparator"
    state.term_win, state.term_buf = win, buf

    local parts = {}
    for _, value in ipairs(command) do
        parts[#parts + 1] = vim.fn.shellescape(value)
    end

    local job = vim.fn.jobstart(table.concat(parts, " "), {
        term = true,
        cwd = root,
        on_exit = on_exit and vim.schedule_wrap(on_exit) or nil,
    })
    if job <= 0 then
        vim.notify("Could not start: " .. title, vim.log.levels.ERROR)
        close_hub_terminal()
        return
    end

    vim.keymap.set("t", "<Esc>", function()
        vim.cmd("stopinsert")
        if is_open() then vim.api.nvim_set_current_win(state.win) end
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "q", close_hub_terminal, { buffer = buf, silent = true })

    vim.cmd("startinsert")
end

local function terminal_command(root, title, command, on_exit)
    if is_open() then
        open_hub_terminal(root, title, command, on_exit)
        return
    end

    -- Hub isn't open (e.g. a global :XcodeUpdatePackages/:AndroidEmulatorSetup
    -- invocation) — fall back to a normal floaterm split.
    local parts = {}
    for _, value in ipairs(command) do
        parts[#parts + 1] = vim.fn.shellescape(value)
    end
    pcall(vim.cmd, "EditorFocus")
    local safe_title = (title:gsub("%s+", "-"))
    vim.cmd(string.format(
        "FloatermNew --cwd=%s --title=%s %s",
        vim.fn.fnameescape(root),
        vim.fn.fnameescape(safe_title),
        table.concat(parts, " ")
    ))
    if on_exit then
        vim.api.nvim_create_autocmd("TermClose", {
            buffer = vim.api.nvim_get_current_buf(),
            once = true,
            callback = function() vim.schedule(on_exit) end,
        })
    end
end

local function stream_logs()
    local device = selected_device()
    if not device then return end

    local root = require("workspace").get()
    if device.kind == "ios_simulator" then
        terminal_command(root, "log-" .. device.name, { "xcrun", "simctl", "spawn", device.id, "log", "stream", "--style", "compact" })
    elseif device.kind == "android_device" or device.kind == "android_avd" then
        local adb = android_tool("adb")
        if not adb then
            vim.notify("adb not found", vim.log.levels.ERROR)
            return
        end
        terminal_command(root, "logcat-" .. device.name, { adb, "-s", device.id, "logcat" })
    elseif device.kind == "ios_device" then
        -- devicectl has no system-wide "log stream" like simctl; the closest
        -- equivalent is (re)launching the app with its console attached,
        -- which streams stdout/stderr until the app exits.
        pick_bundle_id(device, "Bundle identifier to launch with console: ", function(bundle_id)
            terminal_command(root, "console-" .. device.name, {
                "xcrun", "devicectl", "device", "process", "launch",
                "--device", device.id, "--console", "--terminate-existing", bundle_id,
            })
        end)
    end
end

local function android_setup()
    local script = vim.fn.expand("~/.config/scripts/android-emulator-setup.sh")
    if vim.fn.filereadable(script) ~= 1 then
        vim.notify("Android setup script not found: " .. script, vim.log.levels.ERROR)
        return
    end
    terminal_command(vim.fn.expand("~"), "android-emulator-setup", { script }, M.refresh)
end

local function ensure_configured_project(prompt)
    if not _G.xcodebuild_initialized then
        require("xcodebuild").setup({
            show_build_progress_bar = true,
            logs = { auto_open_on_success = false, auto_open_on_error = true },
        })
        _G.xcodebuild_initialized = true
    end

    local config = require("xcodebuild.project.config")
    if not config.settings.projectFile or not config.settings.scheme then
        vim.notify("Choose the Xcode project and scheme once; then " .. prompt, vim.log.levels.INFO)
        require("xcodebuild.actions").configure_project()
        return nil
    end
    return config
end

local function run_native_ios(device)
    local config = ensure_configured_project("press R again")
    if not config then return end

    config.set_destination({
        id = device.id,
        name = device.name,
        os = device.os,
        platform = device.physical and "iOS" or "iOS Simulator",
    })
    require("xcodebuild.actions").build_and_run()
end

local function has_suffix(path, suffix)
    return path:sub(-#suffix) == suffix
end

-- xcodebuild.nvim itself picks -project vs -workspace this same way
-- (lua/xcodebuild/core/xcode.lua): only a literal .xcodeproj takes -project,
-- anything else (namely .xcworkspace) needs -workspace.
local function xcodebuild_project_flag(project_file)
    return has_suffix(project_file, ".xcodeproj") and "-project" or "-workspace"
end

-- The workspace's own Package.resolved and the sibling .xcodeproj's internal
-- copy can drift; clear every copy we can find so `-resolvePackageDependencies`
-- can't silently reuse a stale lock, regardless of which file type is configured.
local function package_resolved_paths(project_file)
    local dir = vim.fs.dirname(project_file)
    local paths = {}

    if has_suffix(project_file, ".xcworkspace") then
        paths[#paths + 1] = project_file .. "/xcshareddata/swiftpm/Package.resolved"
    else
        paths[#paths + 1] = project_file .. "/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    end

    for _, workspace in ipairs(vim.fn.glob(dir .. "/*.xcworkspace", false, true)) do
        paths[#paths + 1] = workspace .. "/xcshareddata/swiftpm/Package.resolved"
    end
    for _, xcodeproj in ipairs(vim.fn.glob(dir .. "/*.xcodeproj", false, true)) do
        paths[#paths + 1] = xcodeproj .. "/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    end

    local seen, unique = {}, {}
    for _, path in ipairs(paths) do
        if not seen[path] and vim.fn.filereadable(path) == 1 then
            seen[path] = true
            unique[#unique + 1] = path
        end
    end
    return unique
end

local function resolve_packages_script(project_file, scheme, extra)
    return (extra and (extra .. " && ") or "") .. string.format(
        "xcodebuild -resolvePackageDependencies %s %s -scheme %s",
        xcodebuild_project_flag(project_file),
        vim.fn.shellescape(project_file),
        vim.fn.shellescape(scheme)
    )
end

local function update_packages()
    local config = ensure_configured_project("try again")
    if not config then return end

    local project_file = config.settings.projectFile
    local resolved = package_resolved_paths(project_file)

    if safe_confirm(
        string.format("Delete %d Package.resolved file(s) and update to the latest resolvable versions?", #resolved),
        "&Update\n&Cancel"
    ) ~= 1 then
        return
    end

    local rm = #resolved > 0
        and ("rm -f " .. table.concat(vim.tbl_map(vim.fn.shellescape, resolved), " "))
        or nil
    local root = config.settings.workingDirectory or require("workspace").get()
    terminal_command(root, "spm-update", { "sh", "-c", resolve_packages_script(project_file, config.settings.scheme, rm) })
end

-- config.settings.buildDir looks like ".../DerivedData/App-abc123/Build/Products";
-- its parent is the DerivedData folder holding the cached SourcePackages checkout.
local function derived_data_source_packages(config)
    local build_dir = config.settings.buildDir
    if not build_dir then return nil end
    return build_dir:gsub("/Build/Products/?.*$", "") .. "/SourcePackages"
end

local function reset_package_caches()
    local config = ensure_configured_project("try again")
    if not config then return end

    if safe_confirm(
        "Reset the Swift Package Manager cache and re-resolve dependencies?",
        "&Reset\n&Cancel"
    ) ~= 1 then
        return
    end

    local targets = { vim.fn.expand("~/Library/Caches/org.swift.swiftpm") }
    local source_packages = derived_data_source_packages(config)
    if source_packages then targets[#targets + 1] = source_packages end

    local rm = "rm -rf " .. table.concat(vim.tbl_map(vim.fn.shellescape, targets), " ")
    local root = config.settings.workingDirectory or require("workspace").get()
    terminal_command(root, "spm-reset-cache", { "sh", "-c", resolve_packages_script(config.settings.projectFile, config.settings.scheme, rm) })
end

-- ============================================================
-- Package version picker
--
-- xcodebuild has no CLI to change one package's pinned version — that rule
-- lives in project.pbxproj's XCRemoteSwiftPackageReference blocks. We edit
-- that file directly with a brace-counting scan (not a regex spanning the
-- nested braces, which would be fragile) so only the target package's own
-- `requirement = { ... };` block is touched — everything else in the file,
-- including formatting, is left byte-for-byte alone. Validated against a
-- copy of a real project.pbxproj with `plutil -lint` before ever writing to
-- a live file.
-- ============================================================

local function find_pbxproj_path(project_file)
    if has_suffix(project_file, ".xcodeproj") then
        return project_file .. "/project.pbxproj"
    end
    local dir = vim.fs.dirname(project_file)
    local candidates = vim.fn.glob(dir .. "/*.xcodeproj", false, true)
    return candidates[1] and (candidates[1] .. "/project.pbxproj") or nil
end

local function find_matching_brace(text, open_pos)
    local depth = 0
    local i = open_pos
    local len = #text
    while i <= len do
        local c = text:sub(i, i)
        if c == "{" then
            depth = depth + 1
        elseif c == "}" then
            depth = depth - 1
            if depth == 0 then return i end
        end
        i = i + 1
    end
end

local function parse_package_references(text)
    local section_start = text:find("/%* Begin XCRemoteSwiftPackageReference section %*/")
    local section_end = text:find("/%* End XCRemoteSwiftPackageReference section %*/")
    if not section_start or not section_end then return {} end

    local packages = {}
    local search_from = section_start
    while true do
        local entry_start, header_end, id, name = text:find(
            '(%x+) /%* XCRemoteSwiftPackageReference "([^"]+)" %*/ = {', search_from
        )
        if not entry_start or entry_start > section_end then break end
        local close_brace_pos = find_matching_brace(text, header_end)
        if not close_brace_pos then break end
        local body = text:sub(entry_start, close_brace_pos)

        packages[#packages + 1] = {
            id = id,
            name = name,
            url = body:match('repositoryURL = "([^"]+)"'),
            kind = body:match("kind = (%a+);"),
            minimumVersion = body:match("minimumVersion = ([%w%.%-]+);"),
            version = body:match("version = ([%w%.%-]+);"),
            revision = body:match("revision = ([%w]+);"),
            branch = body:match('branch = "?([^;"]+)"?;'),
            entry_start = entry_start,
            entry_end = close_brace_pos,
        }
        search_from = close_brace_pos + 1
    end
    return packages
end

local function find_requirement_range(text, entry_start, entry_close)
    local body = text:sub(entry_start, entry_close)
    local rel_start, rel_header_end = body:find("requirement = {")
    if not rel_start then return nil end
    -- own the leading indentation on that line too, so the replacement's
    -- own indentation doesn't stack on top of the original's.
    while rel_start > 1 and body:sub(rel_start - 1, rel_start - 1):match("[ \t]") do
        rel_start = rel_start - 1
    end
    local abs_open_brace = entry_start + rel_header_end - 1
    local abs_close_brace = find_matching_brace(text, abs_open_brace)
    if not abs_close_brace then return nil end
    local abs_end = abs_close_brace
    if text:sub(abs_close_brace + 1, abs_close_brace + 1) == ";" then
        abs_end = abs_close_brace + 1
    end
    return entry_start + rel_start - 1, abs_end
end

local function pbxproj_scalar(value)
    if value:match("^[%w%.%-]+$") then
        return value
    end
    return '"' .. value:gsub('"', '\\"') .. '"'
end

local function format_requirement(choice)
    local lines = { "\t\t\trequirement = {" }
    if choice.kind == "exactVersion" then
        lines[#lines + 1] = "\t\t\t\tkind = exactVersion;"
        lines[#lines + 1] = "\t\t\t\tversion = " .. pbxproj_scalar(choice.value) .. ";"
    elseif choice.kind == "upToNextMajorVersion" then
        lines[#lines + 1] = "\t\t\t\tkind = upToNextMajorVersion;"
        lines[#lines + 1] = "\t\t\t\tminimumVersion = " .. pbxproj_scalar(choice.value) .. ";"
    elseif choice.kind == "branch" then
        lines[#lines + 1] = "\t\t\t\tkind = branch;"
        lines[#lines + 1] = "\t\t\t\tbranch = " .. pbxproj_scalar(choice.value) .. ";"
    elseif choice.kind == "revision" then
        lines[#lines + 1] = "\t\t\t\tkind = revision;"
        lines[#lines + 1] = "\t\t\t\trevision = " .. pbxproj_scalar(choice.value) .. ";"
    end
    lines[#lines + 1] = "\t\t\t};"
    return table.concat(lines, "\n")
end

local function package_current_requirement(pkg)
    return pkg.version or pkg.minimumVersion or pkg.branch or pkg.revision or "?"
end

-- Semver-ish sort, newest first; tags that don't look like versions
-- (diagnostic/experiment branches some repos tag) are dropped entirely.
local function fetch_package_versions(url, callback)
    if not url then
        callback({})
        return
    end
    system({ "git", "ls-remote", "--tags", url }, function(output)
        local seen, tags = {}, {}
        for line in (output or ""):gmatch("[^\r\n]+") do
            local ref = line:match("refs/tags/(.+)$")
            if ref then
                ref = ref:gsub("%^{}$", "")
                if ref:match("^v?%d+%.%d+%.%d+") and not seen[ref] then
                    seen[ref] = true
                    tags[#tags + 1] = ref
                end
            end
        end
        table.sort(tags, function(a, b)
            local function nums(s)
                local parts = {}
                for n in s:gmatch("%d+") do parts[#parts + 1] = tonumber(n) end
                return parts
            end
            local na, nb = nums(a), nums(b)
            for i = 1, math.max(#na, #nb) do
                local x, y = na[i] or 0, nb[i] or 0
                if x ~= y then return x > y end
            end
            return a > b
        end)
        callback(tags)
    end)
end

local function apply_package_requirement(pbxproj_path, pkg, choice)
    local text = table.concat(vim.fn.readfile(pbxproj_path), "\n")
    local start_pos, end_pos = find_requirement_range(text, pkg.entry_start, pkg.entry_end)
    if not start_pos then
        vim.notify("Could not locate the requirement block for " .. pkg.name, vim.log.levels.ERROR)
        return
    end

    local new_text = text:sub(1, start_pos - 1) .. format_requirement(choice) .. text:sub(end_pos + 1)
    vim.fn.writefile(vim.split(new_text, "\n"), pbxproj_path)
    vim.notify(string.format("%s pinned to %s (%s)", pkg.name, choice.value, choice.kind), vim.log.levels.INFO)

    if safe_confirm("Re-resolve packages now?", "&Resolve\n&Later") ~= 1 then
        return
    end
    local ok, config = pcall(require, "xcodebuild.project.config")
    if not ok or not config.settings.projectFile or not config.settings.scheme then
        return
    end
    local resolved = package_resolved_paths(config.settings.projectFile)
    local rm = #resolved > 0
        and ("rm -f " .. table.concat(vim.tbl_map(vim.fn.shellescape, resolved), " "))
        or nil
    local root = config.settings.workingDirectory or require("workspace").get()
    terminal_command(root, "spm-pin-" .. pkg.name, {
        "sh", "-c", resolve_packages_script(config.settings.projectFile, config.settings.scheme, rm),
    })
end

local function choose_package_version(pbxproj_path, pkg)
    if not pkg.url then
        vim.notify(pkg.name .. " has no repository URL (local or binary package?)", vim.log.levels.WARN)
        return
    end

    vim.notify("Fetching available versions for " .. pkg.name .. "…", vim.log.levels.INFO)
    fetch_package_versions(pkg.url, function(tags)
        Snacks.picker.pick({
            title = "Versions — " .. pkg.name .. " (currently " .. package_current_requirement(pkg) .. ")",
            finder = function()
                local items = {}
                for _, tag in ipairs(tags) do
                    items[#items + 1] = { text = tag, label = tag, choice = { kind = "exactVersion", value = tag } }
                end
                items[#items + 1] = { text = "manual-branch", label = "Track a branch…", manual = "branch" }
                items[#items + 1] = { text = "manual-revision", label = "Pin to a revision (SHA)…", manual = "revision" }
                items[#items + 1] = { text = "manual-major", label = "Up to next major from a version…", manual = "upToNextMajorVersion" }
                return items
            end,
            format = function(item)
                if item.manual then
                    return { { item.label, "Comment" } }
                end
                return { { item.label, "Function" } }
            end,
            confirm = function(picker, item)
                picker:close()
                if not item then return end
                vim.schedule(function()
                    if item.choice then
                        apply_package_requirement(pbxproj_path, pkg, item.choice)
                        return
                    end
                    local prompts = {
                        branch = "Branch name: ",
                        revision = "Revision (SHA): ",
                        upToNextMajorVersion = "Minimum version: ",
                    }
                    local value = safe_input(prompts[item.manual])
                    if value then
                        apply_package_requirement(pbxproj_path, pkg, { kind = item.manual, value = value })
                    end
                end)
            end,
        })
    end)
end

local function pick_package_version()
    local config = ensure_configured_project("try again")
    if not config then return end

    local pbxproj_path = find_pbxproj_path(config.settings.projectFile)
    if not pbxproj_path or vim.fn.filereadable(pbxproj_path) ~= 1 then
        vim.notify("Could not find project.pbxproj", vim.log.levels.ERROR)
        return
    end

    local text = table.concat(vim.fn.readfile(pbxproj_path), "\n")
    local packages = parse_package_references(text)
    if #packages == 0 then
        vim.notify("No Swift package references found in this project", vim.log.levels.WARN)
        return
    end

    Snacks.picker.pick({
        title = "Swift Packages",
        finder = function()
            local items = {}
            for _, pkg in ipairs(packages) do
                items[#items + 1] = {
                    text = pkg.name .. " " .. package_current_requirement(pkg),
                    label = pkg.name,
                    detail = (pkg.kind or "?") .. " " .. package_current_requirement(pkg),
                    pkg = pkg,
                }
            end
            return items
        end,
        format = function(item)
            return {
                { item.label,          "Function" },
                { "  " .. item.detail, "Comment" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function() choose_package_version(pbxproj_path, item.pkg) end)
        end,
    })
end

local function run_project()
    local device = selected_device()
    if not device then
        vim.notify("Select a device first", vim.log.levels.INFO)
        return
    end

    if device.kind == "ios_simulator" and device.state ~= "Booted" then
        focus_or_boot()
    elseif device.kind == "android_avd" then
        focus_or_boot()
        vim.notify("Run again after the Android emulator appears as connected", vim.log.levels.INFO)
        return
    end

    local root = require("workspace").get()
    local dependencies = package_info(root)
    local ios = device.kind:match("^ios_") ~= nil

    if dependencies.expo then
        terminal_command(root, "mobile-" .. device.name, {
            "npx", "expo", ios and "run:ios" or "run:android", "--device", device.id,
        })
    elseif dependencies["react-native"] then
        if ios then
            terminal_command(root, "mobile-" .. device.name, {
                "npx", "react-native", "run-ios", "--udid", device.physical and (device.udid or device.id) or device.id,
            })
        else
            terminal_command(root, "mobile-" .. device.name, {
                "npx", "react-native", "run-android", "--deviceId", device.id,
            })
        end
    elseif not ios then
        local gradlew = vim.fn.filereadable(root .. "/gradlew") == 1 and "./gradlew"
            or (vim.fn.filereadable(root .. "/android/gradlew") == 1 and "./android/gradlew")
        if gradlew then
            terminal_command(root, "mobile-" .. device.name, {
                "env", "ANDROID_SERIAL=" .. device.id, gradlew, "installDebug",
            })
        else
            vim.notify("No Expo, React Native, or Gradle Android project found", vim.log.levels.WARN)
        end
    else
        run_native_ios(device)
    end
end

local function close()
    close_hub_terminal()
    if is_open() then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
end

function M.open()
    if is_open() then
        vim.api.nvim_set_current_win(state.win)
        return
    end

    state.buf = state.buf and vim.api.nvim_buf_is_valid(state.buf) and state.buf
        or vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].filetype = "MobileDevices"

    local width = math.min(100, math.max(60, vim.o.columns - 10))
    local height = math.min(30, math.max(16, vim.o.lines - 8))
    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " Mobile Devices ",
        title_pos = "center",
    })
    vim.wo[state.win].cursorline = true
    vim.wo[state.win].wrap = false

    local opts = { buffer = state.buf, silent = true, nowait = true }
    vim.keymap.set("n", "q", close, opts)
    vim.keymap.set("n", "<Esc>", close, opts)
    vim.keymap.set("n", "r", function() M.refresh() end, opts)
    vim.keymap.set("n", "<CR>", focus_or_boot, opts)
    vim.keymap.set("n", "R", run_project, opts)
    vim.keymap.set("n", "x", stop_device, opts)
    vim.keymap.set("n", "u", update_packages, opts)
    vim.keymap.set("n", "c", reset_package_caches, opts)
    vim.keymap.set("n", "p", pick_package_version, opts)
    vim.keymap.set("n", "a", android_setup, opts)
    vim.keymap.set("n", "s", screenshot_device, opts)
    vim.keymap.set("n", "U", uninstall_app, opts)
    vim.keymap.set("n", "e", erase_device, opts)
    vim.keymap.set("n", "o", open_deep_link, opts)
    vim.keymap.set("n", "l", stream_logs, opts)
    vim.keymap.set("n", "/", set_filter, opts)
    vim.keymap.set("n", "<C-l>", clear_filter, opts)

    render()
    M.refresh(function()
        if not state.last_device then return end
        for line, device in pairs(state.line_devices) do
            if device.kind == state.last_device.kind and device.id == state.last_device.id then
                pcall(vim.api.nvim_win_set_cursor, state.win, { line, 0 })
                break
            end
        end
    end)
end

function M.toggle()
    if is_open() then
        close()
    else
        M.open()
    end
end

function M.setup()
    vim.api.nvim_create_user_command("MobileDevices", M.toggle, {
        desc = "Toggle the workspace mobile device hub",
    })
    vim.keymap.set("n", "zmm", M.toggle, { desc = "Mobile device hub" })

    vim.api.nvim_create_user_command("XcodeUpdatePackages", update_packages, {
        desc = "Delete Package.resolved and re-resolve SPM dependencies to their latest versions",
    })
    vim.api.nvim_create_user_command("XcodeResetPackageCaches", reset_package_caches, {
        desc = "Clear the SPM package cache and re-resolve dependencies",
    })
    vim.api.nvim_create_user_command("XcodePickPackageVersion", pick_package_version, {
        desc = "Pick a Swift package and pin it to a specific version, branch, or revision",
    })
    vim.api.nvim_create_user_command("AndroidEmulatorSetup", android_setup, {
        desc = "Install/update the Android SDK and latest Pixel AVD",
    })
end

return M
