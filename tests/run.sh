#!/bin/sh
# Runs every tests/cases/*.lua in its own headless Neovim with a throwaway
# state directory, so nothing here can touch your real workspace history.
# Usage: tests/run.sh [name-substring]
cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
sandbox=$(mktemp -d /tmp/nvim-tests.XXXXXX)
failed=0
for case in tests/cases/*${1}*.lua; do
    name=$(basename "$case" .lua)
    work="$sandbox/$name"
    mkdir -p "$work/state"
    out=$(cd "$work" && XDG_STATE_HOME="$work/state" TEST_DIR="$work" \
        nvim --headless -c "luafile $root/tests/helper.lua" -c "luafile $root/$case" -c "lua T.finish()" 2>&1)
    if [ $? -eq 0 ]; then
        printf 'PASS  %s\n' "$name"
    else
        printf 'FAIL  %s\n%s\n' "$name" "$out" | sed '2,$s/^/      /'
        failed=1
    fi
done
rm -rf "$sandbox"
exit $failed
