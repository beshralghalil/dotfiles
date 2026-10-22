#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Animations from different users

# Close an open sumi-menu first
if pgrep -x sumi-menu >/dev/null; then
  pkill -x sumi-menu
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
msg='❗NOTE:❗ This will copy animations into UserAnimations.lua'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' | sed 's/.*\///' | sed 's/\.lua$//' | sort -V)

# sumi menu
chosen_file=$(echo "$animations_list" | sumi-menu -i -dmenu -placeholder "Search / Choose which Animations to load" -mesg "$msg")

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
    full_path="$animations_dir/$chosen_file.lua"
    cp "$full_path" "$UserConfigs/UserAnimations.lua"
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Hyprland Animation Loaded"
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
