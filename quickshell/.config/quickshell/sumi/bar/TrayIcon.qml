import QtQuick
import QtQuick.Effects
import "../common"

// One tray icon cell, plain QtQuick. Icons are drawn desaturated (monochrome)
// by default to keep the bar black-and-white; hover restores some contrast.
Item {
    id: cell

    property string source: ""
    property bool monochrome: true
    // MultiEffect needs a GPU scene graph; under the software renderer
    // (e.g. off-screen previews) fall back to the colour icon
    readonly property bool _fx: monochrome && GraphicsInfo.api !== GraphicsInfo.Software
    property int iconSize: 16

    signal clicked(int button, real x, real y)  // x/y: bottom-left of the cell, in cell coords
    signal scrolled(int delta, bool horizontal)

    implicitWidth: 24
    implicitHeight: 24
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.hover
        opacity: mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(140) } }
    }

    Image {
        id: img
        anchors.centerIn: parent
        width: cell.iconSize
        height: cell.iconSize
        sourceSize: Qt.size(cell.iconSize * 2, cell.iconSize * 2)
        source: cell.source
        smooth: true
        asynchronous: true
        visible: !cell._fx
    }
    MultiEffect {
        visible: cell._fx
        anchors.fill: img
        source: img
        saturation: -1.0
        brightness: mouse.containsMouse ? 0.1 : 0.0
        opacity: mouse.containsMouse ? 1.0 : 0.82
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => cell.clicked(e.button, 0, cell.height)
        onWheel: e => {
            const horizontal = e.angleDelta.y === 0;
            cell.scrolled(horizontal ? e.angleDelta.x : e.angleDelta.y, horizontal);
        }
    }
}
