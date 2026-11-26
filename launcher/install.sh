#!/bin/sh
# Make ~/Applications/Neovim.app: an app Finder can open files with. It does
# nothing but hand the files to nvim-open (next to this script), which reuses the
# running Neovim in kitty or starts one. macOS only.
#
#   sh launcher/install.sh
#
# Then, once: in Finder select a file, Get Info > Open with > Neovim > Change All.
# (Or, with `brew install duti`: duti -s <bundle id> .md all, and so on.)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/Neovim.app"
SCRIPT="$HERE/nvim-open"
mkdir -p "$HOME/Applications"
rm -rf "$APP"

TMP="$(mktemp -t nvim-launcher).applescript"
cat > "$TMP" <<APPLESCRIPT
on open theItems
	set args to ""
	repeat with anItem in theItems
		set args to args & " " & quoted form of POSIX path of anItem
	end repeat
	do shell script quoted form of "$SCRIPT" & args & " >/dev/null 2>&1 &"
end open

on run
	do shell script quoted form of "$SCRIPT" & " >/dev/null 2>&1 &"
end run
APPLESCRIPT
osacompile -o "$APP" "$TMP"
rm -f "$TMP"

# Offer to open any file or folder, and stay out of the Dock.
PLIST="$APP/Contents/Info.plist"
plutil -replace CFBundleName -string "Neovim" "$PLIST"
plutil -replace CFBundleIdentifier -string "local.nvim-launcher" "$PLIST"
plutil -replace LSUIElement -bool true "$PLIST"
plutil -replace CFBundleDocumentTypes -json '[{"CFBundleTypeName":"Anything","CFBundleTypeRole":"Editor","LSHandlerRank":"Alternate","LSItemContentTypes":["public.data","public.text","public.folder","public.plain-text","public.source-code"]}]' "$PLIST"
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
echo "Installed $APP"
