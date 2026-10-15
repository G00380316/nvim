-- The file types `run` knows include the archives and data files added to the shell function.
local runner = require("runner").runners.run
for _, ext in ipairs({ "zip", "tar", "tgz", "tbz2", "txz", "gz", "bz2", "xz", "json", "csv" }) do
    T.ok(runner.extensions[ext], ext .. " runs")
end
T.ok(runner.names["requirements.txt"], "requirements.txt runs")
T.ok(runner.names["package.json"], "package.json runs")
