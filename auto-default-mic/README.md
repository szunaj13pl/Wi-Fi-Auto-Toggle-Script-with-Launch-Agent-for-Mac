# auto-default-mic

Keeps `LCS_USB_Audio` as the default input device when available, unless the user manually picks a different mic.

## Behavior

- LCS plugged in → set as default input (if not already).
- User picks different mic → override flag set, daemon stops touching default.
- LCS unplugged → override cleared. Next plug-in re-applies.
- User picks LCS again → override cleared.

Match is by substring `LCS_USB_Audio` in the CoreAudio device name.

## Install

```bash
cd mac-launch-agents/auto-default-mic
./install.sh
```

Requires Swift toolchain (Xcode CLT).

Binary lands at `~/.local/bin/auto-default-mic`. LaunchAgent at `~/Library/LaunchAgents/com.user.auto-default-mic.plist`. Logs at `~/Library/Logs/auto-default-mic.log`.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.user.auto-default-mic.plist
rm ~/Library/LaunchAgents/com.user.auto-default-mic.plist
rm ~/.local/bin/auto-default-mic
rm -f /tmp/mic_manual_override /tmp/mic_script_setting
```

## State files

- `/tmp/mic_manual_override` — present = user override active.
- `/tmp/mic_script_setting` — short-lived flag while daemon writes default (suppresses self-triggered "manual change" detection).

## Change target device

Edit `TARGET_NAME` in `AutoDefaultMic.swift`, rebuild, reload agent.
