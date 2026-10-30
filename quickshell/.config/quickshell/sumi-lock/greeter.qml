// 墨 sumi login screen: the lock screen's theme as a greetd greeter (run by greeter.sh inside cage).
import QtQuick
import Quickshell
import "./shim"

ShellRoot {
    id: shellRoot

    property string themePath: Quickshell.env("QS_THEME_PATH") || (Quickshell.shellDir + "/themes/clockwork/orbital")

    readonly property var sddm: sddmShim.sddm
    readonly property var config: sddmShim.config
    readonly property var userModel: sddmShim.userModel
    readonly property var sessionModel: sddmShim.sessionModel
    readonly property var keyboard: TrackedKeyboard {}
    readonly property var battery: Battery {}

    SddmShim {
        id: sddmShim
        greeter: true
        themePath: shellRoot.themePath
    }

    // cage shows it fullscreen
    FloatingWindow {
        color: "black"

        Loader {
            anchors.fill: parent
            source: "file://" + shellRoot.themePath + "/Main.qml"
            onLoaded: item.forceActiveFocus()
            onStatusChanged: if (status === Loader.Error) console.error("FAILED to load theme:", source)
        }
    }
}
