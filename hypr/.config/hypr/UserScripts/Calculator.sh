#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# /* Calculator (using qalculate) and sumi-menu */
# /* Submitted by: https://github.com/JosephArmas */

# Close an open sumi-menu before execution
if pgrep -x sumi-menu >/dev/null; then
    pkill -x sumi-menu
fi

# main function

while true; do
    result=$(
        sumi-menu -i -dmenu -lines 0 \
            -placeholder "Calculate" \
            -mesg "$result      =    $calc_result"
    )

    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -n "$result" ]; then
        calc_result=$(qalc -t "$result")
        echo "$calc_result" | wl-copy
    fi
done
