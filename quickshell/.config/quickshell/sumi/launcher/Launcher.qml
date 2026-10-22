import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "fuzzy.js" as Fuzzy
import "calc.js" as Calc

// 墨 launcher: keyboard-driven app launcher (replaces rofi drun).
//
// One full-screen overlay surface on the focused monitor, mapped only while
// `open` (hidden by default, so instantiating this creates no surface). The
// card itself is the plain-QtQuick LauncherCard; this file owns the data:
// DesktopEntries search + ranking, launch counts, the "=" calculator.
//
//   toggle() / show() / hide()   — wire to an IpcHandler / keybind
//   history: ~/.config/sumi/launcher-history.json  ({ "counts": { id: n } })
//
// Window/scrim structure adapted from Ryoku's launcher
// (github.com/ryoku-dev/ryoku, GPL-3.0).
Scope {
    id: root

    property bool open: false
    property int maxResults: 60
    // terminal for Terminal=true entries (DesktopEntry.execute() does not wrap them)
    property string terminal: Quickshell.env("TERMINAL") || "kitty"

    property var targetScreen: null

    function show() {
        root.targetScreen = root.focusedScreen();
        card.reset();
        root.open = true;
    }
    function hide() { root.open = false; }
    function toggle() { if (root.open) root.hide(); else root.show(); }

    function focusedScreen() {
        const mon = Hyprland.focusedMonitor;
        const screens = Quickshell.screens;
        if (mon)
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === mon.name)
                    return screens[i];
        return screens.length ? screens[0] : null;
    }

    // ── data ───────────────────────────────────────────────────────────────
    property int appsRevision: 0
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.appsRevision++; }
    }

    // searchable docs, rebuilt when the installed apps change
    readonly property var docs: {
        void root.appsRevision;
        const src = DesktopEntries.applications.values;
        const out = [];
        for (let i = 0; i < src.length; i++) {
            const e = src[i];
            if (!e || e.noDisplay)
                continue;
            const cmd = Array.from(e.command || []);
            out.push({
                id: e.id,
                name: e.name || e.id,
                generic: e.genericName || "",
                keywords: Array.from(e.keywords || []).join(" "),
                exec: cmd.length ? String(cmd[0]).split("/").pop() : "",
                icon: e.icon || "",
                entry: e
            });
        }
        return out;
    }

    readonly property string query: card.text
    readonly property bool calcMode: query.length > 0 && query.charAt(0) === "="
    readonly property string calcExpr: calcMode ? query.slice(1).trim() : ""
    readonly property string calcResult: calcMode ? (Calc.evaluate(calcExpr) || "") : ""

    readonly property var ranked: (root.open && !root.calcMode)
        ? Fuzzy.rank(root.docs, root.query, history.counts).slice(0, root.maxResults)
        : []
    readonly property var rows: ranked.map(d => ({
        name: d.name,
        generic: d.generic,
        icon: d.icon.length ? Quickshell.iconPath(d.icon, true) : ""
    }))

    function launch(index) {
        const doc = root.ranked[index];
        if (!doc || !doc.entry)
            return;
        root.bump(doc.id);
        const e = doc.entry;
        if (e.runInTerminal && e.command && e.command.length)
            Quickshell.execDetached([root.terminal, "-e"].concat(Array.from(e.command)));
        else
            e.execute();
        root.hide();
    }

    function copyResult() {
        if (!root.calcResult.length)
            return;
        // wl-copy forks and keeps serving the selection after our surface unmaps,
        // so the copy survives closing the launcher (no focus/serial dance).
        Quickshell.execDetached(["wl-copy", "--", root.calcResult]);
        card.copied = true;
        closeAfterCopy.restart();
    }
    Timer { id: closeAfterCopy; interval: 380; onTriggered: root.hide() }

    // ── launch history ─────────────────────────────────────────────────────
    function bump(id) {
        const counts = Object.assign({}, history.counts || {});
        counts[id] = (counts[id] || 0) + 1;
        history.counts = counts;
        historyFile.writeAdapter();
    }

    FileView {
        id: historyFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/sumi/launcher-history.json"
        watchChanges: true
        printErrors: false   // missing until the first launch; never written just by loading
        atomicWrites: true
        onFileChanged: reload()

        JsonAdapter {
            id: history
            property var counts: ({})
        }
    }

    // ── surface ────────────────────────────────────────────────────────────
    PanelWindow {
        id: win

        screen: root.targetScreen
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "sumi-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        // The surface only exists while open, so the exclusive grab is only
        // ever held while open. Kept constant on purpose: dropping the grab on
        // a still-mapped layer can strand the keyboard (see Ryoku's notes);
        // unmapping with it held hands focus back to the previous window.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) Qt.callLater(card.focusSearch)

        // dim + click-out
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.38)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.hide()
            }
        }

        LauncherCard {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(win.height * 0.24)
            rows: root.rows
            totalCount: root.docs.length
            calcActive: root.calcMode
            calcExpr: root.calcExpr
            calcResult: root.calcResult

            onActivated: index => root.launch(index)
            onCalcAccepted: root.copyResult()
            onDismissed: root.hide()
        }
    }
}
