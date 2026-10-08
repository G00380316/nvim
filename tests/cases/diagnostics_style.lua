-- Virtual text is limited to the cursor's line; the guicursor gives insert its own colour.
T.eq(vim.diagnostic.config().virtual_text.current_line, true, "current-line virtual text")
T.ok(vim.o.guicursor:find("ver25%-CursorInsert"), "insert cursor has its own highlight")
