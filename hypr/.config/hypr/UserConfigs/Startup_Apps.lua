-- User startup apps (converted from Startup_Apps.conf). Runs once per session, after the vendor list.

hl.on("hyprland.start", function()
    -- 墨 sumi shell: bar, tray, launcher, desktop widgets; toggle with SUPER+ALT+W or scripts/SumiWidgets.sh
    hl.exec_cmd("qs -n -p " .. os.getenv("HOME") .. "/.config/quickshell/sumi")
    -- (started first so its tray is ready before apps register their tray icons)
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("qs")
    -- KeybindsLayoutInit.sh is no longer needed: SUPER+J/K are bound in configs/Keybinds.lua
    hl.exec_cmd("batsignal -d 20 -c 25 -w 30 -p -b")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("emacs --daemon")
    -- delayed so its tray icon registers with the sumi bar (it does not re-register later)
    hl.exec_cmd("sleep 3 && protonvpn-app --start-minimized")
end)
