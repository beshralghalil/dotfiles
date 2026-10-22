import QtQuick
import "../common"

// Vertical hairline separator.
Item {
    implicitWidth: 9
    implicitHeight: 14
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: parent.height
        color: Theme.hairline
    }
}
