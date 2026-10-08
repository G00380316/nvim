-- Sizes follow the window.
local r = require("responsive")
vim.o.columns = 200
T.eq(r.sidebar_width(), 30, "wide: full sidebar")
T.eq(r.dashboard_width(), 48, "wide: full dashboard")
vim.o.columns = 80
T.ok(r.sidebar_width() < 30 and r.sidebar_width() >= 18, "narrow: sidebar shrinks")
T.ok(r.dashboard_width() <= r.editor_width(), "narrow: dashboard fits the editor area")
T.ok(not r.show_statusline_part("lsp"), "narrow: LSP part hidden")
T.ok(r.show_statusline_part("branch"), "narrow: branch kept")
vim.o.columns = 50
T.ok(r.sidebar_width() >= 18, "tiny: sidebar never below 18")
T.ok(not r.dashboard_header(), "tiny: logo hidden")

vim.o.lines = 20
T.ok(r.terminal_max_height() <= 8 and r.terminal_max_height() >= 5, "short window: terminal capped at 40%")
