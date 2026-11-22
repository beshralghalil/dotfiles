#!/usr/bin/env bash
# Window manager queries for scripts (mango, via mmsg).
#   wm.sh active   -> {"class","pid","x","y","w","h"} of the focused window
#   wm.sh monitor  -> {"name","height","scale"} of the focused monitor
case "$1" in
  active)  mmsg get focusing-client | jq -c '{class: .appid, pid, x, y, w: .width, h: .height}' ;;
  monitor)
    name=$(mmsg get focusing-client 2>/dev/null | jq -r '.monitor // empty')
    mmsg get all-monitors | jq -c --arg n "$name" \
      '[.monitors[] | select(if $n != "" then .name == $n else .active end)][0] // .monitors[0]
       | {name, height, scale}' ;;
  *) echo "usage: wm.sh active|monitor" >&2; exit 1 ;;
esac
