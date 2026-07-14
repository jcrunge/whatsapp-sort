#!/bin/bash
# Build WhatsAppSort.app, install the LaunchAgent, and load it.
# Portable across users: every path is derived from $HOME.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/WhatsAppSort.app"
AGENT="$HOME/Library/LaunchAgents/com.github.whatsapp-sort.plist"
LABEL="com.github.whatsapp-sort"

echo "==> Building the app bundle"
mkdir -p "$APP/Contents/MacOS"
clang -O2 -o "$APP/Contents/MacOS/WhatsAppSort" "$HERE/wa-sort.c"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

echo "==> Signing (ad-hoc, so TCC has a stable identity)"
codesign --force --deep -s - "$APP"

echo "==> Writing the LaunchAgent -> $AGENT"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP}/Contents/MacOS/WhatsAppSort</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>${HOME}/Downloads</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>${HOME}/Documents/WhatsApp/.wa-sort.err</string>
</dict>
</plist>
PLIST

echo "==> Loading the agent"
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"

cat <<DONE

Done. One manual step is left (macOS security cannot be automated):

  1. Open  System Settings > Privacy & Security > Full Disk Access
  2. Add   $APP
  3. Turn its switch ON

The agent already watches ~/Downloads and will start moving
"WhatsApp *" files into ~/Documents/WhatsApp/_Inbox the moment
the permission is granted.
DONE
