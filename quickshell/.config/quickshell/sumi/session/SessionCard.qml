import QtQuick
import "../common"

// Session / power menu, 墨 style: a row of monochrome tiles.
//   [lock] [reboot] [shutdown] [logout] [suspend] [hibernate]
// Plain QtQuick so it can be previewed off-screen. Session.qml handles keys
// and runs the actions.
Item {
    id: card

    property int current: 0
    signal chosen(int index)

    // icon, label, key — actions live in Session.qml (same order)
    readonly property var entries: [
        ["\u{F033E}", "Lock", "L"],        // lock
        ["\u{F0709}", "Reboot", "R"],      // restart
        ["\u{F0425}", "Shutdown", "S"],    // power
        ["\u{F0343}", "Logout", "E"],      // logout
        ["\u{F04B2}", "Suspend", "U"],     // sleep
        ["\u{F0717}", "Hibernate", "H"]    // snowflake
    ]

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        spacing: 22

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SESSION"
            color: Theme.inkDim
            font.family: Theme.mono
            font.weight: Font.Light
            font.styleName: "Light"
            font.pixelSize: 13
            font.letterSpacing: 6
        }

        Row {
            spacing: 14
            Repeater {
                model: card.entries
                Rectangle {
                    id: tile
                    required property int index
                    required property var modelData
                    readonly property bool active: card.current === index
                    width: 132; height: 150
                    radius: Theme.radius + 2
                    color: active ? Theme.ink : Theme.card
                    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 14
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData[0]
                            color: tile.active ? Theme.paper : Theme.ink
                            font.family: Theme.icon
                            font.pixelSize: 44
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData[1]
                            color: tile.active ? Theme.paper : Theme.ink
                            font.family: Theme.mono
                            font.weight: Font.Light
                            font.styleName: "Light"
                            font.pixelSize: 15
                            font.letterSpacing: 1
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData[2]
                            color: tile.active ? Theme.paper : Theme.inkDim
                            opacity: 0.8
                            font.family: Theme.mono
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: card.current = tile.index
                        onClicked: card.chosen(tile.index)
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "←→ select   ↵ confirm   esc cancel"
            color: Theme.inkFaint
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 1
        }
    }
}
