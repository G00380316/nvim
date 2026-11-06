-- Missing tools get the right install command on each kind of machine.
local deps = require("deps")

local function machine(platform, have)
    deps._platform = platform
    local set = {}
    for _, name in ipairs(have) do set[name] = true end
    deps._exists = function(exe) return set[exe] == true end
end

local function plan_for(exe)
    for _, item in ipairs(deps.entries) do
        if item.exe == exe or (item.exes and vim.tbl_contains(item.exes, exe)) then
            local commands, via, reason = deps.plan(item)
            return commands, via, reason
        end
    end
end

-- A Mac with Homebrew: brew first, then the language managers.
machine("mac", { "brew", "npm", "node" })
local commands, via = plan_for("rg")
T.eq(commands, { "brew install ripgrep" }, "mac: ripgrep through brew")
commands, via = plan_for("yaml-language-server")
T.eq(via, "brew", "mac: a server brew has comes through brew")
commands, via = plan_for("tailwindcss-language-server")
T.eq(commands, { "npm install -g @tailwindcss/language-server" }, "mac: npm-only server through npm")
commands = plan_for("xelatex")
T.eq(commands, { "brew install --cask mactex-no-gui" }, "mac: XeLaTeX is a cask")

-- Debian: the system manager, a different name for fd, no sudo prefix for root.
machine("linux", { "apt-get" })
commands = plan_for("rg")
T.eq(commands, { "sudo apt-get install -y ripgrep" }, "apt: ripgrep")
commands = plan_for("fd")
T.eq(commands, { "sudo apt-get install -y fd-find" }, "apt: fd is fd-find")
commands = plan_for("xelatex")
T.eq(commands, { "sudo apt-get install -y texlive-xetex" }, "apt: XeLaTeX")

-- A server only npm has, with no node yet: node first, into a user prefix.
commands, via = plan_for("tailwindcss-language-server")
T.eq(commands, { "sudo apt-get install -y nodejs npm", "npm install -g --prefix ~/.local @tailwindcss/language-server" },
    "apt: node is fetched before the npm package")
T.eq(via, "npm", "apt: installed through npm")

-- Arch, and a tool pipx has but the system does not.
machine("linux", { "pacman" })
commands = plan_for("rg")
T.eq(commands, { "sudo pacman -S --needed --noconfirm ripgrep" }, "pacman: ripgrep")
commands = plan_for("jupytext")
T.eq(commands, { "sudo pacman -S --needed --noconfirm python-pipx", "pipx install jupytext" },
    "pacman: pipx first, then jupytext")

-- No way at all: says so instead of guessing.
machine("linux", {})
local none, _, reason = plan_for("rg")
T.ok(none == nil and reason ~= nil, "nothing to install with gives a reason")
none, _, reason = plan_for("sourcekit-lsp")
T.ok(none == nil and (reason:find("swift") or reason:find("xcode")), "the Swift toolchain is a manual step")

-- Linuxbrew is used when the system has no name for the package.
machine("linux", { "apt-get", "brew" })
commands, via = plan_for("lua-language-server")
T.eq(commands, { "brew install lua-language-server" }, "linux: brew fills the gaps the system manager has")

deps._platform, deps._exists = nil, nil
