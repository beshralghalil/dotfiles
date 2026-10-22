import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "match.js" as Match

// 墨 picker: the dmenu-style menu behind ~/.local/bin/sumi-menu (rofi -dmenu flags).
//
// The shim writes a request (JSON) plus the raw stdin rows to
// $XDG_RUNTIME_DIR/sumi-picker/, calls `ipc call picker open <request>` and
// waits for `<request>.result`, which this writes (atomically) when the menu
// closes:
//
//   line 1   exit code (0 accept, 1 cancel, 10.. -kb-custom-N)
//   line 2   kind: items | custom | none
//   line 3   the filter text
//   line 4.. items: one row index per line   custom: the typed text
//
// The shim maps indices back to the raw input lines, so what it prints is
// byte-exact. One picker at a time: a new request cancels the open one.
// Also a "windows" mode (rofi -show window): Hyprland clients, focus on pick.
//
// Window/scrim structure as in the sumi launcher (after Ryoku's launcher,
// github.com/ryoku-dev/ryoku, GPL-3.0).
Scope {
    id: root

    property bool open: false
    property var targetScreen: null
    // tests only: run the whole request/result cycle without mapping a surface
    property bool headless: false

    // current request
    property string mode: ""          // "dmenu" | "windows"
    property string requestPath: ""
    property string resultPath: ""
    property var req: ({})
    property var entries: []
    property bool caseSensitive: false
    property var marked: ({})
    property int resultCap: 500
    property alias query: card.text

    readonly property var shown: root.open
        ? Match.filter(root.entries, card.text, root.resultCap, root.caseSensitive)
        : []

    // ── IPC entry points (wired in shell.qml) ──────────────────────────────
    function openRequest(path) {
        let r;
        try {
            reqReader.path = path;
            r = JSON.parse(reqReader.text());
        } catch (e) {
            reqReader.path = "";
            return "error: bad request " + path + ": " + e;
        }
        reqReader.path = "";
        if (!r || typeof r !== "object")
            return "error: bad request";

        let raw = "";
        if (r.items && r.items.length) {
            itemsReader.path = r.items;
            raw = itemsReader.text() || "";
            itemsReader.path = "";
        }

        // supersede whatever is open
        root.finishCurrent(1, "none", []);

        root.mode = "dmenu";
        root.requestPath = path;
        root.resultPath = r.result || (path + ".result");
        root.req = r;
        root.caseSensitive = !!r.caseSensitive;
        root.marked = ({});
        root.entries = Match.prepare(root.parseRows(raw, r), root.caseSensitive);
        root.present(r);
        return "open";
    }

    function openWindows() {
        root.finishCurrent(1, "none", []);
        Hyprland.refreshToplevels();
        root.mode = "windows";
        root.requestPath = "";
        root.resultPath = "";
        root.req = ({ prompt: "Window", mesg: "", placeholder: "switch to window" });
        root.caseSensitive = false;
        root.marked = ({});
        root.entries = Match.prepare(root.windowRows(), false);
        root.present(root.req);
        return "open";
    }

    function cancel() {
        if (!root.open) return "closed";
        root.finishCurrent(1, "none", []);
        return "cancelled";
    }

    // the shim got SIGTERM/SIGINT (pkill -x sumi-menu): close only if it is ours
    function dismiss(path) {
        if (root.open && root.requestPath === path) {
            root.requestPath = "";
            root.resultPath = "";
            root.close();
            return "dismissed";
        }
        return "not active";
    }

    function status(path) {
        return root.open && root.requestPath === path ? "active" : "none";
    }

    // ── request -> rows ────────────────────────────────────────────────────
    function parseRange(spec) {
        const out = {};
        String(spec || "").split(",").forEach(part => {
            const m = part.trim().match(/^(\d+)(?:-(\d+))?$/);
            if (!m) return;
            const a = parseInt(m[1], 10), b = m[2] !== undefined ? parseInt(m[2], 10) : a;
            for (let i = a; i <= b && i - a < 100000; i++) out[i] = true;
        });
        return out;
    }

    function parseRows(raw, r) {
        const sep = (r.sep && r.sep.length) ? r.sep : "\n";
        let lines = raw.length ? raw.split(sep) : [];
        if (lines.length && lines[lines.length - 1] === "")
            lines.pop();
        if (sep !== "\n")
            lines = lines.map(l => l.replace(/\n$/, ""));
        const markup = !!r.markupRows;
        const active = root.parseRange(r.active);
        const urgent = root.parseRange(r.urgent);
        const out = new Array(lines.length);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const nul = line.indexOf("\u0000");
            let text = nul >= 0 ? line.slice(0, nul) : line;
            const e = { text: "", meta: "", icon: "", iconKind: 0, selectable: true,
                        urgent: !!urgent[i], active: !!active[i] };
            if (nul >= 0) {
                const opts = line.slice(nul + 1).split("\u001f");
                for (let k = 0; k + 1 < opts.length; k += 2) {
                    const key = opts[k], val = opts[k + 1];
                    if (key === "icon") root.setIcon(e, val);
                    else if (key === "display") text = val;
                    else if (key === "meta") e.meta = val;
                    else if (key === "nonselectable") e.selectable = !(val === "true" || val === "1");
                    else if (key === "urgent") e.urgent = val === "true";
                    else if (key === "active") e.active = val === "true";
                    // info / permanent / others: ignored
                }
            }
            e.text = markup ? Match.stripMarkup(text) : text;
            if (e.text.indexOf("\t") >= 0)
                e.text = e.text.replace(/\t/g, "    ");
            out[i] = e;
        }
        return out;
    }

    function setIcon(e, val) {
        if (!val || !val.length) return;
        let p = val;
        if (p.indexOf("file://") === 0) p = decodeURIComponent(p.slice(7));
        if (p.charAt(0) === "~") p = Quickshell.env("HOME") + p.slice(1);
        if (p.charAt(0) === "/") {
            e.icon = "file://" + p.split("/").map(s => encodeURIComponent(s)).join("/");
            e.iconKind = Match.isImage(p) ? 2 : 1;
        } else {
            e.icon = Quickshell.iconPath(p, true);
            e.iconKind = 1;
        }
    }

    function windowRows() {
        const src = Hyprland.toplevels.values;
        const rows = [];
        for (let i = 0; i < src.length; i++) {
            const t = src[i];
            if (!t) continue;
            const ipc = t.lastIpcObject || {};
            const appId = (t.wayland && t.wayland.appId) || ipc["class"] || "";
            const ws = t.workspace ? t.workspace : null;
            let icon = "";
            const de = appId.length ? DesktopEntries.heuristicLookup(appId) : null;
            if (de && de.icon) icon = Quickshell.iconPath(de.icon, true);
            if (!icon.length && appId.length) icon = Quickshell.iconPath(appId.toLowerCase(), true);
            let addr = String(t.address || "");
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            rows.push({
                text: t.title || appId || addr,
                sub: (appId || "window") + (ws ? "   ·   workspace " + ws.name : "") + (t.activated ? "   ·   focused" : ""),
                meta: appId + " " + (ws ? ws.name : ""),
                icon: icon,
                iconKind: icon.length ? 1 : 0,
                selectable: true,
                active: t.activated,
                address: addr,
                wsId: ws ? ws.id : 9999
            });
        }
        rows.sort((a, b) => a.wsId - b.wsId);
        return rows;
    }

    // ── open / close ───────────────────────────────────────────────────────
    function present(r) {
        const n = root.entries.length;
        let images = 0, icons = 0, nonEmpty = 0;
        for (let i = 0; i < n; i++) {
            const e = root.entries[i];
            if (e.iconKind === 2) images++;
            if (e.iconKind > 0) icons++;
            if (e.text.length || e.iconKind > 0) nonEmpty++;
        }
        const lines = (r.lines === undefined || r.lines === null) ? -1 : r.lines;
        card.inputOnly = root.mode === "dmenu" && (lines === 0 || nonEmpty === 0);
        card.grid = !card.inputOnly && images >= 4 && images * 2 >= n;
        card.showIcons = icons > 0;
        card.maxVisible = lines > 0 ? Math.max(3, Math.min(12, lines)) : 8;
        card.eyebrow = root.mode === "windows" ? "WINDOWS"
            : card.inputOnly ? "INPUT" : card.grid ? "CHOOSE" : "SELECT";
        card.prompt = Match.monochrome(r.prompt || "");
        card.message = Match.monochrome(Match.stripMarkup(r.mesg || ""));
        card.placeholder = Match.monochrome(r.placeholder || "");
        card.password = !!r.password;
        card.allowCustom = root.mode === "dmenu" && !r.noCustom;
        card.multiSelect = !!r.multiSelect;
        card.customKeys = root.customBindings(r.kb || {});

        // initial selection: -selected-row N, or the first row containing -select
        let sel = 0;
        if (typeof r.selectedRow === "number" && r.selectedRow > 0) sel = r.selectedRow;
        if (r.select && r.select.length) {
            const s = String(r.select).toLowerCase();
            for (let i = 0; i < n; i++)
                if (root.entries[i].text.toLowerCase().indexOf(s) >= 0) { sel = i; break; }
        }
        if (root.mode === "windows") {
            // start on the most recent other window, rofi-style
            for (let i = 0; i < n; i++)
                if (!root.entries[i].active) { sel = i; break; }
        }

        root.targetScreen = root.focusedScreen();
        card.reset(r.filter || "", 0);
        root.open = true;
        // map the entry index to its position in the (possibly filtered) list
        const pos = root.shown.indexOf(Math.min(sel, Math.max(0, n - 1)));
        card.selectedIndex = pos >= 0 ? pos : 0;
        card.fixSelection(1);
        Qt.callLater(card.reveal);
    }

    function customBindings(kb) {
        // rofi defaults: kb-custom-1..10 = Alt+1..Alt+0
        const out = [];
        for (let n = 1; n <= 19; n++) {
            const spec = kb[String(n)];
            if (spec !== undefined && spec !== null) {
                const keys = Match.parseKeys(spec);
                if (keys.length)
                    out.push({ n: n, keys: keys, label: root.keyLabel(spec) });
            } else if (n <= 10 && root.mode === "dmenu") {
                out.push({ n: n, keys: Match.parseKeys("Alt+" + (n % 10)), label: "" });
            }
        }
        return out;
    }

    function keyLabel(spec) {
        const first = String(spec).split(",")[0].trim();
        return first.split(/[+-](?=.)/).map(t => {
            const l = t.toLowerCase();
            return l === "control" ? "ctrl" : l === "delete" ? "del" : l === "return" ? "enter" : l;
        }).join("+");
    }

    function close() { root.open = false; }

    function focusedScreen() {
        const mon = Hyprland.focusedMonitor;
        const screens = Quickshell.screens;
        if (mon)
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === mon.name)
                    return screens[i];
        return screens.length ? screens[0] : null;
    }

    // write the result for the current request (if any) and close
    function finishCurrent(code, kind, payload) {
        const path = root.resultPath;
        root.requestPath = "";
        root.resultPath = "";
        if (path.length) {
            const filter = String(card.text).replace(/[\r\n]+/g, " ");
            const body = [String(code), kind, filter].concat(payload).join("\n") + "\n";
            resultWriter.path = path;
            resultWriter.setText(body);
            resultWriter.path = "";
        }
        if (root.open)
            root.close();
    }

    function pickedEntries(pos) {
        const keys = Object.keys(root.marked).filter(k => root.marked[k]).map(k => parseInt(k, 10));
        if (keys.length) {
            keys.sort((a, b) => a - b);
            return keys;
        }
        return pos >= 0 && pos < root.shown.length ? [root.shown[pos]] : [];
    }

    function onPicked(pos) {
        if (root.mode === "windows") {
            const e = root.entries[root.shown[pos]];
            root.close();
            if (e && e.address)
                Hyprland.dispatch(Hyprland.usingLua
                    ? 'hl.dsp.focus({ window = "address:' + e.address + '" })'
                    : "focuswindow address:" + e.address);
            return;
        }
        const cur = root.entries[root.shown[pos]];
        if (!cur || cur.selectable === false) return;
        const idx = root.pickedEntries(pos);
        if (!idx.length) return;
        root.finishCurrent(0, "items", idx.map(String));
    }

    function onCustom(text) {
        if (root.mode !== "dmenu" || root.req.noCustom) return;
        root.finishCurrent(0, "custom", [String(text).replace(/[\r\n]+/g, " ")]);
    }

    function onCustomKey(n, pos) {
        if (root.mode !== "dmenu") return;
        const idx = root.pickedEntries(pos);
        if (idx.length) root.finishCurrent(9 + n, "items", idx.map(String));
        else if (card.text.length) root.finishCurrent(9 + n, "custom", [card.text]);
        else root.finishCurrent(9 + n, "none", []);
    }

    function onMark(pos) {
        const i = root.shown[pos];
        if (i === undefined) return;
        const m = Object.assign({}, root.marked);
        if (m[i]) delete m[i]; else m[i] = true;
        root.marked = m;
    }

    FileView { id: reqReader; blockAllReads: true; printErrors: false; preload: false }
    FileView { id: itemsReader; blockAllReads: true; printErrors: false; preload: false }
    FileView { id: resultWriter; blockWrites: true; atomicWrites: true; printErrors: false; preload: false }

    // ── surface ────────────────────────────────────────────────────────────
    PanelWindow {
        id: win

        screen: root.targetScreen
        visible: root.open && !root.headless
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "sumi-picker"
        WlrLayershell.layer: WlrLayer.Overlay
        // exists only while open, so the exclusive grab is only held while
        // open (kept constant on purpose, see Launcher.qml)
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: if (visible) Qt.callLater(card.focusSearch)

        // dim + click-out = cancel
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.38)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.cancel()
            }
        }

        PickerCard {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(win.height * (card.grid ? 0.16 : 0.22))
            entries: root.entries
            shown: root.shown
            marked: root.marked

            onPicked: pos => root.onPicked(pos)
            onCustomPicked: text => root.onCustom(text)
            onCustomKey: (n, pos) => root.onCustomKey(n, pos)
            onMarkToggled: pos => root.onMark(pos)
            onDismissed: root.cancel()
        }
    }
}
