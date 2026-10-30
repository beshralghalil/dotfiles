import QtQuick
import "../common"

// Kanji label + thin mono value (+ small unit), optionally over a hairline gauge:
//   電 87%      音 45
//   ───          ━━──
Row {
    id: r

    property string label: ""
    property string value: ""
    property string unit: ""
    property real frac: -1          // 0..1 draws a hairline gauge under the value; <0 = none
    property bool dim: false        // whole readout in inkDim (muted / idle)
    property bool sealed: false     // label as an ink-filled seal (emphasis, e.g. battery low)
    property bool valueSerif: false // value is a kanji word rather than a number

    spacing: 5
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Seal {
        text: r.label
        filled: r.sealed
        dim: r.dim
        size: 18
        glyphSize: 14
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: valueRow.implicitWidth
        implicitHeight: 18

        Row {
            id: valueRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: r.frac >= 0 ? -1 : 0
            Text {
                id: v
                text: r.value
                color: r.dim ? Theme.inkDim : Theme.ink
                font.family: r.valueSerif ? Theme.serif : Theme.mono
                font.weight: Font.Light
                font.styleName: r.valueSerif ? "" : "Light"
                font.pixelSize: r.valueSerif ? 12 : 13
            }
            Text {
                visible: r.unit !== ""
                anchors.baseline: v.baseline
                text: r.unit
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.styleName: "Light"
                font.pixelSize: 10
            }
        }

        Rectangle {
            visible: r.frac >= 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -1
            width: parent.width
            height: 1
            color: Theme.inkFaint
            Rectangle {
                height: 1
                width: parent.width * Math.max(0, Math.min(1, r.frac))
                color: r.dim ? Theme.inkDim : Theme.ink
                Behavior on width { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.OutCubic } }
            }
        }
    }
}
