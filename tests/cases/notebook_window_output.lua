-- The default result style is text under the cell; the style can be switched.
local nb = require("notebook")
T.eq(nb.output_mode(), "inline", "inline style by default")
T.eq(vim.g.molten_virt_text_output, true, "inline text on")
nb.toggle_output_mode()
T.eq(nb.output_mode(), "window", "switched to a window")
T.eq(vim.g.molten_auto_open_output, true, "output opens by itself in window style")
T.eq(vim.g.molten_virt_text_output, false, "no inline text in window style")
