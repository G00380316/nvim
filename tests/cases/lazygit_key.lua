-- <leader>g opens LazyGit directly.
local map = vim.fn.maparg("<leader>g", "n", false, true)
T.ok(map.rhs and map.rhs:find("GitPanel", 1, true), "<leader>g runs GitPanel")
T.eq(vim.fn.exists(":GitPanel"), 2, "the command exists")
