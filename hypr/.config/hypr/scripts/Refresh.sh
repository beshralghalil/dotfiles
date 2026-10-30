#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing ags, swaync, wallust (and closing an open sumi-menu)

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
_ps=(swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done
# sumi-menu is a script: pidof cannot see it, pkill -x can
pkill -x sumi-menu || true

# quit ags & relaunch ags
#ags -q && ags &

# quit quickshell & relaunch quickshell
# only the plain `qs` (overview); leave the sumi shell (qs -n -p ~/.config/quickshell/sumi) running
pkill -xf qs && qs &

# some process to kill
for pid in $(pidof swaync ags swaybg); do
  kill -SIGUSR1 "$pid"
  sleep 0.1
done

# relaunch swaync
sleep 0.3
swaync >/dev/null 2>&1 &
# reload swaync
swaync-client --reload-config

# Rainbow borders disabled on purpose (random-colour window borders were unwanted).
# To re-enable, run ${UserScripts}/RainbowBorders.sh from here.

exit 0
