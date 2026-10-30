import QtQuick
import "../common"

// One interactive cell of the bar: a Row of content with padding, a quiet hover
// wash, and click / scroll signals. Wheel deltas are accumulated so a touchpad
// emits one `scrolled` per notch-equivalent (120 units).
// Plain QtQuick (no Quickshell types) so it can be previewed off-screen.
Item {
    id: chip

    default property alias content: row.data
    property int padding: 7
    property alias spacing: row.spacing
    property bool interactive: true
    readonly property bool hovered: mouse.containsMouse

    signal clicked(int button)   // Qt.LeftButton / Qt.RightButton / Qt.MiddleButton
    signal scrolled(int step)    // +1 = up / away, -1 = down / towards

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.hover
        opacity: chip.interactive && mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(140) } }
    }

    Row {
        id: row
        x: chip.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }

    property real _acc: 0
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: chip.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => chip.clicked(e.button)
        onWheel: e => {
            chip._acc += e.angleDelta.y !== 0 ? e.angleDelta.y : -e.angleDelta.x;
            while (Math.abs(chip._acc) >= 120) {
                const s = chip._acc > 0 ? 1 : -1;
                chip._acc -= s * 120;
                chip.scrolled(s);
            }
        }
    }
}
