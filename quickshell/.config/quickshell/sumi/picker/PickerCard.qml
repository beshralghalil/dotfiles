import QtQuick
import "../common"
import "match.js" as Match

// 墨 picker card: the launcher card idiom for rofi -dmenu style menus.
//
//   選  SELECT                                               12 / 143
//   Prompt ▏ filter text▏
//   ─────────────────────────────────────────────────────────────────
//   message (the -mesg text, plain)
//   ─────────────────────────────────────────────────────────────────
//   ■  [icon]  row                                                  ↵
//   02 [icon]  row
//   ─────────────────────────────────────────────────────────────────
//   ↑↓ move   ↵ choose   esc close                                  墨
//
// Three layouts: list (default), grid (thumbnail tiles, when most rows carry
// image icons) and input-only (no rows: -lines 0 / empty stdin).
// Plain QtQuick, fed by `entries` (all rows) and `shown` (indices into
// entries, in display order), so it renders in off-screen previews; Picker.qml
// owns the filtering, the request and the result.
Rectangle {
    id: card

    // { text, sub, icon, iconKind, selectable, urgent, active }
    property var entries: []
    property var shown: []
    property int totalCount: entries.length
    property bool grid: false
    property bool inputOnly: false
    property bool showIcons: false
    property string eyebrow: "SELECT"
    property string prompt: ""
    property string message: ""
    property string placeholder: ""
    property bool password: false
    property bool allowCustom: true
    property bool multiSelect: false
    property var marked: ({})
    // [{ n, label, keys: [{ mods, key }] }] (rofi -kb-custom-N)
    property var customKeys: []
    property int maxVisible: 8
    property int columns: 5
    property int selectedIndex: 0

    property alias text: field.text
    readonly property alias input: field

    signal picked(int pos)            // pos into `shown`
    signal customPicked(string text)
    signal customKey(int n, int pos)  // pos may be -1 (nothing selected)
    signal markToggled(int pos)
    signal dismissed()

    function focusSearch() { field.forceActiveFocus(); }
    function reset(initialText, initialIndex) {
        field.text = initialText || "";
        // the pointer may rest over the card when it maps: its first report
        // only arms hover selection, so it can't steal -selected-row
        list.lastPointer = Qt.point(-1, -1);
        gridView.lastPointer = Qt.point(-1, -1);
        card.selectedIndex = Math.max(0, initialIndex || 0);
        card.fixSelection(1);
        Qt.callLater(card.reveal);
    }
    function entryAt(pos) {
        return pos >= 0 && pos < card.shown.length ? card.entries[card.shown[pos]] : null;
    }
    function selectable(pos) {
        const e = card.entryAt(pos);
        return !!e && e.selectable !== false;
    }
    // keep the selection on a selectable row, searching in `dir` first
    function fixSelection(dir) {
        const n = card.shown.length;
        if (n === 0) { card.selectedIndex = 0; return; }
        let i = Math.max(0, Math.min(n - 1, card.selectedIndex));
        for (let k = 0; k < n; k++) {
            const j = i + (k * dir);
            if (j >= 0 && j < n && card.selectable(j)) { card.selectedIndex = j; return; }
        }
        for (let k = 0; k < n; k++) {
            const j = i - (k * dir);
            if (j >= 0 && j < n && card.selectable(j)) { card.selectedIndex = j; return; }
        }
        card.selectedIndex = i;
    }
    function move(delta) {
        const n = card.shown.length;
        if (card.inputOnly || n === 0)
            return;
        let j = card.selectedIndex + delta;
        if (Math.abs(delta) === 1 && !card.grid) {
            // wrap like rofi's cycle
            if (j < 0) j = n - 1;
            else if (j >= n) j = 0;
        }
        j = Math.max(0, Math.min(n - 1, j));
        const dir = delta >= 0 ? 1 : -1;
        while (j >= 0 && j < n && !card.selectable(j))
            j += dir;
        if (j >= 0 && j < n)
            card.selectedIndex = j;
    }
    function reveal() {
        if (card.grid) gridView.positionViewAtIndex(card.selectedIndex, GridView.Contain);
        else list.positionViewAtIndex(card.selectedIndex, ListView.Contain);
    }
    function accept() {
        if (card.inputOnly || card.shown.length === 0) {
            if (card.allowCustom || card.inputOnly)
                card.customPicked(field.text);
            return;
        }
        if (card.selectable(card.selectedIndex))
            card.picked(card.selectedIndex);
    }

    onSelectedIndexChanged: reveal()
    onShownChanged: {
        if (card.selectedIndex >= card.shown.length)
            card.selectedIndex = Math.max(0, card.shown.length - 1);
        card.fixSelection(1);
    }

    readonly property int pad: 22
    readonly property int rowH: !card.showIcons ? 42 : 50
    readonly property int cellW: Math.floor((card.width - card.pad * 2 - 8) / card.columns)
    readonly property int cellH: Math.round((cellW - 12) * 0.6) + 12 + 22
    readonly property int gridRows: Math.min(3, Math.ceil(card.shown.length / card.columns))
    readonly property int listH: card.inputOnly ? 0
        : card.shown.length === 0 ? 96
        : card.grid ? card.gridRows * card.cellH
        : Math.min(card.shown.length, card.maxVisible) * card.rowH

    width: card.grid ? 980 : 680
    implicitHeight: body.implicitHeight + card.pad * 2
    height: implicitHeight
    radius: Theme.radius + 2
    color: Theme.card
    border.color: Theme.hairline
    border.width: 1
    clip: true

    Behavior on height { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }

    // swallow clicks on the card so they don't reach the click-out scrim
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Column {
        id: body
        x: card.pad
        y: card.pad
        width: card.width - card.pad * 2
        spacing: 0

        // ── eyebrow ──────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 20
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "選"
                    color: Theme.inkFaint
                    font.family: Theme.serif
                    font.weight: Font.Black
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.eyebrow
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.styleName: "Light"
                    font.pixelSize: 10
                    font.letterSpacing: 3
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible: !card.inputOnly
                text: field.text.length ? card.shown.length + " / " + card.totalCount
                    : card.totalCount + (card.totalCount === 1 ? " ITEM" : " ITEMS")
                color: Theme.inkDim
                font.family: Theme.mono
                font.styleName: "Light"
                font.pixelSize: 10
                font.letterSpacing: 2
                font.features: { "tnum": 1 }
            }
        }

        // ── prompt + field ───────────────────────────────────────────────
        Item {
            width: parent.width
            height: 58

            Text {
                id: seal
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width * 0.32)
                text: card.prompt.length ? card.prompt : (card.inputOnly ? "Input" : "Filter")
                textFormat: Text.PlainText
                color: Theme.ink
                font.family: Theme.serif
                font.weight: Font.Medium
                font.pixelSize: 15
                font.letterSpacing: 1
                elide: Text.ElideRight
            }
            Rectangle {
                id: sealRule
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: seal.right
                anchors.leftMargin: 12
                width: 1; height: 22
                color: Theme.hairline
            }

            TextInput {
                id: field
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: sealRule.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                color: Theme.ink
                font.family: Theme.mono
                font.styleName: "Thin"
                font.pixelSize: 26
                echoMode: card.password ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                selectionColor: Theme.ink
                selectedTextColor: Theme.paper
                selectByMouse: true
                clip: true
                focus: true

                cursorDelegate: Rectangle {
                    width: 2
                    color: Theme.ink
                    visible: field.cursorVisible
                    SequentialAnimation on opacity {
                        running: field.activeFocus
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 0 }
                        PauseAnimation { duration: 520 }
                        NumberAnimation { to: 0; duration: 0 }
                        PauseAnimation { duration: 420 }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    visible: field.text.length === 0
                    text: card.placeholder.length ? card.placeholder
                        : card.inputOnly ? "type here" : "type to filter"
                    textFormat: Text.PlainText
                    color: Theme.inkFaint
                    font.family: Theme.mono
                    font.styleName: "Thin"
                    font.pixelSize: card.placeholder.length > 34 ? 18 : 26
                    elide: Text.ElideRight
                }

                onTextChanged: {
                    card.selectedIndex = 0;
                    if (card.grid) gridView.positionViewAtBeginning();
                    else list.positionViewAtBeginning();
                }

                Keys.onPressed: e => {
                    const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                    const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
                    const enter = e.key === Qt.Key_Return || e.key === Qt.Key_Enter;
                    // custom keybinds (rofi -kb-custom-N) win over the built-ins
                    for (let i = 0; i < card.customKeys.length; i++) {
                        const c = card.customKeys[i];
                        if (Match.hits(c.keys, e.key, e.modifiers)) {
                            card.customKey(c.n, card.selectable(card.selectedIndex) ? card.selectedIndex : -1);
                            e.accepted = true;
                            return;
                        }
                    }
                    if (e.key === Qt.Key_Escape) {
                        card.dismissed();
                    } else if (enter && ctrl) {
                        if (card.allowCustom) card.customPicked(field.text);
                    } else if (enter && shift) {
                        if (card.multiSelect && card.selectable(card.selectedIndex)) {
                            card.markToggled(card.selectedIndex);
                            card.move(1);
                        } else if (card.allowCustom) {
                            card.customPicked(field.text);
                        }
                    } else if (enter) {
                        card.accept();
                    } else if (card.grid && e.key === Qt.Key_Right) {
                        card.move(1);
                    } else if (card.grid && e.key === Qt.Key_Left) {
                        card.move(-1);
                    } else if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                        card.move(card.grid ? card.columns : 1);
                    } else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                        card.move(card.grid ? -card.columns : -1);
                    } else if (e.key === Qt.Key_Tab) {
                        card.move(1);
                    } else if (e.key === Qt.Key_Backtab) {
                        card.move(-1);
                    } else if (e.key === Qt.Key_PageDown) {
                        card.move(card.grid ? card.columns * card.gridRows : card.maxVisible);
                    } else if (e.key === Qt.Key_PageUp) {
                        card.move(card.grid ? -card.columns * card.gridRows : -card.maxVisible);
                    } else if (ctrl && e.key === Qt.Key_Home) {
                        card.selectedIndex = 0; card.fixSelection(1);
                    } else if (ctrl && e.key === Qt.Key_End) {
                        card.selectedIndex = Math.max(0, card.shown.length - 1); card.fixSelection(-1);
                    } else if (ctrl && e.key === Qt.Key_Space && card.multiSelect) {
                        if (card.selectable(card.selectedIndex)) card.markToggled(card.selectedIndex);
                    } else if (ctrl && e.key === Qt.Key_U) {
                        field.text = "";
                    } else {
                        return;
                    }
                    e.accepted = true;
                }
            }
        }

        Rule {}

        // ── message (-mesg) ──────────────────────────────────────────────
        Item {
            visible: card.message.length > 0
            width: parent.width
            height: visible ? msg.implicitHeight + 20 : 0
            Rectangle {
                x: 8; y: 10 + 6
                width: 5; height: 5
                radius: 1
                color: Theme.inkDim
            }
            Text {
                id: msg
                x: 24; y: 10
                width: parent.width - 30
                text: card.message
                textFormat: Text.PlainText
                color: Theme.inkDim
                font.family: Theme.sans
                font.weight: Font.Light
                font.pixelSize: 12
                lineHeight: 1.15
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
            }
        }
        Rule { visible: card.message.length > 0 && !card.inputOnly }

        // ── rows ─────────────────────────────────────────────────────────
        Item {
            visible: !card.inputOnly
            width: parent.width
            height: visible ? card.listH + 16 : 0

            ListView {
                id: list
                visible: !card.grid && card.shown.length > 0
                x: 0; y: 8
                width: parent.width - (interactive ? 8 : 0)
                height: card.listH
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: card.shown.length > card.maxVisible
                model: card.grid || card.inputOnly ? 0 : card.shown.length
                highlightMoveDuration: 0
                reuseItems: true
                cacheBuffer: 0

                property point lastPointer: Qt.point(-1, -1)

                delegate: PickerRow {
                    required property int index
                    readonly property var entry: card.entries[card.shown[index]] || ({})
                    width: list.width
                    height: card.rowH
                    ordinal: index
                    text: entry.text || ""
                    sub: entry.sub || ""
                    icon: entry.icon || ""
                    iconKind: entry.iconKind || 0
                    showIcon: card.showIcons
                    selected: index === card.selectedIndex
                    selectable: entry.selectable !== false
                    urgent: !!entry.urgent
                    active: !!entry.active
                    marked: !!card.marked[card.shown[index]]
                    onHovered: (sx, sy) => {
                        const armed = list.lastPointer.x >= 0;
                        if (sx !== list.lastPointer.x || sy !== list.lastPointer.y) {
                            list.lastPointer = Qt.point(sx, sy);
                            if (armed && selectable)
                                card.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        if (!selectable) return;
                        card.selectedIndex = index;
                        card.picked(index);
                    }
                }
            }

            GridView {
                id: gridView
                visible: card.grid && card.shown.length > 0
                x: 4; y: 8
                width: card.cellW * card.columns
                height: card.listH
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: card.shown.length > card.columns * 3
                cellWidth: card.cellW
                cellHeight: card.cellH
                model: card.grid && !card.inputOnly ? card.shown.length : 0
                highlightMoveDuration: 0
                reuseItems: true
                cacheBuffer: card.cellH

                property point lastPointer: Qt.point(-1, -1)

                delegate: PickerTile {
                    required property int index
                    readonly property var entry: card.entries[card.shown[index]] || ({})
                    width: card.cellW
                    height: card.cellH
                    text: entry.text || ""
                    icon: entry.icon || ""
                    iconKind: entry.iconKind || 0
                    selected: index === card.selectedIndex
                    selectable: entry.selectable !== false
                    marked: !!card.marked[card.shown[index]]
                    onHovered: (sx, sy) => {
                        const armed = gridView.lastPointer.x >= 0;
                        if (sx !== gridView.lastPointer.x || sy !== gridView.lastPointer.y) {
                            gridView.lastPointer = Qt.point(sx, sy);
                            if (armed && selectable)
                                card.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        card.selectedIndex = index;
                        card.picked(index);
                    }
                }
            }

            // thin scroll position tick on the right edge
            Rectangle {
                readonly property Flickable view: card.grid ? gridView : list
                visible: view.visible && view.contentHeight > view.height
                x: parent.width - 2
                y: view.y + view.visibleArea.yPosition * view.height
                width: 1
                height: Math.max(16, view.visibleArea.heightRatio * view.height)
                color: Theme.inkDim
            }

            // nothing matched
            Column {
                visible: card.shown.length === 0
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NO MATCH"
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.styleName: "Light"
                    font.pixelSize: 12
                    font.letterSpacing: 4
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.allowCustom && field.text.length ? "↵ USE THE TYPED TEXT" : "TRY ANOTHER FILTER"
                    color: Theme.inkFaint
                    font.family: Theme.mono
                    font.styleName: "Light"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }
        }

        Rule {}

        // ── key legend ───────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 26
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 3
                spacing: 18
                Hint { visible: !card.inputOnly; key: card.grid ? "\u2190\uFE0E\u2191\uFE0E\u2193\uFE0E\u2192\uFE0E" : "\u2191\uFE0E\u2193\uFE0E"; label: "move" }
                Hint { key: "↵"; label: card.inputOnly || card.shown.length === 0 ? "submit" : "choose" }
                Hint { visible: card.multiSelect && !card.inputOnly; key: "shift+↵"; label: "mark" }
                Hint {
                    visible: card.allowCustom && !card.inputOnly && !card.multiSelect
                    key: "shift+↵"; label: "use text"
                }
                Repeater {
                    model: card.customKeys.filter(c => c.label.length).slice(0, 3)
                    Hint {
                        required property var modelData
                        key: modelData.label
                        label: "action " + modelData.n
                    }
                }
                Hint { key: "esc"; label: "close" }
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 3
                text: "墨"
                color: Theme.inkFaint
                font.family: Theme.serif
                font.weight: Font.Black
                font.pixelSize: 13
            }
        }
    }

    component Rule: Rectangle {
        width: parent ? parent.width : 0
        height: visible ? 1 : 0
        color: Theme.hairline
    }

    component Hint: Row {
        property string key
        property string label
        spacing: 6
        Text {
            anchors.baseline: lbl.baseline
            text: parent.key
            color: Theme.ink
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
        Text {
            id: lbl
            text: parent.label
            color: Theme.inkDim
            font.family: Theme.mono
            font.styleName: "Light"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
