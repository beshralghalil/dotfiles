import QtQuick
import "../common"
import "../launcher" as L

// One picker row (list mode), the launcher row idiom without the app verb:
//   [01 | ■]  [icon]  text                                      ↵
// `iconKind`: 0 none, 1 theme / app icon (pressed into ink by AppIcon),
// 2 image file (thumbnail, cliphist image ...: content, kept in colour).
// `showIcon` reserves the icon column so rows with and without icons align.
// Plain QtQuick so it renders in off-screen previews.
Item {
    id: row

    property int ordinal: 0
    property string text: ""
    property string sub: ""
    property url icon
    property int iconKind: 0
    property bool showIcon: false
    property bool selected: false
    property bool marked: false
    property bool selectable: true
    property bool urgent: false
    property bool active: false

    signal hovered(real sceneX, real sceneY)
    signal clicked()

    height: 44

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: row.selected ? Theme.hover : area.containsMouse && row.selectable ? Qt.rgba(1, 1, 1, 0.035) : "transparent"
    }

    // index / selection marker (a hollow square marks multi-select picks)
    Item {
        id: marker
        width: 34
        height: parent.height
        Text {
            anchors.centerIn: parent
            visible: !row.selected && !row.marked
            text: row.selectable ? Theme.pad2((row.ordinal + 1) % 100) : "·"
            color: Theme.inkFaint
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Rectangle {
            anchors.centerIn: parent
            visible: row.selected || row.marked
            width: 8; height: 8
            radius: 1
            color: row.selected ? Theme.ink : "transparent"
            border.color: Theme.ink
            border.width: 1
        }
    }

    Item {
        id: iconBox
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: marker.right
        anchors.leftMargin: row.showIcon ? 4 : -6
        width: row.showIcon ? 44 : 0
        height: row.showIcon ? 30 : 0
        visible: row.showIcon && row.iconKind > 0

        L.AppIcon {
            anchors.centerIn: parent
            width: 26; height: 26
            visible: row.iconKind === 1
            source: row.iconKind === 1 ? row.icon : ""
            name: row.text
            active: row.selected
        }
        Image {
            anchors.fill: parent
            visible: row.iconKind === 2
            source: row.iconKind === 2 ? row.icon : ""
            sourceSize.width: 96
            sourceSize.height: 64
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            opacity: row.selected ? 1 : 0.82
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: iconBox.right
        anchors.leftMargin: row.showIcon ? 14 : 10
        anchors.right: verb.left
        anchors.rightMargin: 12
        spacing: 2

        Text {
            width: parent.width
            text: row.text.length ? row.text : " "
            textFormat: Text.PlainText
            color: !row.selectable ? Theme.inkDim
                : row.selected ? Theme.ink : Qt.rgba(0.92, 0.92, 0.92, 0.86)
            font.family: Theme.sans
            font.weight: row.selected || row.urgent ? Font.Medium : Font.Normal
            font.italic: row.active && !row.selected
            font.underline: row.urgent
            font.pixelSize: 14
            elide: Text.ElideRight
            maximumLineCount: 1
        }
        Text {
            width: parent.width
            visible: row.sub.length > 0
            text: row.sub
            textFormat: Text.PlainText
            color: Theme.inkDim
            font.family: Theme.sans
            font.weight: Font.Light
            font.pixelSize: 11
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Text {
        id: verb
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 14
        opacity: row.selected && row.selectable ? 1 : 0
        text: "↵"
        color: Theme.inkDim
        font.family: Theme.mono
        font.styleName: "Light"
        font.pixelSize: 12
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.selectable ? Qt.PointingHandCursor : Qt.ArrowCursor
        // only real pointer motion moves the selection (not rows scrolling
        // under a still cursor during keyboard navigation)
        onPositionChanged: m => {
            const g = area.mapToItem(null, m.x, m.y);
            row.hovered(g.x, g.y);
        }
        onClicked: row.clicked()
    }
}
