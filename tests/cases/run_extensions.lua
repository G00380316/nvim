-- The file types `run` knows include the archives and data files added to the shell function.
local runner = require("runner").runners.run
for _, ext in ipairs({ "zip", "tar", "tgz", "tbz2", "txz", "gz", "bz2", "xz", "json", "csv",
    "7z", "rar", "dmg", "yaml", "yml", "toml", "xml", "plist", "db", "sqlite", "sqlite3",
    "kt", "kts", "pl", "r", "jl", "zig", "hs", "dart", "docx", "pdf" }) do
    T.ok(runner.extensions[ext], ext .. " runs")
end
T.ok(runner.names["requirements.txt"], "requirements.txt runs")
T.ok(runner.names["package.json"], "package.json runs")
for _, name in ipairs({ "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml",
    "Cargo.toml", "go.mod", "Package.swift", "Brewfile", "CMakeLists.txt" }) do
    T.ok(runner.names[name], name .. " runs")
end
local test = require("runner").runners.runtest
for _, ext in ipairs({ "rb", "dart", "kt" }) do T.ok(test.extensions[ext], ext .. " tests") end
