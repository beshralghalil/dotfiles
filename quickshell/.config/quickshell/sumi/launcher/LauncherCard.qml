import QtQuick
import "../common"

// 墨 launcher card: a dark translucent sheet with a mincho eyebrow, a thin mono
// search line, hairline rules, the ranked rows and a key legend.
//
//   起動 — アプリ                                      12 / 143
//   fire▏
//   ───────────────────────────────────────────────────────────
//   ■  [icon]  Firefox                                  起動 ↵
//   02 [icon]  ...
//   ───────────────────────────────────────────────────────────
//   ↑↓ 選択   ↵ 起動   = 計算   esc 閉じる                     墨
//
// Plain QtQuick, fed by `rows` (array of { name, generic, icon }), so it can be
// previewed off-screen; Launcher.qml owns the data and the actions.
// Row layout and keyboard model adapted from Ryoku's launcher
// (github.com/ryoku-dev/ryoku, GPL-3.0).
Rectangle {
    id: card

    property var rows: []
    property int totalCount: 0
    property int maxVisible: 7
    property int selectedIndex: 0

    // "=" calculator mode: Launcher fills these instead of rows
    property bool calcActive: false
    property string calcExpr: ""
    property string calcResult: ""     // "" when the expression is not valid (yet)
    property bool copied: false

    property alias text: field.text
    readonly property alias input: field

    signal activated(int index)
    signal calcAccepted()
    signal dismissed()

    function focusSearch() { field.forceActiveFocus(); }
    function reset() {
        field.text = "";
        card.selectedIndex = 0;
        card.copied = false;
        list.positionViewAtBeginning();
    }
    function move(delta) {
        if (card.calcActive || card.rows.length === 0)
            return;
        card.selectedIndex = Math.max(0, Math.min(card.rows.length - 1, card.selectedIndex + delta));
    }
    function accept() {
        if (card.calcActive) {
            if (card.calcResult.length)
                card.calcAccepted();
        } else if (card.selectedIndex >= 0 && card.selectedIndex < card.rows.length) {
            card.activated(card.selectedIndex);
        }
    }

    onSelectedIndexChanged: list.positionViewAtIndex(card.selectedIndex, ListView.Contain)
    onRowsChanged: if (card.selectedIndex >= card.rows.length) card.selectedIndex = Math.max(0, card.rows.length - 1)

    readonly property int pad: 22
    readonly property int rowH: 52
    readonly property int listH: card.calcActive ? calcPanel.implicitHeight
        : card.rows.length === 0 ? 96
        : Math.min(card.rows.length, card.maxVisible) * card.rowH

    width: 640
    implicitHeight: body.implicitHeight + card.pad * 2
    height: implicitHeight
    radius: Theme.radius + 2
    color: Theme.card
    border.color: Theme.hairline
    border.width: 1
    clip: true

    Behavior on height { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }

    // swallow clicks on the card so they don't fall through to the click-out scrim
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
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.calcActive ? "CALCULATOR" : "APPLICATIONS"
                color: Theme.inkDim
                font.family: Theme.serif
                font.weight: Font.Light
                font.pixelSize: 13
                font.letterSpacing: 2
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                text: card.calcActive ? "CALC"
                    : field.text.length ? card.rows.length + " / " + card.totalCount
                    : card.totalCount + " APPS"
                color: Theme.inkDim
                font.family: Theme.mono
                font.styleName: "Light"
                font.pixelSize: 10
                font.letterSpacing: 2
                font.features: { "tnum": 1 }
            }
        }

        // ── search line ─────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 58

            Text {
                id: seal
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Theme.ink
                font.family: Theme.serif
                font.weight: Font.Medium
                font.pixelSize: 15
                font.letterSpacing: 3
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
                font.pixelSize: 28
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
                    visible: field.text.length === 0
                    text: "search apps   = calc"
                    color: Theme.inkFaint
                    font: field.font
                }

                onTextChanged: {
                    card.selectedIndex = 0;
                    card.copied = false;
                    list.positionViewAtBeginning();
                }

                Keys.onPressed: e => {
                    const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                    if (e.key === Qt.Key_Escape) {
                        card.dismissed();
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        card.accept();
                    } else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab
                               || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                        card.move(1);
                    } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab
                               || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                        card.move(-1);
                    } else if (e.key === Qt.Key_PageDown) {
                        card.move(card.maxVisible);
                    } else if (e.key === Qt.Key_PageUp) {
                        card.move(-card.maxVisible);
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

        // ── results ─────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: card.listH + 16

            ListView {
                id: list
                visible: !card.calcActive && card.rows.length > 0
                x: 0; y: 8
                width: parent.width - (interactive ? 8 : 0)
                height: card.listH
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: card.rows.length > card.maxVisible
                model: card.calcActive ? 0 : card.rows.length
                highlightMoveDuration: 0
                reuseItems: true

                // window position of the last hover allowed to move the selection
                property point lastPointer: Qt.point(-1, -1)

                delegate: ResultRow {
                    required property int index
                    readonly property var entry: card.rows[index] || ({})
                    width: list.width
                    height: card.rowH
                    ordinal: index
                    name: entry.name || ""
                    generic: entry.generic || ""
                    icon: entry.icon || ""
                    selected: index === card.selectedIndex
                    onHovered: (sx, sy) => {
                        if (sx !== list.lastPointer.x || sy !== list.lastPointer.y) {
                            list.lastPointer = Qt.point(sx, sy);
                            card.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        card.selectedIndex = index;
                        card.activated(index);
                    }
                }
            }

            // thin scroll position tick on the right edge
            Rectangle {
                visible: list.visible && list.contentHeight > list.height
                x: parent.width - 2
                y: list.y + list.visibleArea.yPosition * list.height
                width: 1
                height: Math.max(16, list.visibleArea.heightRatio * list.height)
                color: Theme.inkDim
            }

            // nothing matched
            Column {
                visible: !card.calcActive && card.rows.length === 0
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "no match"
                    color: Theme.inkDim
                    font.family: Theme.serif
                    font.weight: Font.Light
                    font.pixelSize: 16
                    font.letterSpacing: 4
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "NO MATCH"
                    color: Theme.inkFaint
                    font.family: Theme.mono
                    font.styleName: "Light"
                    font.pixelSize: 10
                    font.letterSpacing: 3
                }
            }

            // calculator
            Column {
                id: calcPanel
                visible: card.calcActive
                x: 6; y: 8
                width: parent.width - 12
                spacing: 4
                topPadding: 8
                bottomPadding: 8

                Text {
                    width: parent.width
                    text: card.calcExpr.length ? card.calcExpr : "2^10 + sqrt(16)"
                    color: card.calcExpr.length ? Theme.inkDim : Theme.inkFaint
                    font.family: Theme.mono
                    font.styleName: "Light"
                    font.pixelSize: 13
                    elide: Text.ElideLeft
                }
                Row {
                    spacing: 14
                    Text {
                        anchors.baseline: result.baseline
                        text: "="
                        color: Theme.inkDim
                        font.family: Theme.mono
                        font.styleName: "Thin"
                        font.pixelSize: 26
                    }
                    Text {
                        id: result
                        width: calcPanel.width - 40
                        text: card.calcResult.length ? card.calcResult : "—"
                        color: card.calcResult.length ? Theme.ink : Theme.inkFaint
                        font.family: Theme.mono
                        font.styleName: "Thin"
                        font.pixelSize: 44
                        elide: Text.ElideRight
                    }
                }
                Row {
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 1
                        color: card.calcResult.length ? Theme.ink : "transparent"
                        border.color: card.calcResult.length ? Theme.ink : Theme.inkDim
                        border.width: 1
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.copied ? "COPIED"
                            : card.calcResult.length ? "↵ COPY"
                            : card.calcExpr.length ? "INVALID" : "TYPE AN EXPRESSION"
                        color: Theme.inkDim
                        font.family: Theme.mono
                        font.styleName: "Light"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                }
            }
        }

        Rule {}

        // ── key legend ──────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 26
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 3
                spacing: 18
                Hint { key: "↑↓"; label: "select" }
                Hint { key: "↵"; label: card.calcActive ? "copy" : "open" }
                Hint { key: "="; label: "calculate" }
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
        height: 1
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
            font.family: Theme.serif
            font.weight: Font.Light
            font.pixelSize: 11
            font.letterSpacing: 1
        }
    }
}
