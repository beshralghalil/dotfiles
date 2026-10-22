import QtQuick
import "../../common"

// 墨 (sumi) clock face: black-and-white, Japanese editorial.
//   [seal]  14:52
//   [十]    ──────────────   <- hairline fills across the minute
//   [月]    2026 · 10 · 21  WED
//   [...]   令和八年  神無月  秋
// Plain QtQuick (no Quickshell types) so it can be previewed off-screen.
// Layout idea (one face per file, scaled sizes, typography + one quiet motion)
// borrowed from Ryoku's desktop clock (github.com/ryoku-dev/ryoku, GPL-3.0).
Item {
    id: face

    property date now: new Date()
    property real scale_: 1.0

    property bool use24h: true
    property bool minuteLine: true

    readonly property color ink: Theme.ink
    readonly property color inkDim: Theme.inkDim
    readonly property color inkFaint: Theme.inkFaint
    readonly property color paper: Theme.paper
    readonly property string mono: Theme.mono
    readonly property string serif: Theme.serif

    function px(v) { return Math.round(v * face.scale_) }

    readonly property int hh: use24h ? now.getHours() : ((now.getHours() + 11) % 12 + 1)
    readonly property int mm: now.getMinutes()
    readonly property int ss: now.getSeconds()
    readonly property int mon: now.getMonth()
    readonly property int dom: now.getDate()
    readonly property int dow: now.getDay()
    readonly property string verticalDate: Theme.kanjiNum(mon + 1) + "月" + Theme.kanjiNum(dom) + "日"

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: face.px(30)

        // ── left: seal + vertical kanji date ──────────────────────────────
        Column {
            id: left
            spacing: face.px(16)
            topPadding: face.px(26)

            // hanko-style seal, monochrome: filled ink square, paper-coloured kanji
            Rectangle {
                width: face.px(58); height: width
                radius: face.px(3)
                color: face.ink
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -face.px(2)
                    text: Theme.weekdayKanji[face.dow]
                    color: face.paper
                    font.family: face.serif
                    font.weight: Font.Black
                    font.pixelSize: face.px(38)
                }
            }

            // date written top-to-bottom
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: face.px(2)
                Repeater {
                    model: face.verticalDate.length
                    Text {
                        required property int index
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: face.verticalDate.charAt(index)
                        color: face.inkDim
                        font.family: face.serif
                        font.weight: Font.Light
                        font.pixelSize: face.px(21)
                    }
                }
            }
        }

        // ── right: time, minute hairline, dates ───────────────────────────
        Column {
            id: right
            spacing: face.px(10)

            Row {
                id: time
                spacing: 0
                Text {
                    text: Theme.pad2(face.hh)
                    color: face.ink
                    font.family: face.mono
                    font.weight: Font.Thin
                    font.styleName: "Thin"
                    font.pixelSize: face.px(136)
                    font.letterSpacing: -face.px(4)
                }
                Text {
                    text: ":"
                    color: face.inkDim
                    font.family: face.mono
                    font.weight: Font.Thin
                    font.styleName: "Thin"
                    font.pixelSize: face.px(136)
                    font.letterSpacing: -face.px(4)
                }
                Text {
                    text: Theme.pad2(face.mm)
                    color: face.ink
                    font.family: face.mono
                    font.weight: Font.Thin
                    font.styleName: "Thin"
                    font.pixelSize: face.px(136)
                    font.letterSpacing: -face.px(4)
                }
                Text {
                    visible: !face.use24h
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: face.px(30)
                    leftPadding: face.px(14)
                    text: face.now.getHours() < 12 ? "AM" : "PM"
                    color: face.inkDim
                    font.family: face.mono
                    font.weight: Font.Light
                    font.pixelSize: face.px(22)
                }
            }

            // hairline that fills across the current minute
            Item {
                visible: face.minuteLine
                width: time.width
                height: Math.max(1, face.px(1))
                Rectangle { anchors.fill: parent; color: face.inkFaint }
                Rectangle {
                    height: parent.height
                    width: parent.width * face.ss / 59
                    color: face.ink
                    Behavior on width {
                        enabled: face.ss !== 0
                        NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                topPadding: face.px(6)
                text: face.now.getFullYear() + " · " + Theme.pad2(face.mon + 1) + " · " + Theme.pad2(face.dom)
                      + "    " + Theme.weekdayLatin[face.dow]
                color: face.inkDim
                font.family: face.mono
                font.weight: Font.Light
                font.pixelSize: face.px(17)
                font.letterSpacing: face.px(3)
            }

            Text {
                text: Theme.era(face.now.getFullYear()) + "　" + Theme.monthNames[face.mon] + "　" + Theme.season(face.mon)
                color: face.inkDim
                font.family: face.serif
                font.weight: Font.Light
                font.pixelSize: face.px(19)
                font.letterSpacing: face.px(5)
            }
        }
    }
}
