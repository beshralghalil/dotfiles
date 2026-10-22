#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds so they always cycle windows globally (no layout-specific behavior)
# This avoids double-actions when layouts change.

set -euo pipefail

# NOTE: with the Lua config, SUPER+J/K are bound statically in ~/.config/hypr/configs/Keybinds.lua
# and this script is no longer run at startup. Kept for manual use (re-applies the binds at runtime).

# Always reset and bind SUPER+J/K the same way
hyprctl eval 'hl.unbind("SUPER + J")' || true
hyprctl eval 'hl.unbind("SUPER + K")' || true

# Cycle windows globally: J = next, K = previous
hyprctl eval 'hl.bind("SUPER + J", hl.dsp.window.cycle_next(), { description = "cycle next window" })'
hyprctl eval 'hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }), { description = "cycle previous window" })'
