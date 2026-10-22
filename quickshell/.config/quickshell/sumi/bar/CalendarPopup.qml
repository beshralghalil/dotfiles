import QtQuick
import "../common"
import "../desktop/widgets"

// Calendar card shown under the bar clock: month navigation + the desktop
// CalendarWidget. Plain QtQuick (previewable).
Rectangle {
    id: pop

    property date today: new Date()
    property int offset: 0   // months away from today's month
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)

    implicitWidth: col.implicitWidth + 36
    implicitHeight: col.implicitHeight + 32
    radius: Theme.radius + 2
    color: Theme.card

    // swallow clicks on the card background
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Column {
        id: col
        x: 18; y: 16
        spacing: 12

        CalendarWidget {
            id: cal
            shown: pop.shown
            today: pop.today
            scale_: 0.9
        }

        // navigation
        Item {
            width: cal.width
            height: 26
            NavButton { anchors.left: parent.left; glyph: "\u{F0141}"; onClicked: pop.offset -= 1 }   // chevron-left
            Text {
                anchors.centerIn: parent
                visible: pop.offset !== 0
                text: "today"
                color: todayArea.containsMouse ? Theme.ink : Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.styleName: "Light"
                font.pixelSize: 12
                font.letterSpacing: 2
                MouseArea {
                    id: todayArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pop.offset = 0
                }
            }
            NavButton { anchors.right: parent.right; glyph: "\u{F0142}"; onClicked: pop.offset += 1 } // chevron-right
        }
    }

    // scroll over the card to change month
    WheelHandler {
        onWheel: e => pop.offset += (e.angleDelta.y > 0 ? -1 : 1)
    }

    component NavButton: Rectangle {
        id: nb
        property string glyph
        signal clicked()
        width: 26; height: 26
        radius: Theme.radius
        color: nbArea.containsMouse ? Theme.hover : "transparent"
        Text {
            anchors.centerIn: parent
            text: nb.glyph
            color: Theme.ink
            font.family: Theme.icon
            font.pixelSize: 16
        }
        MouseArea {
            id: nbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nb.clicked()
        }
    }
}
