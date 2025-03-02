#!/bin/bash

# Define variables
SCRIPT_NAME="auto-toggle-wifi.sh"
SCRIPT_SRC="./$SCRIPT_NAME"
SCRIPT_DEST="/Library/Scripts/$SCRIPT_NAME"

LAUNCHAGENT_NAME="com.toggle-wifi.plist"
LAUNCHAGENT_SRC="./$LAUNCHAGENT_NAME"
LAUNCHAGENT_DEST="/Library/LaunchAgents/$LAUNCHAGENT_NAME"

# Function to display messages
echo_message() {
    echo "[INFO] $1"
}

# Function to display error messages
echo_error() {
    echo "[ERROR] $1"
}

# Ensure the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo_error "This script must be run as root. Please use 'sudo'."
    exit 1
fi

# Check if the source script exists
if [ ! -f "$SCRIPT_SRC" ]; then
    echo_error "Source script '$SCRIPT_SRC' not found. Please ensure it is in the current directory."
    exit 1
fi

# Check if the LaunchAgent plist exists
if [ ! -f "$LAUNCHAGENT_SRC" ]; then
    echo_error "LaunchAgent plist '$LAUNCHAGENT_SRC' not found. Please ensure it is in the current directory."
    exit 1
fi

# Copy the script to the destination
echo_message "Installing '$SCRIPT_NAME' to '$SCRIPT_DEST'..."
cp "$SCRIPT_SRC" "$SCRIPT_DEST"

# Set executable permissions
echo_message "Setting executable permissions for '$SCRIPT_NAME'..."
chmod +x "$SCRIPT_DEST"

# Copy the LaunchAgent plist to the destination
echo_message "Installing LaunchAgent '$LAUNCHAGENT_NAME' to '$LAUNCHAGENT_DEST'..."
cp "$LAUNCHAGENT_SRC" "$LAUNCHAGENT_DEST"

# Set appropriate permissions for the LaunchAgent
echo_message "Setting permissions for '$LAUNCHAGENT_NAME'..."
chmod 644 "$LAUNCHAGENT_DEST"

# Load the LaunchAgent
echo_message "Loading LaunchAgent '$LAUNCHAGENT_NAME'..."
launchctl load -w "$LAUNCHAGENT_DEST"

echo_message "Installation completed successfully."