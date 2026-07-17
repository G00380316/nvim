local root = vim.fs.root(0, {
    "gradlew",
    "mvnw",
    "settings.gradle",
    "settings.gradle.kts",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    ".git",
}) or require("workspace").get()

local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
local bundles = vim.fn.glob(
    mason_packages .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
    false,
    true
)

for _, jar in ipairs(vim.fn.glob(mason_packages .. "/java-test/extension/server/*.jar", false, true)) do
    local name = vim.fs.basename(jar)
    if name ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar"
        and name ~= "jacocoagent.jar"
    then
        table.insert(bundles, jar)
    end
end

local project = vim.fs.basename(root)
local data = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project

require("jdtls").start_or_attach({
    name = "jdtls",
    cmd = { "jdtls", "-data", data },
    root_dir = root,
    init_options = { bundles = bundles },
})

vim.keymap.set("n", "zdjc", function()
    require("jdtls").test_class()
end, { buffer = true, desc = "Debug Java class" })

vim.keymap.set("n", "zdjm", function()
    require("jdtls").test_nearest_method()
end, { buffer = true, desc = "Debug nearest Java method" })
