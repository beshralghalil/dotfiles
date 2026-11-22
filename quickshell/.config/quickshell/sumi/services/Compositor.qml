pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Compositor-neutral window manager state for sumi: Hyprland or mango.
// mango is detected by MANGO_INSTANCE_SIGNATURE and driven through `mmsg`
// (watch streams for state, `mmsg dispatch` for actions).
Singleton {
    id: root

    readonly property bool isMango: (Quickshell.env("MANGO_INSTANCE_SIGNATURE") || "") !== ""

    // ── mango state (fed by mmsg watch streams) ──────────────────────────
    property var mMonitors: []      // [{name, active, tags:[{index,is_active,is_urgent,client_count}], active_client, keyboardlayout}]
    property var mClients: []       // [{id, title, appid, monitor, tags:[..], is_focused}]

    Process {
        id: monitorsProc
        running: root.isMango
        command: ["mmsg", "watch", "all-monitors"]
        stdout: SplitParser {
            onRead: line => {
                try { root.mMonitors = JSON.parse(line).monitors || []; } catch (e) {}
            }
        }
        onExited: if (root.isMango) restartTimer.start()
    }
    Process {
        id: clientsProc
        running: root.isMango
        command: ["mmsg", "watch", "all-clients"]
        stdout: SplitParser {
            onRead: line => {
                try { root.mClients = JSON.parse(line).clients || []; } catch (e) {}
            }
        }
    }
    // mmsg exits if mango restarts its socket; reconnect
    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: {
            monitorsProc.running = false; monitorsProc.running = true;
            clientsProc.running = false; clientsProc.running = true;
        }
    }

    function mMonitor(name) {
        const ms = root.mMonitors;
        for (let i = 0; i < ms.length; i++)
            if (ms[i].name === name) return ms[i];
        return null;
    }
    function mmsg(args) { Quickshell.execDetached(["mmsg", "dispatch"].concat(args)); }

    // ── focused monitor ──────────────────────────────────────────────────
    readonly property string focusedMonitorName: {
        if (root.isMango) {
            const ms = root.mMonitors;
            for (let i = 0; i < ms.length; i++)
                if (ms[i].active) return ms[i].name;
            return ms.length ? ms[0].name : "";
        }
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === root.focusedMonitorName) ?? Quickshell.screens[0]

    // ── workspaces / tags for the bar ────────────────────────────────────
    // -> [{id, name, active, occupied, urgent}]
    function workspacesFor(screenName, persistent) {
        const out = [];
        if (root.isMango) {
            const m = root.mMonitor(screenName);
            const tags = m ? m.tags : [];
            for (let i = 0; i < tags.length; i++) {
                const t = tags[i];
                if (t.index > persistent && t.client_count === 0 && !t.is_active) continue;
                out.push({ id: t.index, name: "" + t.index, active: t.is_active,
                           occupied: t.client_count > 0, urgent: t.is_urgent });
            }
            return out;
        }
        const mon = Hyprland.monitors.values.find(x => x.name === screenName);
        const byId = {};
        let max = persistent;
        const all = Hyprland.workspaces.values;
        for (let i = 0; i < all.length; i++) {
            const w = all[i];
            if (w.id <= 0) continue;            // special / scratchpad
            byId[w.id] = w;
            if (w.id > max) max = w.id;
        }
        const activeId = mon && mon.activeWorkspace ? mon.activeWorkspace.id
                       : Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        for (let id = 1; id <= max; id++) {
            const w = byId[id];
            if (!w && id > persistent) continue;
            out.push({ id: id, name: w ? w.name : "" + id, active: id === activeId,
                       occupied: w ? w.toplevels.values.length > 0 : false, urgent: w ? w.urgent : false });
        }
        return out;
    }

    function titleFor(screenName) {
        if (root.isMango) {
            const m = root.mMonitor(screenName);
            return m && m.active_client ? (m.active_client.title || "") : "";
        }
        const t = Hyprland.activeToplevel;
        if (!t) return "";
        if (t.monitor && t.monitor.name !== screenName) return "";
        // focus can land on an empty workspace without a fresh active-window event
        const mon = Hyprland.monitors.values.find(x => x.name === screenName);
        const ws = mon ? mon.activeWorkspace : Hyprland.focusedWorkspace;
        if (ws && t.workspace && t.workspace.id !== ws.id) return "";
        return t.title || "";
    }

    function activateWorkspace(id) {
        if (root.isMango) { root.mmsg(["view," + id + ",0"]); return; }
        const w = Hyprland.workspaces.values.find(x => x.id === id);
        if (w) w.activate();
        else root.hyprDispatch("hl.dsp.focus({ workspace = " + id + " })", "workspace " + id);
    }
    function workspaceStep(dir) {
        if (root.isMango) { root.mmsg([(dir > 0 ? "viewtoright_have_client" : "viewtoleft_have_client") + ",0"]); return; }
        const s = dir > 0 ? "e+1" : "e-1";
        root.hyprDispatch('hl.dsp.focus({ workspace = "' + s + '" })', "workspace " + s);
    }

    // ── keyboard layout (full name, e.g. "English (US)") ────────────────
    property string hyprKbLayout: ""
    readonly property string kbLayout: {
        if (root.isMango) {
            const m = root.mMonitor(root.focusedMonitorName);
            return m ? (m.keyboardlayout || "") : "";
        }
        return root.hyprKbLayout;
    }
    Connections {
        target: root.isMango ? null : Hyprland
        // activelayout>>keyboardname,layout name
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const d = event.data, i = d.lastIndexOf(",");
            root.hyprKbLayout = i >= 0 ? d.slice(i + 1) : d;
        }
    }
    Process {
        running: !root.isMango
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap' | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.hyprKbLayout = this.text.trim() }
    }

    // ── windows (picker) ─────────────────────────────────────────────────
    // -> [{key, title, appId, wsId, wsName, focused}]
    function refreshWindows() { if (!root.isMango) Hyprland.refreshToplevels(); }
    function windows() {
        const rows = [];
        if (root.isMango) {
            const cs = root.mClients;
            for (let i = 0; i < cs.length; i++) {
                const c = cs[i];
                const tag = c.tags && c.tags.length ? c.tags[0] : 9999;
                rows.push({ key: String(c.id), title: c.title || "", appId: c.appid || "",
                            wsId: tag, wsName: "" + tag, focused: !!c.is_focused });
            }
            return rows;
        }
        const src = Hyprland.toplevels.values;
        for (let i = 0; i < src.length; i++) {
            const t = src[i];
            if (!t) continue;
            const ipc = t.lastIpcObject || {};
            let addr = String(t.address || "");
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            rows.push({ key: addr, title: t.title || "",
                        appId: (t.wayland && t.wayland.appId) || ipc["class"] || "",
                        wsId: t.workspace ? t.workspace.id : 9999,
                        wsName: t.workspace ? t.workspace.name : "", focused: t.activated });
        }
        return rows;
    }
    function focusWindow(key) {
        if (root.isMango) {
            const c = root.mClients.find(x => String(x.id) === key);
            if (c && c.tags && c.tags.length && !c.is_visible) root.mmsg(["view," + c.tags[0] + ",0"]);
            root.mmsg(["focusid", "client," + key]);
            return;
        }
        root.hyprDispatch('hl.dsp.focus({ window = "address:' + key + '" })', "focuswindow address:" + key);
    }

    // ── session ──────────────────────────────────────────────────────────
    readonly property string exitCommand: root.isMango ? "mmsg dispatch quit" : "hyprctl dispatch 'hl.dsp.exit()'"

    // `lua` for Hyprland's Lua config, `legacy` for a classic hyprland.conf
    function hyprDispatch(lua, legacy) { Hyprland.dispatch(Hyprland.usingLua ? lua : legacy); }
}
