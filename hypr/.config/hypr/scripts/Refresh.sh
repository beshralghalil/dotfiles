#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing ags, waybar, swaync, wallust (and closing an open sumi-menu)

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
  if [ -e "$1" ]; then
    return 0 # File exists
  else
    return 1 # File does not exist
  fi
}

# Kill already running processes
_ps=(waybar swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done
# sumi-menu is a script: pidof cannot see it, pkill -x can
pkill -x sumi-menu || true

# added since wallust sometimes not applying
killall -SIGUSR2 waybar
# Added sleep for GameMode causing multiple waybar
sleep 0.1

# quit ags & relaunch ags
#ags -q && ags &

# quit quickshell & relaunch quickshell
# only the plain `qs` (overview); leave the sumi shell (qs -n -p ~/.config/quickshell/sumi) running
pkill -xf qs && qs &

# some process to kill
for pid in $(pidof waybar swaync ags swaybg); do
  kill -SIGUSR1 "$pid"
  sleep 0.1
done

#Restart waybar, unless the sumi bar replaces it (barEnabled in ~/.config/sumi/widgets.json)
sleep 0.1
if ! jq -e '.barEnabled' "$HOME/.config/sumi/widgets.json" >/dev/null 2>&1; then
  waybar &
fi

# relaunch swaync
sleep 0.3
swaync >/dev/null 2>&1 &
# reload swaync
swaync-client --reload-config

# Rainbow borders disabled on purpose (random-colour window borders were unwanted).
# To re-enable, run ${UserScripts}/RainbowBorders.sh from here.

exit 0
