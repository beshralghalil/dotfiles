#!/usr/bin/env bash
# Toggle the touchpad (mango).
notif="$HOME/.config/swaync/images/ja.png"
STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
mmsg dispatch toggle_trackpad_enable >/dev/null
if [ "$(cat "$STATUS_FILE" 2>/dev/null)" = "false" ]; then
    printf "true" >"$STATUS_FILE"; notify-send -u low -i "$notif" " Enabling" " touchpad"
else
    printf "false" >"$STATUS_FILE"; notify-send -u low -i "$notif" " Disabling" " touchpad"
fi
