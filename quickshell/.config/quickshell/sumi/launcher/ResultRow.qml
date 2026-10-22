import QtQuick
import "../common"

// One launcher row:  [01 | ■]  [icon]  Name                    起動 ↵
//                                     generic name (dim)
// Unselected rows carry a faint two-digit index; the selected row swaps it for
// a filled ink square (the hanko motif used across sumi) on a hover wash.
// Plain QtQuick so it renders in off-screen previews.
Item {
    id: row

    property int ordinal: 0
    property string name: ""
    property string generic: ""
    property url icon
    property bool selected: false

    signal hovered(real sceneX, real sceneY)
    signal clicked()

    height: 52

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: row.selected ? Theme.hover : area.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
    }

    // index / selection marker
    Item {
        id: marker
        x: 0
        width: 34
        height: parent.height
        Text {
            anchors.centerIn: parent
            visible: !row.selected
            text: Theme.pad2(row.ordinal + 1)
            color: Theme.inkFaint
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Rectangle {
            anchors.centerIn: parent
            visible: row.selected
            width: 8; height: 8
            radius: 1
            color: Theme.ink
        }
    }

    AppIcon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: marker.right
        anchors.leftMargin: 4
        width: 28; height: 28
        source: row.icon
        name: row.name
        active: row.selected
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: 16
        anchors.right: verb.left
        anchors.rightMargin: 12
        spacing: 2

        Text {
            width: parent.width
            text: row.name
            color: row.selected ? Theme.ink : Qt.rgba(0.92, 0.92, 0.92, 0.86)
            font.family: Theme.sans
            font.weight: row.selected ? Font.Medium : Font.Normal
            font.pixelSize: 15
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: row.generic.length > 0
            text: row.generic
            color: Theme.inkDim
            font.family: Theme.sans
            font.weight: Font.Light
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Row {
        id: verb
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 14
        spacing: 8
        opacity: row.selected ? 1 : 0
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "open"
            color: Theme.inkDim
            font.family: Theme.serif
            font.weight: Font.Light
            font.pixelSize: 12
            font.letterSpacing: 2
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "↵"
            color: Theme.inkDim
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // only follow real pointer motion, so rows scrolling under a still
        // cursor during keyboard navigation don't steal the selection
        onPositionChanged: m => {
            const g = area.mapToItem(null, m.x, m.y);
            row.hovered(g.x, g.y);
        }
        onClicked: row.clicked()
    }
}
