pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / memory / CPU temperature / uptime, polled every 2 s while the stats
// widget is enabled (nothing runs otherwise).
Singleton {
    id: root

    property bool active: Config.data.statsEnabled
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0    // GiB
    property real memTotal: 0   // GiB
    property real temp: -1      // °C
    property string uptime: ""

    property real lastTotal: 0
    property real lastIdle: 0

    // line 1: cpu total + idle jiffies, line 2: mem total + available kB,
    // line 3: CPU temp in milli-°C (coretemp / k10temp / zenpower, else x86_pkg_temp), line 4: uptime s
    readonly property string script: "read -r _ u n s i w x y z _ < /proc/stat; echo $((u+n+s+i+w+x+y+z)) $((i+w));"
        + "awk '/^MemTotal/{t=$2}/^MemAvailable/{a=$2}END{print t, a}' /proc/meminfo;"
        + "t=-1; for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name 2>/dev/null) in coretemp|k10temp|zenpower) t=$(cat $h/temp1_input 2>/dev/null); break;; esac; done;"
        + "if [ \"$t\" = -1 ]; then for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && t=$(cat $z/temp); done; fi; echo $t;"
        + "cut -d. -f1 /proc/uptime"

    Process {
        id: proc
        command: ["sh", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                if (l.length < 4) return;
                const c = l[0].split(" ").map(Number);
                const dt = c[0] - root.lastTotal, di = c[1] - root.lastIdle;
                if (root.lastTotal > 0 && dt > 0)
                    root.cpu = Math.max(0, Math.min(100, 100 * (1 - di / dt)));
                root.lastTotal = c[0];
                root.lastIdle = c[1];

                const m = l[1].split(" ").map(Number);
                if (m[0] > 0) {
                    root.memTotal = m[0] / 1048576;
                    root.memUsed = (m[0] - m[1]) / 1048576;
                    root.mem = 100 * (m[0] - m[1]) / m[0];
                }
                const t = Number(l[2]);
                root.temp = t >= 0 ? t / 1000 : -1;

                const up = Number(l[3]);
                const d = Math.floor(up / 86400), h = Math.floor(up % 86400 / 3600), mi = Math.floor(up % 3600 / 60);
                root.uptime = (d > 0 ? d + "d " : "") + h + "h " + mi + "m";
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
