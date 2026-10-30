#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Lighter version of Refresh.sh
# Used by automatic wallpaper change
# Modified inorder to refresh Wallust, SwayNC only (and close an open sumi-menu)

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Close an open sumi-menu (a script: pidof cannot see it, pkill -x can)
pkill -x sumi-menu || true

# quit ags & relaunch ags
#ags -q && ags &

# quit quickshell & relaunch quickshell
# only the plain `qs` (overview); leave the sumi shell (qs -n -p ~/.config/quickshell/sumi) running
pkill -xf qs && qs &

# Wallust refresh (synchronous to ensure colors are ready)
${SCRIPTSDIR}/WallustSwww.sh
sleep 0.2

# reload swaync
swaync-client --reload-config

# Rainbow borders disabled on purpose (random-colour window borders were unwanted).
# To re-enable, run ${UserScripts}/RainbowBorders.sh from here.


exit 0