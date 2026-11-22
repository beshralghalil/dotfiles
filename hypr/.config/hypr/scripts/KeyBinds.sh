#!/usr/bin/env bash
# Searchable list of mango keybinds (from ~/.config/mango/binds.toml; "# comment" lines become section headers).
pgrep -x sumi-menu >/dev/null && pkill -x sumi-menu
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'
binds="$HOME/.config/mango/binds.toml"

display_keybinds=$(awk '
  /^\[/ { sub(/^\[/, ""); sub(/\]$/, ""); split($0, t, "."); kind = (t[1] == "bind" ? "" : t[1] " "); lock = ($0 ~ /\.lock/) ? " (locked)" : ""; next }
  /^# ----/ { s = $0; gsub(/^# -+ | -+$/, "", s); section = s; next }
  /^"/ {
    split($0, kv, /" = "/); key = kv[1]; sub(/^"/, "", key)
    act = kv[2]; sub(/"[[:space:]]*(#.*)?$/, "", act)
    sub(/^spawn(_shell)?,/, "", act); gsub(/\$HOME\/\.config\/(hypr\/)?(scripts|UserScripts)\//, "", act)
    gsub(/qs -p \$HOME\/\.config\/quickshell\/sumi ipc call /, "sumi ", act)
    printf "%-26s %s%s%s\n", kind key, (section ? "[" section "] " : ""), act, lock
  }' "$binds")

[[ -z "$display_keybinds" ]] && { echo "no keybinds found."; exit 1; }
printf '%s\n' "$display_keybinds" | sumi-menu -dmenu -i -placeholder "Search Keybinds" -mesg "$msg"
