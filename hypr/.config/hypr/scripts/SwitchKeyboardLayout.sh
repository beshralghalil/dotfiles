#!/usr/bin/env bash
# Switch to the next keyboard layout (mango; layouts from xkb_rules_layout in config.toml).
mmsg dispatch switch_keyboard_layout >/dev/null || {
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"; exit 1; }
