local M = {}

local state = {
    buf = nil,
    win = nil,
    devices = {},
    line_devices = {},
    loading = false,
    errors = {},
}

local function executable(name)
    local path = vim.fn.exepath(name)
    return path ~= "" and path or nil
end

local function emulator_path()
    local candidates = {
        executable("emulator"),
        vim.env.ANDROID_SDK_ROOT and (vim.env.ANDROID_SDK_ROOT .. "/emulator/emulator"),
        vim.env.ANDROID_HOME and (vim.env.ANDROID_HOME .. "/emulator/emulator"),
        vim.fn.expand("~/Library/Android/sdk/emulator/emulator"),
    }

    for _, path in ipairs(candidates) do
        if path and vim.fn.executable(path) == 1 then
            return path
        end
    end
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
        if hardware.platform == "iOS" and connection.tunnelState == "connected" then
            devices[#devices + 1] = {
                kind = "ios_device",
                id = hardware.udid or device.identifier,
                core_id = device.identifier,
                udid = hardware.udid,
                name = properties.name or hardware.marketingName or hardware.udid or device.identifier,
                model = hardware.marketingName,
                os = properties.osVersionNumber,
                state = connection.transportType == "wired" and "Wired" or "Wi-Fi",
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
        "",
    }
    state.line_devices = {}

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
            if device.kind == section.kind then
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
            lines[#lines + 1] = state.loading and "   … checking" or "   — none available"
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

function M.refresh()
    state.loading = true
    state.devices = {}
    state.errors = {}
    render()

    local pending = 0
    local function begin()
        pending = pending + 1
    end
    local function finish(devices, error_message)
        vim.list_extend(state.devices, devices or {})
        if error_message then
            state.errors[#state.errors + 1] = error_message
        end
        pending = pending - 1
        if pending == 0 then
            state.loading = false
            sort_devices(state.devices)
            render()
        end
    end

    if executable("xcrun") then
        begin()
        system({ "xcrun", "simctl", "list", "devices", "available", "--json" }, function(output)
            finish(M._parse_ios_simulators(output), output and nil or "iOS Simulator service unavailable")
        end)

        begin()
        local json_path = vim.fn.tempname() .. ".json"
        system({ "xcrun", "devicectl", "list", "devices", "--json-output", json_path }, function(_, _, code)
            local output
            if code == 0 and vim.fn.filereadable(json_path) == 1 then
                output = table.concat(vim.fn.readfile(json_path), "\n")
            end
            vim.uv.fs_unlink(json_path)
            finish(M._parse_ios_devices(output), output and nil or "Connected iOS devices unavailable")
        end)
    else
        state.errors[#state.errors + 1] = "Xcode command-line tools not found"
    end

    if executable("adb") then
        begin()
        system({ "adb", "devices", "-l" }, function(output)
            finish(M._parse_android_devices(output), output and nil or "ADB server unavailable")
        end)
    else
        state.errors[#state.errors + 1] = "ADB not found"
    end

    local emulator = emulator_path()
    if emulator then
        begin()
        system({ emulator, "-list-avds" }, function(output)
            finish(M._parse_android_avds(output), output and nil or "Android emulator list unavailable")
        end)
    else
        state.errors[#state.errors + 1] = "Android emulator not found"
    end

    if pending == 0 then
        state.loading = false
        render()
    end
end

local function selected_device()
    if not is_open() then
        return nil
    end
    return state.line_devices[vim.api.nvim_win_get_cursor(state.win)[1]]
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
            vim.fn.jobstart({ emulator, "-avd", device.id }, { detach = true })
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
        system({ "adb", "-s", device.id, "emu", "kill" }, function(_, error, code)
            if code ~= 0 then
                vim.notify(error or "Could not stop emulator", vim.log.levels.ERROR)
            end
            M.refresh()
        end)
    else
        vim.notify("Real devices are disconnected physically, not stopped here", vim.log.levels.INFO)
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

local function terminal_command(root, title, command)
    local parts = {}
    for _, value in ipairs(command) do
        parts[#parts + 1] = vim.fn.shellescape(value)
    end
    pcall(vim.cmd, "EditorFocus")
    vim.cmd(string.format(
        "FloatermNew --cwd=%s --title=%s %s",
        vim.fn.fnameescape(root),
        vim.fn.fnameescape(title:gsub("%s+", "-")),
        table.concat(parts, " ")
    ))
end

local function run_native_ios(device)
    if not _G.xcodebuild_initialized then
        require("xcodebuild").setup({
            show_build_progress_bar = true,
            logs = { auto_open_on_success = false, auto_open_on_error = true },
        })
        _G.xcodebuild_initialized = true
    end

    local actions = require("xcodebuild.actions")
    local config = require("xcodebuild.project.config")
    if not config.settings.projectFile or not config.settings.scheme then
        vim.notify("Choose the Xcode project and scheme once; then press R again", vim.log.levels.INFO)
        actions.configure_project()
        return
    end

    config.set_destination({
        id = device.id,
        name = device.name,
        os = device.os,
        platform = device.physical and "iOS" or "iOS Simulator",
    })
    actions.build_and_run()
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
    vim.keymap.set("n", "r", M.refresh, opts)
    vim.keymap.set("n", "<CR>", focus_or_boot, opts)
    vim.keymap.set("n", "R", run_project, opts)
    vim.keymap.set("n", "x", stop_device, opts)

    render()
    M.refresh()
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
end

return M
