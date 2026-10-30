-- Shared variables for the Lua config (replaces the $vars repeated across the old .conf files).
-- Usage in other files:  local v = require("vars")

local HOME = os.getenv("HOME")

local v = {
    mainMod     = "SUPER",
    hyprDir     = HOME .. "/.config/hypr",
    scriptsDir  = HOME .. "/.config/hypr/scripts",
    UserScripts = HOME .. "/.config/hypr/UserScripts",
    UserConfigs = HOME .. "/.config/hypr/UserConfigs",

    -- defaults, overridden by UserConfigs/01-UserDefaults.conf below
    term  = "kitty",
    emacs = "emacsclient -a '' -c",
}

-- UserConfigs/01-UserDefaults.conf stays in hyprlang-style syntax because the bash scripts
-- (WebSearch.sh, Launch.sh, Kool_Quick_Settings.sh) read it too.
-- Here we pick up its `$name = value` and `env = NAME,value` lines so it remains the single place
-- to set your terminal, editor, etc.
v.env = {}
local f = io.open(v.UserConfigs .. "/01-UserDefaults.conf", "r")
if f then
    for rawline in f:lines() do
        local line = rawline:gsub("%s+#.*$", "")            -- strip trailing comments
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name and value ~= "" then
            v[name] = value
        end
        local ename, evalue = line:match("^%s*env%s*=%s*([%w_]+)%s*,%s*(.-)%s*$")
        if ename then
            v.env[ename] = evalue
        end
    end
    f:close()
end

-- Shell command that multiplies/divides cursor:zoom_factor (never below 1), used by the zoom
-- gestures (UserSettings.lua) and SUPER+ALT+scroll (UserKeybinds.lua). `hyprctl keyword` doesn't work
-- with a Lua config, so the new value is applied with `hyprctl eval`.  op is e.g. "* 2.0" or "/ 1.5".
function v.zoomCmd(op)
    return [[hyprctl eval "hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor ]]
        .. op .. [[}') } })"]]
end

return v
