-- Tiny assertion helper shared by every case. A case calls T.eq / T.ok;
-- T.finish() (run by tests/run.sh after the case) exits non-zero on failure.
T = { failures = {} }

function T.ok(cond, msg)
    if not cond then T.failures[#T.failures + 1] = msg or "assertion failed" end
end

function T.eq(actual, expected, msg)
    if not vim.deep_equal(actual, expected) then
        T.failures[#T.failures + 1] = ("%s: expected %s, got %s"):format(
            msg or "eq", vim.inspect(expected), vim.inspect(actual))
    end
end

---Write a file under the case's private directory and return its path.
function T.file(name, text)
    local path = vim.env.TEST_DIR .. "/" .. name
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local f = assert(io.open(path, "w"))
    f:write(text or "")
    f:close()
    return path
end

function T.finish()
    if #T.failures == 0 then vim.cmd("qa!") end
    io.stderr:write(table.concat(T.failures, "\n") .. "\n")
    vim.cmd("cquit 1")
end
