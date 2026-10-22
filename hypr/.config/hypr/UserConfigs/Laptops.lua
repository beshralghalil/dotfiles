-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Laptop related binds and devices (converted from Laptops.conf). Addendum to configs/Keybinds.lua

local v = require("vars")
local mainMod, scriptsDir = v.mainMod, v.scriptsDir

-- for disabling Touchpad. `hyprctl devices` to get device name.
-- scripts/TouchPad.sh reads this line, keep the format: Touchpad_Device = "..."
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

hl.bind("xf86KbdBrightnessDown", exec(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true }) -- decrease keyboard brightness
hl.bind("xf86KbdBrightnessUp", exec(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true })   -- increase keyboard brightness
hl.bind("xf86Launch1", exec("rog-control-center"))       -- ASUS Armory crate button
hl.bind("xf86Launch3", exec("asusctl led-mode -n"))      -- FN+F4 Switch keyboard RGB profile
hl.bind("xf86Launch4", exec("asusctl profile -n"))       -- FN+F5 change of fan profiles (Quite, Balance, Performance)
hl.bind("xf86MonBrightnessDown", exec(scriptsDir .. "/Brightness.sh --dec"), { repeating = true }) -- decrease monitor brightness
hl.bind("xf86MonBrightnessUp", exec(scriptsDir .. "/Brightness.sh --inc"), { repeating = true })   -- increase monitor brightness
hl.bind("xf86TouchpadToggle", exec(scriptsDir .. "/TouchPad.sh"))                                  -- disable touchpad

-- Screenshot keybindings using F6 (no PrinSrc button)
hl.bind(mainMod .. " + F6", exec(scriptsDir .. "/ScreenShot.sh --now"))            -- screenshot
hl.bind(mainMod .. " + SHIFT + F6", exec(scriptsDir .. "/ScreenShot.sh --area"))   -- screenshot (area)
hl.bind(mainMod .. " + CTRL + F6", exec(scriptsDir .. "/ScreenShot.sh --in5"))     -- screenshot (5 secs delay)
hl.bind(mainMod .. " + ALT + F6", exec(scriptsDir .. "/ScreenShot.sh --in10"))     -- screenshot (10 secs delay)
hl.bind("ALT + F6", exec(scriptsDir .. "/ScreenShot.sh --active"))                 -- screenshot (active window only)

hl.device({
    name = Touchpad_Device,
    enabled = true, -- scripts/TouchPad.sh toggles this at runtime with `hyprctl eval`
})

-- Below are useful when you are connecting your laptop in external display
-- Suggest you edit below for your laptop display
-- From WIKI This is to disable laptop monitor when lid is closed.
-- hl.bind("switch:off:Lid Switch", exec([[hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })']]), { locked = true })
-- hl.bind("switch:on:Lid Switch", exec([[hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })']]), { locked = true })

-- NOTE: the old LaptopDisplay.conf / lid-switch-writes-a-file method is not carried over;
-- use the two binds above instead if you need lid handling.
