### Commands to run

    :TSInstall lua python bash json vim vimdoc query markdown markdown_inline json yaml html css

### Tools the config needs (Mac and Linux)

`lua/deps.lua` knows the programs the config leans on, with the package names
from `Mac_Install/install.sh`, and fetches whichever are missing: Homebrew on a
Mac; apt, dnf, pacman, zypper or apk on Linux (then Homebrew-on-Linux, npm,
pipx, cargo or go for tools that only come that way, installing node, pipx and
the rest first if need be).

It asks, showing the exact command, at the moment something needs a tool:
opening a file for a language whose server is missing, exporting a note,
`lazygit`, `opencode`, a notebook; and once after start for ripgrep, fd, git,
tree-sitter, a C compiler and node. The command runs in the terminal panel so a
`sudo` password can be typed there. "Never ask again" is remembered.

- `:Deps` (or "Check tools and install missing ones" in the palette) lists what is
  missing and installs from the list; `:DepsInstall [name]` installs everything
  missing, or one tool.
- `vim.g.deps_auto_install = true` skips the question.
- A few things have no package and are told to you instead: the Swift toolchain,
  superhtml, tinymist without Homebrew.
