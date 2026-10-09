-- The default result style is a window under the cell; the style can be switched.
local nb = require("notebook")
T.eq(nb.output_mode(), "window", "window style by default")
T.eq(vim.g.molten_auto_open_output, true, "output opens by itself")
T.eq(vim.g.molten_virt_text_output, false, "no inline text in window style")
nb.toggle_output_mode()
T.eq(nb.output_mode(), "inline", "switched to inline")
T.eq(vim.g.molten_virt_text_output, true, "inline text on")
