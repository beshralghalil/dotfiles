import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"

// Session / power menu (replaces wlogout). Opened with
//   qs -p ~/.config/quickshell/sumi ipc call session toggle
// Keys: L lock, R reboot, S shutdown, E logout, U suspend, H hibernate,
// arrows + Enter, Esc closes. Actions match the old ~/.config/wlogout/layout.
Scope {
    id: root

    property bool open: false
    readonly property string home: Quickshell.env("HOME")
    readonly property var actions: [
        root.home + "/.config/hypr/scripts/LockScreen.sh",
        "systemctl reboot",
        "systemctl poweroff",
        "hyprctl dispatch 'hl.dsp.exit()'",
        "systemctl suspend",
        "systemctl hibernate"
    ]
    readonly property string keys: "lrseuh"

    function show() { card.current = 0; root.open = true; Qt.callLater(() => card.forceActiveFocus()); }
    function hide() { root.open = false; }
    function toggle() { root.open ? hide() : show(); }
    function run(i) {
        root.open = false;
        // let the overlay unmap first (lock/suspend should not capture it)
        Qt.callLater(() => Quickshell.execDetached(["sh", "-c", "sleep 0.15; " + root.actions[i]]));
    }

    PanelWindow {
        id: win
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "sumi-session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Rectangle { // dim backdrop; click outside the tiles closes
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.62)
            MouseArea { anchors.fill: parent; onClicked: root.hide() }
        }

        SessionCard {
            id: card
            anchors.centerIn: parent
            onChosen: i => root.run(i)
            focus: true
            Keys.onPressed: e => {
                const n = card.entries.length;
                if (e.key === Qt.Key_Escape) root.hide();
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_H && (e.modifiers & Qt.ControlModifier)) card.current = (card.current + n - 1) % n;
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) card.current = (card.current + 1) % n;
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.run(card.current);
                else {
                    const i = root.keys.indexOf(e.text.toLowerCase());
                    if (i >= 0 && e.text !== "") root.run(i);
                    else return;
                }
                e.accepted = true;
            }
        }
    }
}
