#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/auto-default-mic"
PLIST_SRC="com.user.auto-default-mic.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_SRC"
LABEL="com.user.auto-default-mic"

if [ "$(id -u)" -eq 0 ]; then
    echo "[ERROR] Do NOT run as root. User-level LaunchAgent."
    exit 1
fi

echo "[INFO] Building daemon..."
./build.sh

mkdir -p "$BIN_DIR"
install -m 0755 auto-default-mic "$BIN"
echo "[INFO] Installed binary: $BIN"

# Render plist with absolute paths
sed -e "s|__BIN__|$BIN|g" -e "s|__HOME__|$HOME|g" "$PLIST_SRC" > "$PLIST_DEST"
chmod 644 "$PLIST_DEST"
echo "[INFO] Installed LaunchAgent: $PLIST_DEST"

# Unload existing then load
launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load -w "$PLIST_DEST"
echo "[INFO] Loaded. Logs: $HOME/Library/Logs/auto-default-mic.log"

# Reset override on fresh install
rm -f /tmp/mic_manual_override /tmp/mic_script_setting
echo "[INFO] Done."
