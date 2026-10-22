pragma Singleton
import QtQuick
import "../common"
import Quickshell
import Quickshell.Io

// Live settings in ~/.config/sumi/widgets.json. The right-click menu, IPC calls
// (`qs -p ~/.config/quickshell/sumi ipc call widgets ...`) and hand edits all
// meet in that file; FileView watches it, so a save retunes the running shell.
// Pattern adapted from Ryoku's desktop Config (github.com/ryoku-dev/ryoku, GPL-3.0).
Singleton {
    id: root

    readonly property var widgetNames: ["clock", "calendar", "music", "weather", "stats"]
    readonly property alias data: adapter
    property bool ready: false

    function get(key) { return adapter[key] }
    function set(key, value) {
        adapter[key] = value;
        file.writeAdapter();
    }
    // several keys, one write (avoids a stale reload landing between writes)
    function setMany(values) {
        for (const key in values)
            adapter[key] = values[key];
        file.writeAdapter();
    }
    // memory only (live drag); the release does the persisting setMany()
    function setLive(key, value) { adapter[key] = value }
    function toggle(key) { set(key, !adapter[key]) }

    function isWidget(name) { return widgetNames.indexOf(name) >= 0 }
    function resetPosition(name) {
        const d = defaults[name];
        if (d) setMany({ [name + "X"]: d[0], [name + "Y"]: d[1] });
    }
    // default positions on a 1920x1080 screen, clear of the wallpaper's subject
    readonly property var defaults: ({
        clock: [120, 110],      // top-left
        music: [120, 834],      // bottom-left, same margins as the clock
        calendar: [1600, 420],  // right edge, beside the halo
        weather: [1540, 120],
        stats: [1540, 870]
    })

    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/sumi/widgets.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            root.ready = true;
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // ── desktop widgets (only the clock is on by default) ─────────
            property bool clockEnabled: true
            property int clockX: 120
            property int clockY: 110
            property bool clockLocked: false
            property bool clock24h: true
            property bool clockMinuteLine: true

            property bool calendarEnabled: false
            property int calendarX: 1600
            property int calendarY: 420
            property bool calendarLocked: false

            property bool musicEnabled: false
            property int musicX: 120
            property int musicY: 834
            property bool musicLocked: false

            property bool weatherEnabled: false
            property int weatherX: 1540
            property int weatherY: 120
            property bool weatherLocked: false
            // set a city name; it is geocoded once via open-meteo.com
            property string weatherCity: ""
            property bool weatherFahrenheit: false

            property bool statsEnabled: false
            property int statsX: 1540
            property int statsY: 870
            property bool statsLocked: false

            // ── shell modules (off until you switch them on) ──────────────
            property bool barEnabled: false
            property bool launcherEnabled: false
        }
    }
}
