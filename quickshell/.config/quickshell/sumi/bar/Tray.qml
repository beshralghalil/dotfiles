import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// System tray (StatusNotifierItem). Left click activates (or opens the menu for
// menu-only items), right click opens the item's menu, middle click is the
// secondary action, wheel scrolls. Menus are the platform (Qt) menus shown via
// SystemTrayItem.display(); passive items are hidden.
Row {
    id: tray

    required property var window      // the PanelWindow hosting the bar
    property bool monochrome: true

    spacing: 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // some apps (Electron, Steam…) send "name?path=/dir": resolve to a file
    function iconSource(icon) {
        if (!icon) return "";
        const i = icon.indexOf("?path=");
        if (i < 0) return icon;
        const name = icon.slice(0, i), dir = icon.slice(i + 6);
        return "file://" + dir + "/" + name.slice(name.lastIndexOf("/") + 1);
    }

    Repeater {
        model: SystemTray.items
        delegate: TrayIcon {
            id: cell
            required property var modelData
            visible: modelData.status !== Status.Passive
            width: visible ? implicitWidth : 0
            source: tray.iconSource(modelData.icon)
            monochrome: tray.monochrome

            function openMenu(x, y) {
                const p = cell.mapToItem(null, x, y);
                modelData.display(tray.window, Math.round(p.x), Math.round(p.y));
            }
            onClicked: (button, x, y) => {
                if (button === Qt.LeftButton) {
                    if (modelData.onlyMenu && modelData.hasMenu) openMenu(x, y);
                    else modelData.activate();
                } else if (button === Qt.RightButton) {
                    if (modelData.hasMenu) openMenu(x, y);
                    else modelData.secondaryActivate();
                } else {
                    modelData.secondaryActivate();
                }
            }
            onScrolled: (delta, horizontal) => modelData.scroll(delta, horizontal)
        }
    }
}
