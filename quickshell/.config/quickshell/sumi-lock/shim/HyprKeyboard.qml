import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// SDDM-style `keyboard` object for the lock screen: layouts and the active one of Hyprland's main keyboard
Scope {
    id: kb
    property bool numLock: true
    property bool capsLock: false
    property int currentLayout: 0
    property var layouts: []

    Process {
        id: query
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var main = JSON.parse(this.text).keyboards.find(k => k.main);
                    if (!main) return;
                    kb.layouts = main.layout.split(",").map(l => ({ shortName: l.trim(), longName: l.trim() }));
                    kb.currentLayout = Math.max(0, main.active_layout_index);
                } catch (e) {
                    console.warn("HyprKeyboard: cannot read hyprctl devices:", e);
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") query.running = true;
        }
    }
}
