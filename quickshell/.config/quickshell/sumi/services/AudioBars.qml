pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Live audio spectrum from cava (40 bands, 30 fps, PipeWire input, raw ascii
// output). Runs only while the music widget is enabled AND a player is playing,
// so it costs nothing otherwise. Adapted from Ryoku's AudioBars service
// (github.com/ryoku-dev/ryoku, GPL-3.0).
Singleton {
    id: root

    readonly property int bars: 40
    readonly property int fps: 30
    readonly property bool anyPlaying: Mpris.players.values.some(p => p.isPlaying && !(p.dbusName || "").includes("playerctld"))
    readonly property bool active: Config.data.musicEnabled && root.anyPlaying

    property var levels: root.flat()
    property real lastReadMs: 0

    function flat() {
        const a = [];
        for (let i = 0; i < root.bars; i++) a.push(0);
        return a;
    }

    Process {
        id: cava
        property bool backoff: false
        running: root.active && !cava.backoff
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1 || exit 0; cfg=\"${XDG_RUNTIME_DIR:-/tmp}/sumi-cava.conf\"; printf '%s\\n' '[general]' 'framerate = " + root.fps + "' 'bars = " + root.bars + "' '' '[input]' 'method = pipewire' 'source = auto' '' '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 100' 'channels = mono' 'mono_option = average' '' '[smoothing]' 'noise_reduction = 55' > \"$cfg\"; exec cava -p \"$cfg\""]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root.readBars(line)
        }
        // restart after a crash, with a short back-off
        onExited: if (root.active) { cava.backoff = true; restart.restart(); }
    }
    Timer { id: restart; interval: 1200; onTriggered: cava.backoff = false }

    // fall flat if cava stalls
    Timer {
        interval: 150
        running: root.active
        repeat: true
        onTriggered: if (Date.now() - root.lastReadMs > 300) root.levels = root.flat()
    }
    onActiveChanged: { root.levels = root.flat(); root.lastReadMs = 0; }

    function readBars(line) {
        const parts = line.trim().split(/[;\s]+/);
        if (parts.length < root.bars) return;
        const out = [];
        for (let i = 0; i < root.bars; i++) {
            const n = parseInt(parts[i]);
            out.push(isNaN(n) ? 0 : Math.max(0, Math.min(1, n / 100)));
        }
        root.levels = out;
        root.lastReadMs = Date.now();
    }
}
