import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common"
import "../services"

// Notification toasts: top-centre of the focused monitor (like the old swaync), under the bar (exclusive zone 0
// respects the bar's), newest on top. Hidden while the notification center is open.
// Notifs.popups is replaced as a whole array; a local ListModel is reconciled by id so
// each card animates in and out on its own (approach from Ryoku's NotificationPopups).
PanelWindow {
    id: win

    property bool suppressed: false   // the center is open
    readonly property var popups: Notifs.popups

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: cards.count > 0 && !win.suppressed
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "sumi-notifications"
    anchors.top: true
    margins.top: 10
    implicitWidth: 380
    implicitHeight: Math.max(1, list.contentHeight)

    ListModel { id: cards }

    function indexOfId(id) {
        for (let i = 0; i < cards.count; i++)
            if (cards.get(i).nid === id) return i;
        return -1;
    }
    function sync() {
        const incoming = win.popups;
        for (let i = cards.count - 1; i >= 0; i--)
            if (!incoming.some(p => p.id === cards.get(i).nid)) cards.remove(i);
        for (let j = 0; j < incoming.length; j++) {
            const cur = win.indexOfId(incoming[j].id);
            if (cur < 0) cards.insert(j, { nid: incoming[j].id, entry: incoming[j] });
            else if (cur !== j) cards.move(cur, j, 1);
        }
    }
    onPopupsChanged: sync()
    Component.onCompleted: sync()

    ListView {
        id: list
        anchors.fill: parent
        spacing: 10
        interactive: false
        model: cards

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.ms(180); easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: Theme.ms(220); easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.ms(160); easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; to: 0.95; duration: Theme.ms(160); easing.type: Easing.InCubic }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.ms(200); easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; to: 1; duration: Theme.ms(120) }
            NumberAnimation { property: "scale"; to: 1; duration: Theme.ms(120) }
        }

        delegate: NotificationCard {
            required property var entry
            width: ListView.view ? ListView.view.width : 380
            notif: entry
            popup: true
        }
    }
}
