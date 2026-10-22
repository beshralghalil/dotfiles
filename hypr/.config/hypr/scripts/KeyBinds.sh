#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# searchable enabled keybinds using sumi-menu (supports bindd descriptions)

# kill yad to not interfere with this binds
pkill yad || true

# close an open sumi-menu first
if pgrep -x sumi-menu >/dev/null; then
  pkill -x sumi-menu
fi

msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# Read the live binds from Hyprland instead of parsing config files, so this works with the
# Lua config (configs/Keybinds.lua, UserConfigs/UserKeybinds.lua, UserConfigs/Laptops.lua) and also
# shows binds added at runtime (e.g. SUPER+O togglesplit from ChangeLayout.sh).
# Format: MODS+KEY — DESCRIPTION  (or the dispatcher when a bind has no description)
display_keybinds=$(hyprctl binds -j | jq -r '
  def mods($m):
    [ (if ($m / 64 | floor) % 2 == 1 then "SUPER" else empty end),
      (if ($m / 4  | floor) % 2 == 1 then "CTRL"  else empty end),
      (if ($m / 8  | floor) % 2 == 1 then "ALT"   else empty end),
      (if  $m % 2 == 1                then "SHIFT" else empty end) ];
  .[]
  | (if .key == "" and .keycode != 0 then "code:\(.keycode)" else .key end) as $key
  | ((mods(.modmask) + [$key]) | join("+")) as $combo
  | if .has_description and .description != "" then "\($combo)  —  \(.description)"
    else "\($combo)  —  \(.dispatcher) \(.arg)" end
')

# check for any keybinds to display
if [[ -z "$display_keybinds" ]]; then
    echo "no keybinds found."
    exit 1
fi

# use sumi-menu to display the keybinds
printf '%s\n' "$display_keybinds" | sumi-menu -dmenu -i -placeholder "Search Keybinds" -mesg "$msg"
