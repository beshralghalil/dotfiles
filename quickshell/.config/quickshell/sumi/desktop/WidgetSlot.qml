import QtQuick
import QtQuick.Effects
import "../services"

// Holds one desktop widget: places it at <name>X/<name>Y from Config, drags it
// with the left button (saved on release, kept on-screen) unless <name>Locked,
// and asks the desktop for the right-click menu. Children of the slot's content
// (e.g. music buttons) sit above the drag area, so their clicks still work.
// Idea from Ryoku's WidgetSlot (github.com/ryoku-dev/ryoku, GPL-3.0).
//
// The slot includes a `pad` margin around the widget so it can be grabbed by its
// edge, and the slot itself is the input region for the desktop's mask: the mask
// follows the slot's own x/y, so it moves with the widget after a drag.
Item {
    id: slot

    required property string name
    property real areaWidth: parent ? parent.width : 1920
    property real areaHeight: parent ? parent.height : 1080
    default property alias content: holder.data
    readonly property bool locked: Config.data[name + "Locked"]
    property bool dragging: false
    readonly property int pad: 10
    // input area for the desktop's click-through mask
    readonly property Item hitbox: slot

    signal menuRequested(string name, real x, real y)

    // config X/Y is where the widget itself sits; the slot starts `pad` earlier
    x: Math.max(0, Math.min(areaWidth - holder.width, Config.data[name + "X"])) - pad
    y: Math.max(0, Math.min(areaHeight - holder.height, Config.data[name + "Y"])) - pad
    width: holder.width + 2 * pad
    height: holder.height + 2 * pad

    // subtle frame while dragging / hovering an unlocked widget
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, slot.dragging ? 0.28 : 0.10)
        visible: slot.dragging || (drag.containsMouse && !slot.locked)
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: slot.dragging ? Qt.ClosedHandCursor : (slot.locked ? Qt.ArrowCursor : Qt.OpenHandCursor)

        // pointer position (window coordinates) and widget position at press;
        // the drag moves the widget by the pointer's total delta since then
        property point pressAt
        property real startX: 0
        property real startY: 0

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                const p = drag.mapToItem(null, mouse.x, mouse.y);
                slot.menuRequested(slot.name, p.x, p.y);
                return;
            }
            if (slot.locked) return;
            pressAt = drag.mapToItem(null, mouse.x, mouse.y);
            startX = slot.x + slot.pad;
            startY = slot.y + slot.pad;
            slot.dragging = true;
        }
        onPositionChanged: mouse => {
            if (!slot.dragging) return;
            const p = drag.mapToItem(null, mouse.x, mouse.y);
            const nx = Math.round(Math.max(0, Math.min(slot.areaWidth - holder.width, startX + p.x - pressAt.x)));
            const ny = Math.round(Math.max(0, Math.min(slot.areaHeight - holder.height, startY + p.y - pressAt.y)));
            Config.setLive(slot.name + "X", nx);
            Config.setLive(slot.name + "Y", ny);
        }
        onReleased: mouse => {
            if (!slot.dragging) return;
            slot.dragging = false;
            Config.setMany({ [slot.name + "X"]: Config.data[slot.name + "X"],
                             [slot.name + "Y"]: Config.data[slot.name + "Y"] });
        }
        onCanceled: slot.dragging = false
    }

    Item {
        id: holder
        x: slot.pad
        y: slot.pad
        // needs a real size: a layer on a 0x0 item renders nothing
        width: childrenRect.width
        height: childrenRect.height
        // soft dark halo so ink stays legible over busy parts of the wallpaper
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.95
            shadowBlur: 0.8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 32
        }
    }
}
