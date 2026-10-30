import QtQuick
import "../common"

// Workspace strip. Model: [{ id, name, active, occupied, urgent }].
//   active   -> ink-filled seal, paper glyph
//   occupied -> ink glyph
//   empty    -> faint glyph (persistent slots)
//   urgent   -> outlined square
// Numerals: "kanji" (一 二 三 …) or "mono" (thin 1 2 3 …). Named workspaces show
// their name's first character.
Item {
    id: ws

    property var model: []
    property string numerals: "kanji"
    property int cell: 24

    signal activate(int id)
    signal step(int dir)     // +1 next, -1 previous

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 28
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    function glyph(w) {
        if (w.name && w.name !== "" + w.id && isNaN(Number(w.name)))
            return w.name.charAt(0);
        return ws.numerals === "kanji" ? Theme.kanjiNum(w.id) : "" + w.id;
    }

    property real _acc: 0
    MouseArea { // wheel anywhere on the strip; clicks go to the cells
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: e => {
            ws._acc += e.angleDelta.y !== 0 ? e.angleDelta.y : -e.angleDelta.x;
            while (Math.abs(ws._acc) >= 120) {
                const s = ws._acc > 0 ? 1 : -1;
                ws._acc -= s * 120;
                ws.step(-s);      // wheel down -> next, like waybar's e+1
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: ws.model
            delegate: Item {
                id: cellItem
                required property var modelData
                readonly property bool kanji: ws.numerals === "kanji" || isNaN(Number(text_.text))
                width: Math.max(ws.cell, text_.implicitWidth + 8)
                height: ws.cell

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: cellItem.modelData.active ? Theme.ink
                         : hover.containsMouse ? Theme.hover : "transparent"
                    border.width: cellItem.modelData.urgent && !cellItem.modelData.active ? 1 : 0
                    border.color: Theme.ink
                    Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
                }
                Text {
                    id: text_
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: cellItem.kanji ? -1 : 0
                    text: ws.glyph(cellItem.modelData)
                    color: cellItem.modelData.active ? Theme.paper
                         : cellItem.modelData.occupied || cellItem.modelData.urgent ? Theme.ink : Theme.inkFaint
                    font.family: cellItem.kanji ? Theme.serif : Theme.mono
                    font.weight: cellItem.kanji ? (cellItem.modelData.active ? Font.Black : Font.Normal) : Font.Light
                    font.styleName: cellItem.kanji ? "" : (cellItem.modelData.active ? "Regular" : "Light")
                    font.pixelSize: cellItem.kanji ? 14 : 14
                    Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ws.activate(cellItem.modelData.id)
                }
            }
        }
    }
}
