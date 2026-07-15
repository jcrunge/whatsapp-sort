#!/bin/bash
# Remove the LaunchAgent and the app bundle. Leaves your moved files untouched.
set -euo pipefail

APP="$HOME/Applications/WhatsAppSort.app"
AGENT="$HOME/Library/LaunchAgents/com.github.whatsapp-sort.plist"
ERRLOG="$HOME/Library/Logs/whatsapp-sort.err"

echo "==> Unloading the agent"
launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true

echo "==> Removing files"
rm -f "$AGENT" "$ERRLOG"
rm -rf "$APP"

cat <<DONE
Done. Removed:
  - $AGENT
  - $APP
  - $ERRLOG

Your sorted files in ~/Documents/WhatsApp/ were NOT touched.
You may also want to remove WhatsAppSort from
System Settings > Privacy & Security > Full Disk Access.
DONE
