-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Default Keybinds (converted from Keybinds.conf)
-- visit https://wiki.hypr.land/0.56.0/Configuring/Basics/Binds/ for more info

local v = require("vars")
local mainMod, scriptsDir = v.mainMod, v.scriptsDir

local function bind(keys, dsp, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dsp, opts)
end
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

bind("CTRL + ALT + Delete", hl.dsp.exit(), "exit Hyprland")
bind(mainMod .. " + Q", hl.dsp.window.close(), "close active window")
bind(mainMod .. " + SHIFT + Q", exec(scriptsDir .. "/KillActiveProcess.sh"), "Terminate active process")
bind("CTRL + ALT + L", exec(scriptsDir .. "/LockScreen.sh"), "lock screen")
bind("CTRL + ALT + P", exec(scriptsDir .. "/Wlogout.sh"), "powermenu")
bind(mainMod .. " + SHIFT + N", exec("swaync-client -t -sw"), "notification panel")
bind(mainMod .. " + SHIFT + E", exec(scriptsDir .. "/Kool_Quick_Settings.sh"), "Quick settings menu")

-- Master Layout
bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"), "remove master")
bind(mainMod .. " + I", hl.dsp.layout("addmaster"), "add master")
-- J/K cycle windows on every layout. These used to be bound at runtime by
-- scripts/KeybindsLayoutInit.sh via `hyprctl keyword`, which doesn't exist with a Lua config
-- (and runtime binds are lost on every config reload), so they are bound statically here.
bind(mainMod .. " + J", hl.dsp.window.cycle_next(), "cycle next window")
bind(mainMod .. " + K", hl.dsp.window.cycle_next({ next = false }), "cycle previous window")
bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), "swap with master")

-- Dwindle Layout
-- bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), "toggle split (dwindle)")
bind(mainMod .. " + P", hl.dsp.window.pseudo(), "toggle pseudo (dwindle)")

-- Works on either layout (Master or Dwindle)
bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"), "set split ratio 0.3")

-- group
bind(mainMod .. " + G", hl.dsp.group.toggle(), "toggle group")
bind(mainMod .. " + CTRL + tab", hl.dsp.group.next(), "change active in group")

-- Cycle windows; if floating bring to top
bind("ALT + tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, "cycle next window, bring to top")

-- Special Keys / Hot Keys
bind("xf86audioraisevolume", exec(scriptsDir .. "/Volume.sh --inc"), "volume up", { locked = true, repeating = true })
bind("xf86audiolowervolume", exec(scriptsDir .. "/Volume.sh --dec"), "volume down", { locked = true, repeating = true })
bind("xf86AudioMicMute", exec(scriptsDir .. "/Volume.sh --toggle-mic"), "toggle mic mute", { locked = true })
bind("xf86audiomute", exec(scriptsDir .. "/Volume.sh --toggle"), "toggle mute", { locked = true })
bind("xf86Sleep", exec("systemctl suspend"), "sleep", { locked = true })
bind("xf86Rfkill", exec(scriptsDir .. "/AirplaneMode.sh"), "airplane mode", { locked = true })

-- media controls using keyboards
-- "xf86AudioPlayPause" is not a real XKB keysym (the old .conf bind never fired; Lua rejects it). Play/Pause keys are below.
-- bind("xf86AudioPlayPause", exec(scriptsDir .. "/MediaCtrl.sh --pause"), "play/pause", { locked = true })
bind("xf86AudioPause", exec(scriptsDir .. "/MediaCtrl.sh --pause"), "pause", { locked = true })
bind("xf86AudioPlay", exec(scriptsDir .. "/MediaCtrl.sh --pause"), "play", { locked = true })
bind("xf86AudioNext", exec(scriptsDir .. "/MediaCtrl.sh --nxt"), "next track", { locked = true })
bind("xf86AudioPrev", exec(scriptsDir .. "/MediaCtrl.sh --prv"), "previous track", { locked = true })
bind("xf86audiostop", exec(scriptsDir .. "/MediaCtrl.sh --stop"), "stop", { locked = true })

-- Screenshot keybindings NOTE: You may need to press Fn key as well
bind(mainMod .. " + Print", exec(scriptsDir .. "/ScreenShot.sh --now"), "screenshot now")
bind(mainMod .. " + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --area"), "screenshot (area)")
bind(mainMod .. " + CTRL + Print", exec(scriptsDir .. "/ScreenShot.sh --in5"), "screenshot in 5s")
bind(mainMod .. " + CTRL + SHIFT + Print", exec(scriptsDir .. "/ScreenShot.sh --in10"), "screenshot in 10s")
bind("ALT + Print", exec(scriptsDir .. "/ScreenShot.sh --active"), "screenshot active window")

-- screenshot with swappy (another screenshot tool)
bind(mainMod .. " + SHIFT + S", exec(scriptsDir .. "/ScreenShot.sh --swappy"), "screenshot (swappy)")
bind(mainMod .. " + ALT + S", exec(scriptsDir .. "/ScreenShot.sh --swappy --active"), "screenshot (swappy)")

-- Resize windows
bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), "resize left (-50)", { repeating = true })
bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), "resize right (+50)", { repeating = true })
bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), "resize up (-50)", { repeating = true })
bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), "resize down (+50)", { repeating = true })

-- Move windows
bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), "move window left")
bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), "move window right")
bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), "move window up")
bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), "move window down")

-- Swap windows
bind(mainMod .. " + ALT + H", hl.dsp.window.swap({ direction = "left" }), "swap window left")
bind(mainMod .. " + ALT + L", hl.dsp.window.swap({ direction = "right" }), "swap window right")
bind(mainMod .. " + ALT + K", hl.dsp.window.swap({ direction = "up" }), "swap window up")
bind(mainMod .. " + ALT + J", hl.dsp.window.swap({ direction = "down" }), "swap window down")

-- Move focus with mainMod + h/j/k/l
bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), "focus left")
bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), "focus right")
-- NOTE: the old file also bound SUPER+K / SUPER+J to focus up/down, but KeybindsLayoutInit.sh
-- unbound those at startup and replaced them with cycle next/prev (see above), so they are omitted.

-- Workspaces related
bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }), "next workspace")
bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), "previous workspace")

-- Special workspace
bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), "move to special workspace")
bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(), "toggle special workspace")

-- The following mappings use the key codes to better support various keyboard layouts
-- 1 is code:10, 2 is code:11, ... 0 is code:19
for i = 1, 10 do
    local code = "code:" .. (i + 9)
    -- Switch workspaces with mainMod + [0-9]
    bind(mainMod .. " + " .. code, hl.dsp.focus({ workspace = i }), "workspace " .. i)
    -- Move active window and follow to workspace mainMod + SHIFT [0-9]
    bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }), "move to workspace " .. i)
    -- Move active window to a workspace silently mainMod + CTRL [0-9]
    bind(mainMod .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }), "move silently to workspace " .. i)
end
bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1" }), "move to previous workspace")
bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), "move to next workspace")
bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }), "move silently to previous workspace")
bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), "move silently to next workspace")

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "next workspace")
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "previous workspace")
bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }), "next workspace")
bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }), "previous workspace")

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), "move window")     -- mouse:272 = left click
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "resize window") -- mouse:273 = right click
