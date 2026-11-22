#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Copied from Discord post. Thanks to @Zorg


# Get id of an active window
active_pid=$($HOME/.config/hypr/scripts/wm.sh active | jq -r .pid)

# Close active window
kill $active_pid