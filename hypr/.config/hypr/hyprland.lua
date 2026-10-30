-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  --
-- Hyprland Lua config (Hyprland >= 0.55). Converted from hyprland.conf.
-- Wiki for this version: https://wiki.hypr.land/0.56.0/Configuring/Start/
--
-- hyprland.lua takes precedence over hyprland.conf. The old .conf files are left in place but are
-- NOT loaded anymore. To roll back: rename this file and run `hyprctl reload full-reset`.
--
-- Every file below is loaded with require(): "UserConfigs.Foo" means ~/.config/hypr/UserConfigs/Foo.lua.
-- Required files are watched, so saving any of them reloads the config.
-- Check for errors without reloading: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

local v = require("vars")

-- Initial boot script to apply initial wallpapers, theming, new settings etc.
-- As long as ~/.config/hypr/.initial_startup_done exists, initial-boot.sh does nothing.
hl.on("hyprland.start", function()
    hl.exec_cmd(v.hyprDir .. "/initial-boot.sh")
end)

require("configs.Keybinds") -- Pre-configured keybinds

-- Load vendor defaults, then user additions/overrides
require("configs.Startup_Apps")
require("UserConfigs.Startup_Apps")

require("UserConfigs.ENVariables") -- Environment variables to load

require("UserConfigs.Laptops") -- For laptop related

-- Load vendor defaults, then user additions
require("configs.WindowRules")     -- all about Hyprland Window Rules and Layer Rules (defaults)
require("UserConfigs.WindowRules") -- Window Rules and Layer Rules user configs

require("UserConfigs.UserDecorations") -- Decorations config file
require("UserConfigs.UserAnimations")  -- Animation config file (SUPER+SHIFT+A copies a preset from animations/ over it)
require("UserConfigs.UserKeybinds")    -- Put your own keybinds here
require("UserConfigs.UserSettings")    -- Main Hyprland Settings.

-- settings for User default apps: UserConfigs/01-UserDefaults.conf (parsed in vars.lua, also read by scripts)
for name, value in pairs(v.env) do
    hl.env(name, value)
end

-- nwg-displays (writes monitors.lua; workspaces.lua is optional)
pcall(require, "monitors")
hl.exec_cmd(v.hyprDir .. "/UserScripts/RefreshRate.sh auto") -- monitors.lua forces 144 Hz on every reload
pcall(require, "workspaces")
