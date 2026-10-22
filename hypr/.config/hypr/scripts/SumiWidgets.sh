#!/usr/bin/env bash
# Toggle the 墨 sumi desktop widgets (clock calendar music weather stats).
#   SumiWidgets.sh                    sumi menu: pick a widget to toggle it
#   SumiWidgets.sh toggle calendar    also: on | off | lock | reset <widget>
#   SumiWidgets.sh list
# Settings live in ~/.config/sumi/widgets.json (edits apply immediately).

SHELL_DIR="$HOME/.config/quickshell/sumi"
ipc() { qs -p "$SHELL_DIR" ipc call widgets "$@"; }

if ! qs -p "$SHELL_DIR" ipc show >/dev/null 2>&1; then
    notify-send -u low "sumi" "Widget shell is not running. Start it with: qs -p $SHELL_DIR"
    exit 1
fi

if [ $# -gt 0 ]; then
    ipc "$@"
    exit $?
fi

choice=$(ipc list | sumi-menu -dmenu -i -p "Widgets" -mesg "Pick a widget to toggle it")
[ -z "$choice" ] && exit 0
name=${choice%%:*}
result=$(ipc toggle "$name")
notify-send -u low "sumi" "$result"
