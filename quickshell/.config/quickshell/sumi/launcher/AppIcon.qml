import QtQuick
import QtQuick.Effects
import "../common"

// An app icon pressed into ink: the image is drawn through MultiEffect with
// saturation -1, so even colourful icons stay black-and-white. Without an icon
// (or if it fails to load) a hairline square with the name's first letter
// stands in. Plain QtQuick so it renders in off-screen previews; in the shell
// `source` is a Quickshell.iconPath() URL.
Item {
    id: root

    property url source
    property string name: ""
    property bool active: false

    readonly property bool hasImage: img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize.width: Math.round(root.width * 2)
        sourceSize.height: Math.round(root.height * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.hasImage
        saturation: -1
        contrast: 0.08
        brightness: root.active ? 0.04 : -0.06
        opacity: root.active ? 1 : 0.72
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.hasImage
        color: "transparent"
        radius: 2
        border.color: root.active ? Theme.ink : Theme.inkDim
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: root.name.length ? root.name.charAt(0).toUpperCase() : "?"
            color: root.active ? Theme.ink : Theme.inkDim
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: Math.round(root.height * 0.5)
        }
    }
}
