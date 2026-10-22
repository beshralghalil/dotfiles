import QtQuick
import Quickshell
import Quickshell.Io

// Small pollers the bar needs that Quickshell has no service for. Nothing runs
// while `running` is false.
//   cpu / mem / temp   /proc + hwmon, every `statsInterval` ms
//   brightness         `brightnessctl -m`, every 5 s (and on refreshBrightness())
//   nightlight         hyprsunset process / state file, every 3 s
//   notifications      `swaync-client -swb` event stream (count + dnd)
Scope {
    id: root

    property bool running: true
    property int statsInterval: 3000
    property string home: Quickshell.env("HOME")

    property real cpu: -1
    property real mem: -1
    property real temp: -1
    property real brightness: -1       // 0..1
    property bool nightlight: false
    property int notifCount: 0
    property bool notifDnd: false

    function refreshBrightness() { if (root.running) brightProc.running = true }
    function refreshNightlight() { if (root.running) nightProc.running = true }

    // ── cpu / mem / temp (same probes as services/Stats.qml) ───────────────
    property real _lastTotal: 0
    property real _lastIdle: 0
    readonly property string _statsScript: "read -r _ u n s i w x y z _ < /proc/stat; echo $((u+n+s+i+w+x+y+z)) $((i+w));"
        + "awk '/^MemTotal/{t=$2}/^MemAvailable/{a=$2}END{print t, a}' /proc/meminfo;"
        + "t=-1; for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name 2>/dev/null) in coretemp|k10temp|zenpower) t=$(cat $h/temp1_input 2>/dev/null); break;; esac; done;"
        + "if [ \"$t\" = -1 ]; then for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && t=$(cat $z/temp); done; fi; echo $t"

    Process {
        id: statsProc
        command: ["sh", "-c", root._statsScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                if (l.length < 3) return;
                const c = l[0].split(" ").map(Number);
                const dt = c[0] - root._lastTotal, di = c[1] - root._lastIdle;
                if (root._lastTotal > 0 && dt > 0)
                    root.cpu = Math.max(0, Math.min(100, 100 * (1 - di / dt)));
                root._lastTotal = c[0];
                root._lastIdle = c[1];
                const m = l[1].split(" ").map(Number);
                if (m[0] > 0) root.mem = 100 * (m[0] - m[1]) / m[0];
                const t = Number(l[2]);
                root.temp = t >= 0 ? t / 1000 : -1;
            }
        }
    }
    Timer {
        interval: root.statsInterval
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    // ── backlight ──────────────────────────────────────────────────────────
    Process {
        id: brightProc
        // device,class,current,percent%,max ; prints nothing without a backlight
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m -c backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split(",");
                root.brightness = f.length >= 4 ? Number(f[3].replace("%", "")) / 100 : -1;
            }
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: brightProc.running = true
    }

    // ── night light (mirrors Hyprsunset.sh status) ─────────────────────────
    Process {
        id: nightProc
        command: ["sh", "-c", "if pgrep -x hyprsunset >/dev/null 2>&1; then echo on; else cat \"$HOME/.cache/.hyprsunset_state\" 2>/dev/null || echo off; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.nightlight = this.text.trim() === "on"
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: nightProc.running = true
    }

    // ── notifications: swaync-client streams one JSON line per change ─────
    //   {"text": "3", "alt": "dnd-notification", "class": ..., "tooltip": ...}
    Process {
        id: swayncProc
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line);
                    root.notifCount = parseInt(j.text) || 0;
                    root.notifDnd = (j.alt || "").indexOf("dnd") >= 0;
                } catch (e) {}
            }
        }
    }
    Timer { // (re)start the stream; covers swaync restarts and a late daemon
        interval: 10000
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: if (!swayncProc.running) swayncProc.running = true
    }
    onRunningChanged: if (!running) swayncProc.running = false
}
