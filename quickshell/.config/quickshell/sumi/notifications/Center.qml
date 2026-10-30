import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../services"

// Notification center (replaces swaync's panel): history, do-not-disturb, clear all.
//   qs -p ~/.config/quickshell/sumi ipc call notifications toggle
// Esc or a click outside closes it.
Scope {
    id: root

    property bool open: false
    function show() { root.open = true }
    function hide() { root.open = false }
    function toggle() { root.open = !root.open }

    PanelWindow {
        id: win
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "sumi-notification-center"
        anchors.top: true   // top-centre, like the old swaync control centre
        margins.top: 5
        implicitWidth: 450
        implicitHeight: Math.min(panel.implicitHeight, 720, (screen ? screen.height : 1080) - 80)

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: root.hide()
        }

        Rectangle {
            id: panel
            anchors.fill: parent
            implicitHeight: header.height + 1 + Math.max(empty.implicitHeight, list.contentHeight) + 40
            radius: Theme.radius + 2
            color: Theme.paper
            border.width: 1
            border.color: Theme.hairline
            focus: true
            Keys.onEscapePressed: root.hide()

            Item {
                id: header
                x: 16; y: 14
                width: parent.width - 32
                height: 30

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        id: title
                        text: "通知"
                        color: Theme.ink
                        font.family: Theme.serif
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.baseline: title.baseline
                        text: Notifs.count > 0 ? "NOTIFICATIONS · " + Notifs.count : "NOTIFICATIONS"
                        color: Theme.inkDim
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    HeaderButton { // do not disturb
                        glyph: Notifs.dnd ? "\u{F009B}" : "\u{F009A}"   // bell-off / bell
                        active: Notifs.dnd
                        onClicked: Notifs.toggleDnd()
                    }
                    HeaderButton { // clear all
                        glyph: "\u{F0A7A}"                               // trash-can-outline
                        enabled: Notifs.count > 0
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Rectangle {
                id: rule
                anchors.top: header.bottom
                anchors.topMargin: 10
                x: 16
                width: parent.width - 32
                height: 1
                color: Theme.hairline
            }

            Text {
                id: empty
                visible: Notifs.count === 0
                anchors.top: rule.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                bottomPadding: 10
                text: Notifs.dnd ? "静 — do not disturb" : "静 — nothing new"
                color: Theme.inkDim
                font.family: Theme.serif
                font.pixelSize: 13
            }

            ListView {
                id: list
                anchors.top: rule.bottom
                anchors.topMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                x: 12
                width: parent.width - 24
                clip: true
                spacing: 8
                model: Notifs.history
                boundsBehavior: Flickable.StopAtBounds
                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view ? ListView.view.width : 426
                    notif: modelData
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: hb
        property string glyph
        property bool active: false
        signal clicked()
        width: 30; height: 30
        radius: Theme.radius
        opacity: enabled ? 1 : 0.35
        color: hbArea.containsMouse || hb.active ? Theme.hover : "transparent"
        Text {
            anchors.centerIn: parent
            text: hb.glyph
            color: Theme.ink
            font.family: Theme.icon
            font.pixelSize: 16
        }
        MouseArea {
            id: hbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hb.clicked()
        }
    }
}
