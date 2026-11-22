#!/usr/bin/env bash
# Toggle between normal and light blur (mango). Reloading the config restores normal.
notif="$HOME/.config/swaync/images"
STATE="$XDG_RUNTIME_DIR/mango-lessblur"
if [ ! -f "$STATE" ]; then
    touch "$STATE"
    mmsg dispatch setoption,blur_params_radius,2 >/dev/null
    mmsg dispatch setoption,blur_params_num_passes,1 >/dev/null
    notify-send -e -u low -i "$notif/note.png" " Less Blur"
else
    rm -f "$STATE"
    mmsg dispatch setoption,blur_params_radius,5 >/dev/null
    mmsg dispatch setoption,blur_params_num_passes,2 >/dev/null
    notify-send -e -u low -i "$notif/ja.png" " Normal Blur"
fi
