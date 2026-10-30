-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Commands and Apps to be executed at launch (vendor defaults). Converted from Startup_Apps.conf.
-- `hyprland.start` fires once per session (like exec-once); it does NOT re-run on config reload.

local v = require("vars")
local scriptsDir, UserScripts = v.scriptsDir, v.UserScripts

local wallDIR = os.getenv("HOME") .. "/Pictures/wallpapers"
local SwwwRandom = UserScripts .. "/WallpaperAutoChange.sh"
local livewallpaper = ""

hl.on("hyprland.start", function()
    -- wallpaper stuff
    hl.exec_cmd("awww-daemon --format xrgb")
    -- hl.exec_cmd("mpvpaper '*' -o \"load-scripts=no no-audio --loop\" " .. livewallpaper)

    -- wallpaper random
    -- hl.exec_cmd(SwwwRandom .. " " .. wallDIR) -- random wallpaper switcher every 30 minutes

    -- Startup
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    -- KeybindsLayoutInit.sh is no longer needed: SUPER+J/K are bound in configs/Keybinds.lua

    -- Initialize Drop Down terminal - See Bug#810 https://github.com/JaKooLit/Hyprland-Dots/issues/810#issuecomment-3351947644
    hl.exec_cmd(scriptsDir .. "/Dropterminal.sh kitty &")

    -- Polkit (Polkit Gnome / KDE)
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- startup apps
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("nm-tray")   -- For ubuntu
    hl.exec_cmd("swaync")
    -- hl.exec_cmd("ags")
    -- hl.exec_cmd("blueman-applet")
    -- hl.exec_cmd("rog-control-center")
    hl.exec_cmd("qs") -- quickshell AGS Desktop Overview alternative

    -- clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Rainbow borders
    -- hl.exec_cmd(UserScripts .. "/RainbowBorders.sh")

    -- Starting hypridle to start hyprlock
    hl.exec_cmd("hypridle")

    -- Resume Hyprsunset if state is "on" from previous session
    hl.exec_cmd(scriptsDir .. "/Hyprsunset.sh init")

    -- Here are list of features available but disabled by default
    -- hl.exec_cmd("awww-daemon --format xrgb && awww img $HOME/Pictures/wallpapers/mecha-nostalgia.png")  -- persistent wallpaper

    -- gnome polkit for nixos
    -- hl.exec_cmd(scriptsDir .. "/Polkit-NixOS.sh")

    -- xdg-desktop-portal-hyprland (should be auto starting. However, you can force to start)
    -- hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")
end)
