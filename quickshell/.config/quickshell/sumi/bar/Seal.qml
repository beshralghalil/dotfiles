import QtQuick
import "../common"

// A single icon glyph that can be "sealed": an ink-filled square with a
// paper-coloured glyph (emphasis / on-state), an outlined square, or bare.
Item {
    id: seal

    property string text: ""
    property bool filled: false
    property bool outlined: false
    property bool dim: false
    property int size: 20
    property int glyphSize: Math.round(size * 0.72)
    property string family: Theme.icon

    implicitWidth: size
    implicitHeight: size
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: seal.filled ? Theme.ink : "transparent"
        border.width: seal.outlined && !seal.filled ? 1 : 0
        border.color: Theme.hairline
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0
        text: seal.text
        color: seal.filled ? Theme.paper : seal.dim ? Theme.inkDim : Theme.ink
        font.family: seal.family
        font.weight: Font.Normal
        font.pixelSize: seal.glyphSize
        Behavior on color { ColorAnimation { duration: 160 } }
    }
}
