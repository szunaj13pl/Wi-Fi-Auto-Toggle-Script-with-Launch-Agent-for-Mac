#!/bin/bash

ethernet_interface="en7"  # Change this to your correct Ethernet interface, e.g., en7
wifi_status=$(networksetup -getairportpower en0 | awk '{print $4}')
override_flag="/tmp/wifi_manual_override"
script_wifi_enable_flag="/tmp/script_wifi_enabled"

echo "Debugging Output:"  # Debugging header

# Check if the Ethernet interface exists
if ifconfig $ethernet_interface > /dev/null 2>&1; then
    echo "Ethernet interface $ethernet_interface exists."
    # Ethernet interface exists, check its status
    ethernet_status=$(ifconfig $ethernet_interface | grep "status: active")

    if [ -n "$ethernet_status" ]; then
        echo "Ethernet is active."

        # If WiFi is on and no manual override flag exists, check if it was manually enabled
        if [ "$wifi_status" == "On" ] && [ ! -f "$override_flag" ] && [ ! -f "$script_wifi_enable_flag" ]; then
            # This should be the user manually turning on WiFi
            touch "$override_flag"
            echo "Manual override enabled because WiFi was manually turned on with Ethernet connected."
        fi

        # If manual override doesn't exist, disable WiFi
        if [ ! -f "$override_flag" ]; then
            echo "No manual override, disabling WiFi..."
            networksetup -setairportpower en0 off
            echo "WiFi disabled because Ethernet is connected."
        else
            echo "WiFi manual override is active. Skipping toggle."
        fi
    else
        echo "Ethernet is inactive, ensuring WiFi is on."

        # Ethernet is inactive, ensure WiFi is on
        if [ "$wifi_status" == "Off" ]; then
            networksetup -setairportpower en0 on
            touch "$script_wifi_enable_flag"  # Flag that script enabled WiFi
            echo "WiFi enabled because Ethernet is inactive. (Script initiated)"
        fi

        # Remove the manual override flag if Ethernet is disconnected or inactive
        if [ -f "$override_flag" ]; then
            rm "$override_flag"
            echo "Ethernet disconnected. Manual override reset."
        fi
    fi
else
    echo "Ethernet interface $ethernet_interface does not exist."
    # Ethernet interface does not exist, ensure WiFi is on
    if [ "$wifi_status" == "Off" ]; then
        networksetup -setairportpower en0 on
        touch "$script_wifi_enable_flag"  # Flag that script enabled WiFi
        echo "WiFi enabled because Ethernet interface does not exist. (Script initiated)"
    fi

    # Remove the manual override flag if Ethernet interface is missing
    if [ -f "$override_flag" ]; then
        rm "$override_flag"
        echo "Ethernet interface $ethernet_interface does not exist. Manual override reset."
    fi
fi

# Remove manual override if WiFi is manually turned off (en0)
wifi_status_after_check=$(networksetup -getairportpower en0 | awk '{print $4}')
if [ "$wifi_status_after_check" == "Off" ] && [ -f "$override_flag" ]; then
    rm "$override_flag"
    echo "WiFi manually turned off. Manual override removed."
fi

# Clean up the script flag if WiFi is turned off manually
if [ "$wifi_status_after_check" == "Off" ] && [ -f "$script_wifi_enable_flag" ]; then
    rm "$script_wifi_enable_flag"
    echo "WiFi was turned off manually, script flag reset."
fi
