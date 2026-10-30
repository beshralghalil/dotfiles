import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import "../common"
import "../services"

// One notification, shared by the popups and the notification center: app + time header,
// summary, body, an optional progress bar (int:value hint) and the sender's actions.
// Left click runs the default action and dismisses; right click / × closes (a popup only
// leaves the screen, it stays in the center).
Rectangle {
    id: card

    required property var notif
    property bool popup: false
    // the delegate can outlive its notification while it animates out
    function n() { return card.notif || ({}) }

    readonly property bool critical: n().urgency === NotificationUrgency.Critical
    readonly property int value: card.notif ? Notifs.progress(card.notif) : -1
    readonly property var actions: (n().actions || []).filter(a => a.identifier !== "default")
    // the sender's image, or an icon given as a file; theme icon names are skipped
    // (many resolve to a missing-icon placeholder)
    readonly property string imageSource: {
        const img = n().image || "", icon = n().appIcon || "";
        if (img !== "" && !img.startsWith("image://icon/")) return img.startsWith("/") ? "file://" + img : img;
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.startsWith("file://")) return icon;
        return "";
    }
    readonly property bool _fx: GraphicsInfo.api !== GraphicsInfo.Software

    function close() {
        if (!card.notif) return;
        if (card.popup) Notifs.hidePopup(card.notif);
        else Notifs.dismiss(card.notif);
    }

    implicitHeight: content.implicitHeight + 28
    radius: Theme.radius + 2
    color: card.popup ? Theme.card : Qt.rgba(1, 1, 1, 0.03)   // in the center: on its opaque panel
    border.width: 1
    border.color: card.critical ? Theme.ink : Theme.hairline

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => e.button === Qt.RightButton ? card.close() : Notifs.activate(card.notif)
    }

    Row {
        id: content
        x: 14; y: 14
        width: card.width - 28
        spacing: 12

        Item {
            id: thumb
            visible: card.imageSource !== "" && img.status !== Image.Error
            width: 36; height: 36
            Image {
                id: img
                anchors.fill: parent
                source: card.imageSource
                sourceSize: Qt.size(72, 72)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: !card._fx
            }
            MultiEffect {
                visible: card._fx
                anchors.fill: img
                source: img
                saturation: -1.0
            }
        }

        Column {
            width: content.width - (thumb.visible ? thumb.width + content.spacing : 0)
            spacing: 5

            Item { // header: app · time · close
                width: parent.width
                height: 16
                Text {
                    anchors.left: parent.left
                    anchors.right: time.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (card.n().appName || "notification").toUpperCase()
                    elide: Text.ElideRight
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Text {
                    id: time
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.notif ? Notifs.timeLabel(card.notif) : ""
                    color: Theme.inkDim
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
                Text {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0156}" // close
                    color: closeArea.containsMouse ? Theme.ink : Theme.inkDim
                    font.family: Theme.icon
                    font.pixelSize: 13
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.close()
                    }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.n().summary || ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.ink
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: card.n().body || ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 3 : 8
                elide: Text.ElideRight
                color: Theme.inkDim
                font.family: Theme.sans
                font.pixelSize: 12
                lineHeight: 1.15
            }

            Item { // progress (volume / brightness)
                visible: card.value >= 0
                width: parent.width
                height: 9
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 2
                    color: Theme.inkFaint
                    Rectangle {
                        width: parent.width * card.value / 100
                        height: parent.height
                        color: Theme.ink
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                }
            }

            Flow {
                visible: card.actions.length > 0
                width: parent.width
                spacing: 6
                topPadding: 3
                Repeater {
                    model: card.actions
                    delegate: Rectangle {
                        id: act
                        required property var modelData
                        width: actText.implicitWidth + 20
                        height: 24
                        radius: Theme.radius
                        color: actArea.containsMouse ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: Theme.hairline
                        Text {
                            id: actText
                            anchors.centerIn: parent
                            text: act.modelData.text
                            color: Theme.ink
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: actArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const keep = card.n().resident;
                                act.modelData.invoke();
                                if (!keep) Notifs.dismiss(card.notif);
                            }
                        }
                    }
                }
            }
        }
    }
}
