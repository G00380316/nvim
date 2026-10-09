-- CopilotToggle turns inline suggestions off and on in code buffers.
if vim.fn.executable("copilot-language-server") == 0 then return end
vim.cmd("edit " .. T.file("c.py", "x = 1\n"))
vim.wait(2500, function() return #vim.lsp.get_clients({ name = "copilot" }) > 0 end, 100)
T.ok(#vim.lsp.get_clients({ name = "copilot" }) > 0, "copilot attached")
T.eq(vim.lsp.inline_completion.is_enabled({ bufnr = 0 }), true, "on to begin with")
vim.cmd("CopilotToggle")
T.eq(vim.lsp.inline_completion.is_enabled({ bufnr = 0 }), false, "toggled off")
vim.cmd("CopilotToggle")
T.eq(vim.lsp.inline_completion.is_enabled({ bufnr = 0 }), true, "toggled back on")
