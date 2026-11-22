#!/usr/bin/env bash
# Game mode for mango: no animations/blur/shadows/gaps/rounding/dimming, wallpaper daemon stopped.
# Toggle again (or reload the mango config) to restore everything from config.toml.
notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
STATE="$XDG_RUNTIME_DIR/mango-gamemode"
set_opt() { mmsg dispatch "setoption,$1,$2" >/dev/null; }

if [ ! -f "$STATE" ]; then
    touch "$STATE"
    for o in animations layer_animations blur blur_layer shadows border_radius dim_enable \
             gap_inner_horizontal gap_inner_vertical gap_outer_horizontal gap_outer_vertical; do
        set_opt "$o" 0
    done
    awww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
else
    rm -f "$STATE"
    mmsg dispatch reload_config >/dev/null
    awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
    sleep 0.1
    "$SCRIPTSDIR/WallustSwww.sh"
    sleep 0.5
    "$SCRIPTSDIR/Refresh.sh"
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
fi
