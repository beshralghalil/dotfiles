import QtQuick
import Quickshell
import Quickshell.Io

// SDDM-style `keyboard` object for the lock screen: layouts from mango's config
// (xkb_rules_layout) and the active one from `mmsg watch keyboardlayout`.
Scope {
    id: kb
    property bool numLock: true
    property bool capsLock: false
    property int currentLayout: 0
    property var layouts: []
    property string activeName: ""      // e.g. "English (US)", "Arabic"

    // "English (US)" matches "us"; "Arabic" matches "ara" (first two letters)
    function indexFor(name) {
        if (!name) return 0;
        const m = name.match(/\(([^)]+)\)/);
        const key = (m ? m[1] : name.slice(0, 2)).toLowerCase();
        for (let i = 0; i < kb.layouts.length; i++)
            if (kb.layouts[i].shortName.toLowerCase().startsWith(key)) return i;
        return 0;
    }
    onActiveNameChanged: currentLayout = indexFor(activeName)
    onLayoutsChanged: currentLayout = indexFor(activeName)

    Process {
        running: true
        command: ["sh", "-c", "sed -n -E 's/^[[:space:]]*xkb_rules_layout[[:space:]]*=[[:space:]]*\"([^\"]*)\".*/\\1/p' \"$HOME/.config/mango/config.toml\" | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim() || "us";
                kb.layouts = l.split(",").map(s => ({ shortName: s.trim(), longName: s.trim() }));
            }
        }
    }
    Process {
        running: true
        command: ["mmsg", "watch", "keyboardlayout"]
        stdout: SplitParser {
            onRead: line => {
                try { kb.activeName = JSON.parse(line).layout || ""; } catch (e) {}
            }
        }
    }
}
