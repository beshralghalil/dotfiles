-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- This is where you put your own keybinds (converted from UserKeybinds.conf).
-- Be mindful to check ~/.config/hypr/configs/Keybinds.lua as well to avoid conflicts.
-- See also Laptops.lua for laptop keybinds.

local v = require("vars")
local mainMod, scriptsDir, UserScripts = v.mainMod, v.scriptsDir, v.UserScripts
-- term / emacs come from UserConfigs/01-UserDefaults.conf (parsed in vars.lua)
local term, emacs = v.term, v.emacs

local function bind(keys, dsp, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dsp, opts)
end
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- common shortcuts
-- app launcher: 墨 sumi launcher
bind(mainMod .. " + D", exec("qs -p " .. os.getenv("HOME") .. "/.config/quickshell/sumi ipc call launcher toggle"), "app launcher (sumi)")
bind(mainMod .. " + B", exec([[xdg-open "https://"]]), "open default browser")
bind(mainMod .. " + A", exec(scriptsDir .. "/OverviewToggle.sh"), "desktop overview") -- toggles quickshell or ags overview (tries QS first, falls back to AGS)
-- bind(mainMod .. " + A", exec("ags -t 'overview'"), "ags overview")
-- bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewToggle"), "Quickshell overview")
bind(mainMod .. " + Return", exec(term), "Open terminal")
bind(mainMod .. " + E", exec(emacs), "Open emacs client")

-- FEATURES / EXTRAS
bind(mainMod .. " + ALT + R", exec(scriptsDir .. "/Refresh.sh"), "refresh bar and menus")
bind(mainMod .. " + ALT + E", exec(scriptsDir .. "/Emoji.sh"), "emoji menu")
bind(mainMod .. " + S", exec(scriptsDir .. "/WebSearch.sh"), "web search")
bind(mainMod .. " + CTRL + S", exec("qs -p " .. os.getenv("HOME") .. "/.config/quickshell/sumi ipc call picker windows"), "window switcher (sumi)")
bind(mainMod .. " + ALT + O", exec(scriptsDir .. "/ChangeBlur.sh"), "toggle blur")
bind(mainMod .. " + SHIFT + G", exec(scriptsDir .. "/GameMode.sh"), "toggle game mode")
bind(mainMod .. " + ALT + L", exec(scriptsDir .. "/ChangeLayout.sh"), "toggle master/dwindle layout")
bind(mainMod .. " + SHIFT + V", exec(scriptsDir .. "/ClipManager.sh"), "clipboard manager")

bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(), "fullscreen")
bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }), "maximize window")
-- bind(mainMod .. " + SPACE", hl.dsp.window.float(), "Float current window")

-- The old bind used `hyprctl dispatch workspaceopt allfloat`, which no longer exists.
-- Replacement: float every tiled window on the current workspace; if none are tiled, tile them all again.
bind(mainMod .. " + ALT + SPACE", function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local wins = hl.get_workspace_windows(ws)
    local anyTiled = false
    for _, w in ipairs(wins) do
        if not w.floating then anyTiled = true break end
    end
    local action = anyTiled and "enable" or "disable"
    for _, w in ipairs(wins) do
        hl.dispatch(hl.dsp.window.float({ action = action, window = "address:" .. w.address }))
    end
end, "Float all windows (toggle)")
bind(mainMod .. " + SHIFT + Return", exec(scriptsDir .. "/Dropterminal.sh " .. term), "DropDown terminal")

-- Desktop zooming or magnifier
bind(mainMod .. " + ALT + mouse_down", function() hl.exec_cmd(v.zoomCmd("* 2.0")) end, "zoom in")
bind(mainMod .. " + ALT + mouse_up", function() hl.exec_cmd(v.zoomCmd("/ 2.0")) end, "zoom out")

-- Bar (sumi)
bind(mainMod .. " + CTRL + ALT + B", exec("qs -p \"$HOME/.config/quickshell/sumi\" ipc call bar toggle"), "toggle bar on/off")

-- Night light toggle (Hyprsunset)
bind(mainMod .. " + N", exec(scriptsDir .. "/Hyprsunset.sh toggle"), "toggle night light")

-- FEATURES / EXTRAS (UserScripts)
bind(mainMod .. " + SHIFT + M", exec(UserScripts .. "/MusicMenu.sh"), "online music")
bind(mainMod .. " + W", exec(UserScripts .. "/WallpaperSelect.sh"), "select wallpaper")
bind(mainMod .. " + SHIFT + W", exec(UserScripts .. "/WallpaperEffects.sh"), "wallpaper effects")
bind(mainMod .. " + ALT + W", exec(scriptsDir .. "/SumiWidgets.sh"), "desktop widgets menu (sumi)")
bind("CTRL + ALT + W", exec(UserScripts .. "/WallpaperRandom.sh"), "random wallpaper")
bind(mainMod .. " + CTRL + O", exec("hyprctl setprop active opaque toggle"), "toggle active window opacity")
bind(mainMod .. " + SHIFT + K", exec(scriptsDir .. "/KeyBinds.sh"), "search keybinds")
bind(mainMod .. " + SHIFT + A", exec(scriptsDir .. "/Animations.sh"), "animations menu")
bind(mainMod .. " + SHIFT + O", exec(UserScripts .. "/ZshChangeTheme.sh"), "change oh-my-zsh theme")
bind(mainMod .. " + SPACE", exec(scriptsDir .. "/SwitchKeyboardLayout.sh"), "switch keyboard layout globally", { locked = true, non_consuming = true })
-- bind("SHIFT + ALT_L", exec(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), "switch keyboard layout per-window", { locked = true, non_consuming = true })
bind(mainMod .. " + ALT + C", exec(UserScripts .. "/Calculator.sh"), "calculator")

-- Move current workspaces to monitors (left right up or down)
bind(mainMod .. " + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }), "move workspace to left monitor")
bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }), "move workspace to right monitor")
bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }), "move workspace to up monitor")
bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }), "move workspace to down monitor")

-- For passthrough keyboard into a VM
-- bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"), "VM passthrough")
-- hl.define_submap("passthru", function()
--     -- to unbind
--     hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)
