import QtQuick
import "../../common"

// Music visualizer, 墨 style:
//   [音] 再生中  ─────────────────────────────  1:23 / 3:34
//   ▌▌ ▌▌▌ ▌▌▌▌ ▌  ▌▌▌ ▌▌▌▌▌ ▌▌▌  ▌▌ ▌▌▌▌▌    <- live spectrum (ink)
//   ───────────────────────────────────────    <- water line
//   ▖▖ ▖▖▖ ▖▖▖▖ ▖  ▖▖▖ ▖▖▖▖▖ ▖▖▖  ▖▖ ▖▖▖▖▖    <- faint reflection
//   Title — Artist                    ◀◀  ❚❚  ▶▶
// Spectrum levels (0..1 per band) come from cava via the AudioBars service;
// track data from MPRIS. Plain QtQuick so it can be previewed off-screen.
Item {
    id: music

    property bool hasPlayer: false
    property string title: ""
    property string artist: ""
    property bool playing: false
    property real position: 0   // seconds
    property real length: 0     // seconds
    property var levels: []     // spectrum, 0..1 per band
    property real scale_: 1.0

    signal togglePlay()
    signal next()
    signal previous()

    function px(v) { return Math.round(v * music.scale_) }
    function fmt(s) {
        if (!(s > 0)) return "0:00";
        const m = Math.floor(s / 60), r = Math.floor(s % 60);
        return m + ":" + Theme.pad2(r);
    }

    readonly property int bandCount: Math.max(1, levels.length || 40)
    readonly property real vizW: px(400)
    readonly property real vizH: px(54)         // height above the water line
    readonly property real reflectH: px(16)     // reflection depth below it
    readonly property real pitch: vizW / bandCount
    readonly property real barW: Math.max(2, pitch * 0.42)

    implicitWidth: vizW
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: music.vizW
        spacing: music.px(9)

        // header: seal, state, rule, time
        Item {
            width: parent.width
            height: seal.height
            Rectangle {
                id: seal
                width: music.px(26); height: width
                radius: music.px(2)
                color: music.playing ? Theme.ink : "transparent"
                border.color: Theme.hairline
                border.width: music.playing ? 0 : 1
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -music.px(1)
                    text: "\u{F075A}" // music note
                    color: music.playing ? Theme.paper : Theme.inkDim
                    font.family: Theme.icon
                    font.pixelSize: music.px(16)
                }
            }
            Text {
                id: state
                anchors.left: seal.right
                anchors.leftMargin: music.px(14)
                anchors.verticalCenter: seal.verticalCenter
                text: music.hasPlayer ? (music.playing ? "NOW PLAYING" : "PAUSED") : "SILENT"
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.pixelSize: music.px(11)
                font.letterSpacing: music.px(3)
            }
            Rectangle {
                anchors.left: state.right
                anchors.leftMargin: music.px(14)
                anchors.right: times.left
                anchors.rightMargin: music.px(14)
                anchors.verticalCenter: seal.verticalCenter
                height: 1
                color: Theme.inkFaint
                // track progress along the header rule
                Rectangle {
                    height: 1
                    width: music.length > 0 ? parent.width * Math.min(1, music.position / music.length) : 0
                    color: Theme.inkDim
                }
            }
            Text {
                id: times
                anchors.right: parent.right
                anchors.verticalCenter: seal.verticalCenter
                visible: music.hasPlayer
                text: music.fmt(music.position) + " / " + music.fmt(music.length)
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.pixelSize: music.px(11)
            }
        }

        // spectrum + water line + reflection
        Item {
            width: music.vizW
            height: music.vizH + 1 + music.reflectH

            Repeater {
                model: music.bandCount
                Item {
                    required property int index
                    readonly property real level: music.playing ? Math.pow(music.levels[index] || 0, 0.65) : 0
                    x: index * music.pitch + (music.pitch - music.barW) / 2
                    width: music.barW
                    height: parent.height

                    Rectangle { // bar, rising from the water line
                        width: parent.width
                        height: Math.max(1, parent.level * music.vizH)
                        y: music.vizH - height
                        color: Theme.ink
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutSine } }
                    }
                    Rectangle { // reflection, fading below the line
                        y: music.vizH + 1 + music.px(2)
                        width: parent.width
                        height: Math.max(0, parent.level * music.reflectH)
                        opacity: 0.22
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.ink }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutSine } }
                    }
                }
            }
            Rectangle { // water line
                y: music.vizH
                width: parent.width
                height: 1
                color: Theme.hairline
            }
        }

        // track line + transport
        Item {
            width: parent.width
            height: Math.max(track.implicitHeight, transport.height)
            Text {
                id: track
                anchors.left: parent.left
                anchors.right: transport.left
                anchors.rightMargin: music.px(18)
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: !music.hasPlayer ? "Nothing playing"
                    : (music.title || "Unknown title") + (music.artist ? "  —  " + music.artist : "")
                color: music.hasPlayer ? Theme.ink : Theme.inkDim
                font.family: Theme.sans
                font.weight: Font.Light
                font.pixelSize: music.px(13)
            }
            Row {
                id: transport
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: music.hasPlayer
                spacing: music.px(14)
                TransportButton { kind: "prev"; onClicked: music.previous() }
                TransportButton { kind: music.playing ? "pause" : "play"; onClicked: music.togglePlay() }
                TransportButton { kind: "next"; onClicked: music.next() }
            }
        }
    }

    component TransportButton: Item {
        id: btn
        property string kind: "play"
        signal clicked()
        width: music.px(20); height: width
        opacity: area.containsMouse ? 1.0 : 0.7
        onKindChanged: glyph.requestPaint()
        Canvas {
            id: glyph
            anchors.fill: parent
            onPaint: {
                const c = getContext("2d"), w = width, h = height;
                c.reset();
                c.fillStyle = Theme.ink;
                const tri = (x0, x1) => { c.beginPath(); c.moveTo(x0, h * 0.24); c.lineTo(x1, h * 0.5); c.lineTo(x0, h * 0.76); c.closePath(); c.fill(); };
                if (btn.kind === "play") tri(w * 0.32, w * 0.76);
                else if (btn.kind === "pause") { c.fillRect(w * 0.32, h * 0.24, w * 0.1, h * 0.52); c.fillRect(w * 0.58, h * 0.24, w * 0.1, h * 0.52); }
                else if (btn.kind === "next") { tri(w * 0.24, w * 0.66); c.fillRect(w * 0.7, h * 0.24, w * 0.07, h * 0.52); }
                else if (btn.kind === "prev") {
                    c.beginPath(); c.moveTo(w * 0.76, h * 0.24); c.lineTo(w * 0.34, h * 0.5); c.lineTo(w * 0.76, h * 0.76); c.closePath(); c.fill();
                    c.fillRect(w * 0.23, h * 0.24, w * 0.07, h * 0.52);
                }
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
