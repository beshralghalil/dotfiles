#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Searching via web browsers

# Define the path to the config file
config_file=$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Process the config file in memory, removing the $ and fixing spaces
config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')

# Source the modified content directly from the variable
eval "$config_content"

# Check if $term is set correctly
if [[ -z "$Search_Engine" ]]; then
    echo "Error: \$Search_Engine is not set in the configuration file!"
    exit 1
fi

# Message
msg='‼️ **note** ‼️ search via default web browser'

# Close an open sumi-menu before execution
if pgrep -x sumi-menu >/dev/null; then
    pkill -x sumi-menu
fi

# Ask for a query (input only) and pass it to xdg-open with the search engine URL
sumi-menu -dmenu -lines 0 -placeholder "Web Search" -mesg "$msg" </dev/null | xargs -I{} xdg-open $Search_Engine