import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "../common"
import "../services"

// 墨 sumi top bar (replaces waybar). One PanelWindow per screen on the Top layer,
// namespace "sumi-bar", reserving its height. All visuals live in BarContent
// (plain QtQuick); this file wires Quickshell services and actions into it.
// Adapted in spirit from Ryoku's bar (github.com/ryoku-dev/ryoku, GPL-3.0).
//
// Hyprland runs a Lua config here: raw dispatches must be Lua expressions
// (hl.dsp.*); HyprlandWorkspace.activate() already handles that itself.
Scope {
    id: root

    // ── settings (component properties; not in Config) ────────────────────
    property bool shown: true                  // bound to every bar window's visibility
    property bool polling: shown               // run the helper pollers
    property int barHeight: 36
    property int persistentWorkspaces: 5       // always show 1..N, like waybar's persistent-workspaces
    property string numerals: "mono"          // "kanji" (一二三) | "mono" (1 2 3)
    property bool use24h: Config.data.clock24h // shares the desktop clock's setting
    property bool showTitle: true
    property bool showStats: true
    property bool showBrightness: true
    property bool showMic: true
    property bool showMedia: true
    property bool trayMonochrome: true
    property real volumeStep: 0.05
    property real volumeMax: 1.0
    property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    property string launcherCommand: "qs -p " + Quickshell.env("HOME") + "/.config/quickshell/sumi ipc call launcher toggle"
    property string launcherAltCommand: Quickshell.env("HOME") + "/.config/hypr/UserScripts/WallpaperSelect.sh"

    // ── state ──────────────────────────────────────────────────────────────
    property bool idleInhibit: false
    readonly property alias sys: services

    BarServices {
        id: services
        running: root.polling
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(o => o) }

    readonly property var battery: {
        const d = UPower.displayDevice;
        return d && d.ready && d.isLaptopBattery && d.isPresent ? d : null;
    }
    // percentage is 0..1 in current Quickshell; guard against a 0..100 build
    readonly property real batteryFrac: battery ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : -1

    // first playing MPRIS player, else the first one; playerctld is a proxy, skip it
    readonly property var player: {
        const ps = Mpris.players.values.filter(p => !(p.dbusName || "").includes("playerctld"));
        for (let i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return ps[i];
        return ps.length ? ps[0] : null;
    }

    function workspacesFor(mon) {
        const byId = {};
        let max = root.persistentWorkspaces;
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) {
            const w = all[i];
            if (w.id <= 0) continue;            // special / scratchpad
            byId[w.id] = w;
            if (w.id > max) max = w.id;
        }
        const activeId = mon && mon.activeWorkspace ? mon.activeWorkspace.id
                       : Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        const out = [];
        for (let id = 1; id <= max; id++) {
            const w = byId[id];
            if (!w && id > root.persistentWorkspaces) continue;
            out.push({
                id: id,
                name: w ? w.name : "" + id,
                active: id === activeId,
                occupied: w ? w.toplevels.values.length > 0 : false,
                urgent: w ? w.urgent : false
            });
        }
        return out;
    }

    function titleFor(mon) {
        const t = Hyprland.activeToplevel;
        if (!t) return "";
        if (mon && t.monitor && t.monitor !== mon) return "";
        // focus can land on an empty workspace without a fresh active-window
        // event; don't keep showing a window from another workspace
        const ws = mon ? mon.activeWorkspace : Hyprland.focusedWorkspace;
        if (ws && t.workspace && t.workspace.id !== ws.id) return "";
        return t.title || "";
    }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    // ── keyboard layout ─────────────────────────────────────────────────────
    // "English (US)" -> "US", "Arabic" -> "AR"
    property string kbLayout: ""
    function shortLayout(name) {
        if (!name) return "";
        const m = name.match(/\(([^)]+)\)/);
        return (m ? m[1] : name.slice(0, 2)).toUpperCase();
    }
    Connections {
        target: Hyprland
        // activelayout>>keyboardname,layout name
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const d = event.data, i = d.lastIndexOf(",");
            root.kbLayout = root.shortLayout(i >= 0 ? d.slice(i + 1) : d);
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap' | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.kbLayout = root.shortLayout(this.text.trim()) }
    }

    // `lua` for the Lua config, `legacy` for a classic hyprland.conf
    function dispatch(lua, legacy) { Hyprland.dispatch(Hyprland.usingLua ? lua : legacy) }

    function nudge(node, dir) {
        if (!node || !node.audio) return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(root.volumeMax, node.audio.volume + dir * root.volumeStep));
    }

    Timer { id: brightRefresh; interval: 350; onTriggered: services.refreshBrightness() }
    Timer { id: nightRefresh; interval: 1500; onTriggered: services.refreshNightlight() }

    function handle(name, arg) {
        switch (name) {
        case "idle": root.idleInhibit = !root.idleInhibit; break;
        case "kbLayout": run(root.scripts + "/SwitchKeyboardLayout.sh"); break;
        case "launcher": run(root.launcherCommand); break;
        case "launcherAlt": run(root.launcherAltCommand); break;
        case "workspace": {
            const w = Hyprland.workspaces.values.find(x => x.id === arg);
            if (w) w.activate();
            else dispatch("hl.dsp.focus({ workspace = " + arg + " })", "workspace " + arg);
            break;
        }
        case "workspaceStep": {
            const s = arg > 0 ? "e+1" : "e-1";
            dispatch('hl.dsp.focus({ workspace = "' + s + '" })', "workspace " + s);
            break;
        }
        case "notif": run("swaync-client -t -sw"); break;
        case "notifDnd": run("swaync-client -d -sw"); break;
        case "brightnessStep":
            run(root.scripts + "/Brightness.sh " + (arg > 0 ? "--inc" : "--dec"));
            brightRefresh.restart();
            break;
        case "stats": run(root.scripts + "/WaybarScripts.sh " + (arg === Qt.RightButton ? "--nvtop" : "--btop")); break;
        case "volumeStep": nudge(root.sink, arg); break;
        case "mute": if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted; break;
        case "mixer": run("pavucontrol -t 3"); break;
        case "micStep": nudge(root.source, arg); break;
        case "micMute": if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted; break;
        case "micMixer": run("pavucontrol -t 4"); break;
        case "mediaToggle": if (root.player && root.player.canTogglePlaying) root.player.togglePlaying(); break;
        case "mediaNext": if (root.player && root.player.canGoNext) root.player.next(); break;
        case "mediaPrev": if (root.player && root.player.canGoPrevious) root.player.previous(); break;
        case "nightlight":
            run(root.scripts + "/Hyprsunset.sh toggle");
            services.nightlight = !services.nightlight;   // optimistic; confirmed by the poll
            nightRefresh.restart();
            break;
        case "power": run(root.scripts + "/Wlogout.sh"); break;
        case "lock": run(root.scripts + "/LockScreen.sh"); break;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            visible: root.shown
            color: "transparent"
            implicitHeight: root.barHeight
            anchors { top: true; left: true; right: true }
            // Auto = reserve the bar's height so windows tile below it (Normal reserves 0 unless exclusiveZone is set)
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "sumi-bar"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            IdleInhibitor {
                window: win
                enabled: root.idleInhibit
            }

            // calendar popup under the clock; a click anywhere else closes it
            property bool calendarOpen: false
            property real calendarX: 0
            function toggleCalendar(x) {
                win.calendarX = Math.max(8, x - 8);
                win.calendarOpen = !win.calendarOpen;
                if (win.calendarOpen) calCard.offset = 0;
            }
            PopupWindow {
                id: calPopup
                anchor.window: win
                anchor.rect.x: win.calendarX
                anchor.rect.y: win.height + 6
                implicitWidth: calCard.implicitWidth
                implicitHeight: calCard.implicitHeight
                color: "transparent"
                visible: win.calendarOpen
                CalendarPopup {
                    id: calCard
                    anchors.fill: parent
                    today: clock.date
                }
            }
            HyprlandFocusGrab {
                windows: [calPopup, win]
                active: calPopup.visible
                onCleared: win.calendarOpen = false
            }

            Component {
                id: trayComp
                Tray { window: win; monochrome: root.trayMonochrome }
            }

            BarContent {
                anchors.fill: parent

                now: clock.date
                use24h: root.use24h
                numerals: root.numerals
                windowTitle: root.titleFor(win.monitor)
                workspaces: root.workspacesFor(win.monitor)
                trayComponent: trayComp

                notifCount: services.notifCount
                notifDnd: services.notifDnd
                idleInhibit: root.idleInhibit
                nightlight: services.nightlight
                brightness: services.brightness
                cpu: services.cpu
                mem: services.mem
                temp: services.temp

                battery: root.batteryFrac
                charging: root.battery !== null && (root.battery.state === UPowerDeviceState.Charging
                                                    || root.battery.state === UPowerDeviceState.FullyCharged
                                                    || root.battery.state === UPowerDeviceState.PendingCharge)

                hasSink: root.sink !== null && root.sink.audio !== null
                volume: hasSink ? root.sink.audio.volume : 0
                muted: hasSink ? root.sink.audio.muted : false
                hasMic: root.source !== null && root.source.audio !== null
                micVolume: hasMic ? root.source.audio.volume : 0
                micMuted: hasMic ? root.source.audio.muted : false

                hasMedia: root.player !== null
                mediaPlaying: root.player ? root.player.isPlaying : false
                mediaTitle: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
                mediaArtist: root.player ? (root.player.trackArtist || "") : ""
                kbLayout: root.kbLayout

                showTitle: root.showTitle
                showStats: root.showStats
                showBrightness: root.showBrightness
                showMic: root.showMic
                showMedia: root.showMedia

                onAction: (name, arg) => name === "calendar" ? win.toggleCalendar(arg) : root.handle(name, arg)
            }
        }
    }
}
