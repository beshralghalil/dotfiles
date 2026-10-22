import QtQuick
import "../common"
import "../launcher" as L

// One grid tile (thumbnail mode, e.g. the wallpaper menu): the image in full
// colour (it is content), the name under it, a hairline frame that turns to
// ink with a hanko square when selected. Theme icons are pressed into ink.
Item {
    id: tile

    property string text: ""
    property url icon
    property int iconKind: 0
    property bool selected: false
    property bool marked: false
    property bool selectable: true

    signal hovered(real sceneX, real sceneY)
    signal clicked()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: tile.selected ? Theme.hover : area.containsMouse ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
    }

    Rectangle {
        id: frame
        x: 6; y: 6
        width: parent.width - 12
        height: parent.height - 12 - 22
        color: Qt.rgba(1, 1, 1, 0.03)
        border.color: tile.selected ? Theme.ink : Theme.hairline
        border.width: 1
        radius: 2
        clip: true

        Image {
            id: img
            anchors.fill: parent
            anchors.margins: 1
            visible: tile.iconKind === 2
            source: tile.iconKind === 2 ? tile.icon : ""
            sourceSize.width: Math.round(width * 1.5)
            sourceSize.height: Math.round(height * 1.5)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            opacity: tile.selected ? 1 : 0.78
            Behavior on opacity { NumberAnimation { duration: 90 } }
        }
        L.AppIcon {
            anchors.centerIn: parent
            width: 40; height: 40
            visible: tile.iconKind === 1
            source: tile.iconKind === 1 ? tile.icon : ""
            name: tile.text
            active: tile.selected
        }
        Text {
            anchors.centerIn: parent
            visible: tile.iconKind === 0 || (tile.iconKind === 2 && img.status === Image.Error)
            text: tile.text.length ? tile.text.charAt(0).toUpperCase() : "?"
            color: Theme.inkDim
            font.family: Theme.mono
            font.styleName: "Thin"
            font.pixelSize: 30
        }
        // hanko square in the corner of the selected tile
        Rectangle {
            visible: tile.selected || tile.marked
            x: 8; y: 8
            width: 9; height: 9
            radius: 1
            color: tile.selected ? Theme.ink : "transparent"
            border.color: Theme.ink
            border.width: 1
        }
    }

    Text {
        anchors.top: frame.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        text: tile.text
        textFormat: Text.PlainText
        color: tile.selected ? Theme.ink : Theme.inkDim
        font.family: Theme.sans
        font.weight: tile.selected ? Font.Medium : Font.Light
        font.pixelSize: 11
        elide: Text.ElideMiddle
        maximumLineCount: 1
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: m => {
            const g = area.mapToItem(null, m.x, m.y);
            tile.hovered(g.x, g.y);
        }
        onClicked: tile.clicked()
    }
}
