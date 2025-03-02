# Wi-Fi Auto-Toggle Script with Launch Agent for Mac

## Overview

This project provides a script and a Launch Agent to manage your macOS Wi-Fi connection based on Ethernet status. The script ensures that Wi-Fi is enabled when Ethernet is disconnected and disables Wi-Fi when Ethernet is connected, unless a manual override is set. The Launch Agent automates the execution of the script, ensuring it runs at login.

## Features

- **Automatic Wi-Fi Management**: Toggles Wi-Fi based on Ethernet connection status.
- **Manual Override**: Allows users to manually enable Wi-Fi, which the script respects until Ethernet is connected or Wi-Fi is manually turned off.
- **Automated Execution**: The Launch Agent ensures the script runs automatically at login.

## Usage

Once installed, the script will automatically manage your Wi-Fi connection based on Ethernet status. To manually override the Wi-Fi setting:

- *Enable Manual Override:* Manually turn on Wi-Fi while Ethernet is connected. The script will respect this setting until Ethernet is disconnected or Wi-Fi is manually turned off.
- *Disable Manual Override:* Manually turn off Wi-Fi. The script will resume automatic management based on Ethernet status.

## Installation Instructions

*SET CORRECT NETWORK INTERFACES IN `auto-toggle-wifi.sh` BEFORE RUNNING `install_toggle_wifi.sh`*

### AUTO INSTALL

```bash
sudo ./install_toggle_wifi.sh
```

---

### 1. Load the Launch Agent

Load the Launch Agent to register it with launchd, which manages system services:

```bash
sudo launchctl load /Library/LaunchAgents/com.toggle-wifi.plist
```

This command informs launchd to start managing the script as specified in the .plist file.

### 2. Verify the Launch Agent is Loaded

To confirm that the Launch Agent is loaded and running:

```bash
sudo launchctl list | grep com.toggle-wifi
```

If the Launch Agent is listed, it indicates that it is active.

## Uninstallation Instructions

To remove the script and Launch Agent:

### 1. Unload the Launch Agent

```bash
sudo launchctl unload /Library/LaunchAgents/com.toggle-wifi.plist
```

### 2. Delete the Launch Agent and Script

```bash
sudo rm /Library/LaunchAgents/com.toggle-wifi.plist
sudo rm /Library/Scripts/auto-toggle-wifi.sh
```

## Contribution

Feel free to fork the repository, submit issues, and send pull requests. Contributions are welcome!

## License

This project is licensed under the MIT License.
