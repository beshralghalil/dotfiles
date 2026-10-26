import QtQuick
import "../common"

// 墨 bar, visual layer. Plain QtQuick: every value comes in as a property and
// every interaction goes out through `action(name, arg)`, so this file can be
// rendered off-screen with fake data. Bar.qml feeds it from Quickshell services.
//
//  左  醒 │ tray │ [水] 14:52 10·21 │ window title…
//  中  墨 · 一 [二] 三 四 五 · 報 3
//  右  光 60 電 87% │ 処 12 記 41 温 52° │ 音 45 声 消 │ 奏 title — artist │ 夜 終
//
// Typographic idiom (thin mono numerals, mincho labels, hairlines, ink seals)
// adapted from Ryoku (github.com/ryoku-dev/ryoku, GPL-3.0).
Item {
    id: bar

    // ── data ───────────────────────────────────────────────────────────────
    property date now: new Date()
    property bool use24h: true
    property string windowTitle: ""
    property var workspaces: []          // [{ id, name, active, occupied, urgent }]
    property string numerals: "kanji"    // "kanji" | "mono"
    property int notifCount: 0
    property bool notifDnd: false
    property bool idleInhibit: false
    property bool nightlight: false
    property real battery: -1            // 0..1, < 0 = no battery
    property bool charging: false
    property real brightness: -1         // 0..1, < 0 = unknown / no backlight
    property real cpu: -1                // %
    property real mem: -1                // %
    property real temp: -1               // °C
    property real gpuTemp: -1            // °C, discrete GPU
    property bool hasSink: false
    property real volume: 0              // 0..1(+)
    property bool muted: false
    property bool hasMic: false
    property real micVolume: 0
    property bool micMuted: false
    property bool hasMedia: false
    property bool mediaPlaying: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string kbLayout: ""        // short layout code, e.g. "US", "AR"
    property Component trayComponent: null

    // ── layout switches ───────────────────────────────────────────────────
    property bool showTitle: true
    property bool showStats: true
    property bool showBrightness: true
    property bool showMic: true
    property bool showMedia: true
    property int mediaMaxWidth: 240
    function batteryIcon(f) { // battery level glyphs, 10 steps
        const icons = ["\u{F007A}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0079}"];
        return icons[Math.max(0, Math.min(9, Math.floor(f * 10)))];
    }
    property int batteryLow: 15          // % at/below which the battery label is sealed

    signal action(string name, var arg)

    implicitHeight: 36

    // ── chrome ─────────────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; color: Theme.card }

    function cleanTitle(t) {
        if (!t) return "";
        return t.replace(/\s+[—-]\s+Mozilla Firefox$/, "")
                .replace(/\s+[—-]\s+(Chromium|Google Chrome|Brave)$/, "")
                .replace(/\s+-\s+(fish|zsh|bash)$/, "");
    }
    readonly property int hh: use24h ? now.getHours() : ((now.getHours() + 11) % 12 + 1)

    // ── left ───────────────────────────────────────────────────────────────
    Row {
        id: left
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        height: parent.height
        spacing: 2

        Chip { // idle inhibitor (keep the screen awake)
            onClicked: bar.action("idle", null)
            Seal { text: bar.idleInhibit ? "\u{F0176}" : "\u{F06CA}"; filled: bar.idleInhibit; dim: !bar.idleInhibit } // coffee: keep awake
        }

        Loader {
            id: trayLoader
            anchors.verticalCenter: parent.verticalCenter
            active: bar.trayComponent !== null
            sourceComponent: bar.trayComponent
            // don't gate on the tray's width here: its icons count as invisible while
            // this loader is hidden, so the width would stay 0 and it never shows
            visible: !!item
        }
        Rule { visible: !!trayLoader.item && trayLoader.item.implicitWidth > 0 }

        Chip { // clock: weekday seal, HH:MM, date (click: long date)
            id: clockChip
            spacing: 7
            onClicked: bar.action("calendar", clockChip.mapToItem(bar, 0, 0).x)  // open the calendar under the clock
            Text { // weekday
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.weekdayLatin[bar.now.getDay()]
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.styleName: "Light"
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: Theme.pad2(bar.hh) + ":" + Theme.pad2(bar.now.getMinutes())
                    color: Theme.ink
                    font.family: Theme.mono
                    font.weight: Font.ExtraLight
                    font.styleName: "ExtraLight"
                    font.pixelSize: 17
                }
                Text {
                    visible: !bar.use24h
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 4
                    text: bar.now.getHours() < 12 ? "AM" : "PM"
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.pad2(bar.now.getMonth() + 1) + "·" + Theme.pad2(bar.now.getDate())
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.styleName: "Light"
                font.pixelSize: 12
                font.letterSpacing: 1
            }
        }

        Rule { visible: bar.showTitle }

        Item { // active window title, elided to the room left before the centre
            visible: bar.showTitle
            height: parent.height
            width: Math.max(0, Math.min(titleText.implicitWidth + 14,
                                        center.x - 16 - x - left.x))
            Text {
                id: titleText
                x: 7
                width: parent.width - 14
                anchors.verticalCenter: parent.verticalCenter
                text: bar.cleanTitle(bar.windowTitle) || "—"
                elide: Text.ElideRight
                color: bar.windowTitle ? Theme.inkDim : Theme.inkFaint
                font.family: Theme.sans
                font.weight: Font.Light
                font.pixelSize: 12
                font.letterSpacing: 0.5
            }
        }
    }

    // ── centre ─────────────────────────────────────────────────────────────
    Row {
        id: center
        anchors.centerIn: parent
        height: parent.height
        spacing: 2

        Chip { // launcher (app drawer): sumi launcher
            onClicked: b => bar.action(b === Qt.RightButton ? "launcherAlt" : "launcher", null)
            Seal { text: "\u{F003B}"; outlined: true } // apps
        }
        Dot {}
        Workspaces {
            model: bar.workspaces
            numerals: bar.numerals
            onActivate: id => bar.action("workspace", id)
            onStep: dir => bar.action("workspaceStep", dir)
        }
        Dot {}
        Chip { // notifications (swaync): bell / bell-off when do-not-disturb
            spacing: 4
            onClicked: b => bar.action(b === Qt.RightButton ? "notifDnd" : "notif", null)
            Seal {
                text: bar.notifDnd ? "\u{F009B}" : "\u{F009A}"
                filled: bar.notifCount > 0 && !bar.notifDnd
                dim: bar.notifCount === 0 || bar.notifDnd
            }
            Text {
                visible: bar.notifCount > 0
                anchors.verticalCenter: parent.verticalCenter
                text: bar.notifCount > 99 ? "99+" : "" + bar.notifCount
                color: bar.notifDnd ? Theme.inkDim : Theme.ink
                font.family: Theme.mono
                font.styleName: "Light"
                font.weight: Font.Light
                font.pixelSize: 12
            }
        }
    }

    // ── right ──────────────────────────────────────────────────────────────
    Row {
        id: right
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        height: parent.height
        spacing: 2

        Chip { // keyboard layout; click to switch
            visible: bar.kbLayout !== ""
            onClicked: bar.action("kbLayout", null)
            Readout { label: "\u{F030C}"; value: bar.kbLayout }
        }
        Rule { visible: bar.kbLayout !== "" }
        Chip { // backlight, scroll to change
            visible: bar.showBrightness && bar.brightness >= 0
            onScrolled: s => bar.action("brightnessStep", s)
            Readout { label: "\u{F00E0}"; value: "" + Math.round(bar.brightness * 100); frac: bar.brightness }
        }
        Chip { // battery (level glyph / charging); sealed when low
            visible: bar.battery >= 0
            onClicked: b => bar.action("battery", b)
            Readout {
                label: bar.charging ? "\u{F0084}" : bar.batteryIcon(bar.battery)
                value: "" + Math.round(bar.battery * 100)
                unit: "%"
                frac: bar.battery
                sealed: !bar.charging && Math.round(bar.battery * 100) <= bar.batteryLow
            }
        }
        Rule { visible: bar.showStats && bar.cpu >= 0 && (bar.battery >= 0 || (bar.showBrightness && bar.brightness >= 0)) }
        Chip { // system: cpu, memory, cpu temperature, gpu temperature
            visible: bar.showStats && bar.cpu >= 0
            spacing: 9
            onClicked: b => bar.action("stats", b)
            Readout { label: "\u{F0EE0}"; value: "" + Math.round(bar.cpu); frac: bar.cpu / 100 }
            Readout { label: "\u{F035B}"; value: "" + Math.round(bar.mem); frac: bar.mem / 100 }
            Readout {
                visible: bar.temp >= 0
                label: "\u{F050F}"; value: "" + Math.round(bar.temp); unit: "°"
                frac: Math.min(1, bar.temp / 100)
                sealed: bar.temp >= 85
            }
            Readout {
                visible: bar.gpuTemp >= 0
                label: "\u{F08AE}"; value: "" + Math.round(bar.gpuTemp); unit: "°"
                frac: Math.min(1, bar.gpuTemp / 100)
                sealed: bar.gpuTemp >= 85
            }
        }
        Rule { visible: bar.hasSink || (bar.showMic && bar.hasMic) }
        Chip { // speaker: 音, scroll volume, click mute, right-click mixer
            visible: bar.hasSink
            onClicked: b => bar.action(b === Qt.RightButton ? "mixer" : b === Qt.MiddleButton ? "micMute" : "mute", null)
            onScrolled: s => bar.action("volumeStep", s)
            Readout {
                label: bar.muted ? "\u{F0581}" : bar.volume < 0.34 ? "\u{F057F}" : bar.volume < 0.67 ? "\u{F0580}" : "\u{F057E}"
                value: bar.muted ? "off" : "" + Math.round(bar.volume * 100)
                frac: bar.muted ? -1 : Math.min(1, bar.volume)
                dim: bar.muted
            }
        }
        Chip { // microphone
            visible: bar.showMic && bar.hasMic
            onClicked: b => bar.action(b === Qt.RightButton ? "micMixer" : "micMute", null)
            onScrolled: s => bar.action("micStep", s)
            Readout {
                label: bar.micMuted ? "\u{F036D}" : "\u{F036C}"
                value: bar.micMuted ? "off" : "" + Math.round(bar.micVolume * 100)
                frac: bar.micMuted ? -1 : Math.min(1, bar.micVolume)
                dim: bar.micMuted
            }
        }
        Rule { visible: mediaChip.visible && (bar.hasSink || (bar.showMic && bar.hasMic)) }
        Chip { // MPRIS: click play-pause, right next, middle previous
            id: mediaChip
            visible: bar.showMedia && bar.hasMedia
            spacing: 6
            onClicked: b => bar.action(b === Qt.RightButton ? "mediaNext" : b === Qt.MiddleButton ? "mediaPrev" : "mediaToggle", null)
            onScrolled: s => bar.action("volumeStep", s)
            Seal { text: bar.mediaPlaying ? "\u{F075A}" : "\u{F03E4}"; dim: !bar.mediaPlaying }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, bar.mediaMaxWidth)
                elide: Text.ElideRight
                text: bar.mediaTitle + (bar.mediaArtist ? "  —  " + bar.mediaArtist : "")
                color: bar.mediaPlaying ? Theme.ink : Theme.inkDim
                font.family: Theme.sans
                font.weight: Font.Light
                font.pixelSize: 12
            }
        }
        Rule { visible: mediaChip.visible || bar.hasSink || (bar.showMic && bar.hasMic) || (bar.showStats && bar.cpu >= 0) }
        Chip { // night light (hyprsunset)
            onClicked: bar.action("nightlight", null)
            Seal { text: "\u{F0594}"; filled: bar.nightlight; dim: !bar.nightlight }
        }
        Chip { // session: click power menu, right-click lock
            onClicked: b => bar.action(b === Qt.RightButton ? "lock" : "power", null)
            Seal { text: "\u{F0425}"; dim: true }
        }
    }

    component Dot: Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "·"
        color: Theme.inkFaint
        font.family: Theme.mono
        font.pixelSize: 12
    }
}
