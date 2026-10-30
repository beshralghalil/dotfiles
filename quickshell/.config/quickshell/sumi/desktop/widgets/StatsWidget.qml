import QtQuick
import "../../common"

// System readout, 墨 style. One row per metric:
//   処理  CPU   ━━━━━━──────────  23%
//   記憶  MEM   ━━━━━━━━━───────  41%   6.5 / 15.6 G
//   温度  TEMP  ━━━━━━━━────────  52°
Item {
    id: st

    property real cpu: 0        // percent
    property real mem: 0        // percent
    property real memUsed: 0    // GiB
    property real memTotal: 0   // GiB
    property real temp: -1      // °C, -1 = unknown
    property string uptime: ""
    property real scale_: 1.0
    function px(v) { return Math.round(v * st.scale_) }

    implicitWidth: px(360)
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: st.implicitWidth
        spacing: st.px(12)

        Metric { kanji: "\u{F0EE0}"; latin: "CPU"; frac: st.cpu / 100; value: Math.round(st.cpu) + "%" }
        Metric {
            kanji: "\u{F035B}"; latin: "MEM"; frac: st.mem / 100; value: Math.round(st.mem) + "%"
            note: st.memTotal > 0 ? st.memUsed.toFixed(1) + " / " + st.memTotal.toFixed(1) + " G" : ""
        }
        Metric {
            visible: st.temp >= 0
            kanji: "\u{F050F}"; latin: "TEMP"; frac: Math.min(1, st.temp / 100); value: Math.round(st.temp) + "°"
        }
        Text {
            visible: st.uptime !== ""
            text: "UP  " + st.uptime
            color: Theme.inkDim
            font.family: Theme.mono
            font.weight: Font.Light
            font.pixelSize: st.px(14)
            font.letterSpacing: st.px(2)
        }
    }

    component Metric: Column {
        property string kanji
        property string latin
        property real frac: 0
        property string value
        property string note: ""
        width: st.implicitWidth
        spacing: st.px(5)
        Item {
            width: parent.width
            height: k.implicitHeight
            Row {
                spacing: st.px(10)
                Text {
                    id: k
                    text: kanji
                    color: Theme.ink
                    font.family: Theme.icon
                    font.weight: Font.Light
                    font.pixelSize: st.px(17)
                }
                Text {
                    anchors.baseline: k.baseline
                    text: latin
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.weight: Font.Light
                    font.pixelSize: st.px(12)
                    font.letterSpacing: st.px(3)
                }
                Text {
                    anchors.baseline: k.baseline
                    visible: note !== ""
                    text: note
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.weight: Font.Light
                    font.pixelSize: st.px(12)
                }
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: value
                color: Theme.ink
                font.family: Theme.mono
                font.weight: Font.Light
                font.pixelSize: st.px(15)
            }
        }
        Rectangle {
            width: parent.width
            height: Math.max(1, st.px(1))
            color: Theme.inkFaint
            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, frac))
                color: Theme.ink
                Behavior on width { NumberAnimation { duration: Theme.ms(600); easing.type: Easing.OutCubic } }
            }
        }
    }
}
