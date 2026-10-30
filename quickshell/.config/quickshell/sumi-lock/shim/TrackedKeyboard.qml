import QtQuick
import Quickshell

// SDDM-style `keyboard` object for the login screen. cage has no IPC for the active layout, so it is
// tracked from key presses: the grp:win_space_toggle key (Win+Space) and the script of typed text.
// Layouts come from XKB_DEFAULT_LAYOUT (set for cage by install-greeter.sh); xkb starts on the first one.
QtObject {
    property bool numLock: true
    property bool capsLock: false
    property int currentLayout: 0
    property var layouts: (Quickshell.env("XKB_DEFAULT_LAYOUT") || "us").split(",")
        .map(l => ({ shortName: l.trim(), longName: l.trim() }))

    readonly property bool winSpaceToggle: (Quickshell.env("XKB_DEFAULT_OPTIONS") || "").includes("grp:win_space_toggle")

    function indexOf(code) {
        return layouts.findIndex(l => l.shortName === code);
    }

    // called by the theme for every key pressed in the password field
    function keyPressed(event) {
        if (winSpaceToggle && event.nativeScanCode === 65 && (event.modifiers & Qt.MetaModifier)) { // 65 = space
            currentLayout = (currentLayout + 1) % layouts.length;
            return;
        }
        var c = event.text.length > 0 ? event.text.charCodeAt(0) : 0;
        var typed = (c >= 0x0600 && c <= 0x06FF) ? indexOf("ara") : (/[A-Za-z]/.test(event.text) ? indexOf("us") : -1);
        if (typed >= 0) currentLayout = typed;
    }
}
