import QtQuick
import "../common"
import "../services"

// Right-click menu for a desktop widget: position lock/reset, the widget's own
// options, and on/off switches for every widget. Black card, hairline rules.
Rectangle {
    id: menu

    property string target: "clock"
    signal close()

    readonly property var labels: ({ clock: "Clock", calendar: "Calendar", music: "Music",
                                     weather: "Weather", stats: "System stats" })

    width: 260
    height: col.implicitHeight + 16
    radius: Theme.radius + 2
    color: Theme.card
    border.color: Theme.hairline
    border.width: 1

    // swallow clicks on the card background so they don't close the menu
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Column {
        id: col
        x: 8; y: 8
        width: parent.width - 16

        Text {
            leftPadding: 10; topPadding: 4; bottomPadding: 8
            text: "SETTINGS — " + (menu.labels[menu.target] || menu.target).toUpperCase()
            color: Theme.inkDim
            font.family: Theme.serif
            font.weight: Font.Light
            font.pixelSize: 13
            font.letterSpacing: 2
        }

        Entry {
            text: Config.data[menu.target + "Locked"] ? "Unlock position" : "Lock position"
            onActivated: Config.toggle(menu.target + "Locked")
        }
        Entry {
            text: "Reset position"
            onActivated: Config.resetPosition(menu.target)
        }

        // widget-specific options
        Entry {
            visible: menu.target === "clock"
            text: "24-hour time"
            checkable: true
            checked: Config.data.clock24h
            onActivated: Config.toggle("clock24h")
        }
        Entry {
            visible: menu.target === "clock"
            text: "Minute line"
            checkable: true
            checked: Config.data.clockMinuteLine
            onActivated: Config.toggle("clockMinuteLine")
        }
        Entry {
            visible: menu.target === "weather"
            text: "Fahrenheit"
            checkable: true
            checked: Config.data.weatherFahrenheit
            onActivated: Config.toggle("weatherFahrenheit")
        }

        Rule {}
        Text {
            leftPadding: 10; topPadding: 6; bottomPadding: 4
            text: "SHOW WIDGETS"
            color: Theme.inkDim
            font.family: Theme.mono
            font.weight: Font.Light
            font.pixelSize: 11
            font.letterSpacing: 3
        }
        Repeater {
            model: Config.widgetNames
            Entry {
                required property string modelData
                text: menu.labels[modelData]
                checkable: true
                checked: Config.data[modelData + "Enabled"]
                onActivated: Config.toggle(modelData + "Enabled")
            }
        }
    }

    component Rule: Item {
        width: parent ? parent.width : 0
        height: 9
        Rectangle { anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.hairline }
    }

    component Entry: Rectangle {
        id: entry
        property string text
        property bool checkable: false
        property bool checked: false
        signal activated()

        width: parent ? parent.width : 0
        height: visible ? 32 : 0
        radius: Theme.radius
        color: area.containsMouse ? Theme.hover : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            text: entry.text
            color: Theme.ink
            font.family: Theme.sans
            font.weight: Font.Normal
            font.pixelSize: 14
        }
        // square check mark, filled when on
        Rectangle {
            visible: entry.checkable
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            width: 12; height: 12
            radius: 2
            color: entry.checked ? Theme.ink : "transparent"
            border.color: entry.checked ? Theme.ink : Theme.inkDim
            border.width: 1
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                entry.activated();
                if (!entry.checkable) menu.close();
            }
        }
    }
}
