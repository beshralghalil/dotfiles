#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for rainbow borders animation

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

# Lua gradient: { colors = { "0xff...", ... }, angle = 270 }  (hyprctl keyword doesn't exist with a Lua config)
function random_gradient() {
    local colors=()
    for _ in {1..10}; do colors+=("\"$(random_hex)\""); done
    local IFS=,
    echo "{ colors = { ${colors[*]} }, angle = 270 }"
}

# rainbow colors only for active window
hyprctl eval "hl.config({ general = { col = { active_border = $(random_gradient) } } })"

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl eval "hl.config({ general = { col = { inactive_border = $(random_gradient) } } })"