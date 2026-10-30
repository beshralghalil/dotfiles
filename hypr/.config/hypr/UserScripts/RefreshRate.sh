#!/usr/bin/env bash
# Laptop panel refresh rate: 60 Hz on battery, 144 Hz on AC (silently), toggle notifies.
# Usage: RefreshRate.sh status | toggle | auto | watch
MON="eDP-1"
RES="1920x1080"
HIGH=144
LOW=60
AC_ONLINE=/sys/class/power_supply/ACAD/online

current_rate() {
    hyprctl monitors -j | jq -r --arg m "$MON" '.[] | select(.name == $m) | .refreshRate | round'
}

set_rate() { # $1 = rate, $2 = notification text (optional)
    hyprctl eval "hl.monitor({ output = \"$MON\", mode = \"${RES}@$1\", position = \"0x0\", scale = 1 })" >/dev/null
    [ -n "$2" ] && notify-send -a "Display" -i video-display \
        -h string:x-canonical-private-synchronous:refresh-rate "Refresh rate: $1 Hz" "$2"
}

auto_rate() {
    if [ "$(cat "$AC_ONLINE")" = 1 ]; then set_rate $HIGH; else set_rate $LOW; fi
}

case "$1" in
    status)
        echo "$MON: $(current_rate) Hz" ;;
    toggle)
        if [ "$(current_rate)" -ge 100 ]; then set_rate $LOW "Toggled"; else set_rate $HIGH "Toggled"; fi ;;
    auto)
        auto_rate ;;
    watch) # one instance per session, reacts to plugging/unplugging the charger
        exec 9>"$XDG_RUNTIME_DIR/refreshrate.lock"; flock -n 9 || exit 0
        last=$(cat "$AC_ONLINE"); auto_rate
        udevadm monitor --udev --subsystem-match=power_supply 9>&- | while read -r _; do
            now=$(cat "$AC_ONLINE"); [ "$now" = "$last" ] && continue
            last=$now; auto_rate
        done ;;
esac
