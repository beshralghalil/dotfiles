import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Services.Greetd

Item {
    id: shim

    // false = lock screen (current user, PAM); true = greetd login screen (system users, sessions, greetd auth)
    property bool greeter: false
    property string themePath: ""
    property var config: ({})
    property bool configReady: false

    function loadConfig(path) {
        if (!path) {
            config = { background: "bg.png" };
            configReady = true;
            return;
        }
        var url = "file://" + path + "/theme.conf";
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var newConfig = {};
                if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText) {
                    var lines = xhr.responseText.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.startsWith("[") || line === "" || line.startsWith("#")) continue;
                        var parts = line.split("=");
                        if (parts.length === 2) {
                            newConfig[parts[0].trim()] = parts[1].trim();
                        }
                    }
                }
                // Default background fallback
                if (!newConfig.background) {
                    newConfig.background = "bg.png";
                }
                config = newConfig;
                configReady = true;
            }
        };
        try {
            xhr.open("GET", url, true);
            xhr.send();
        } catch (e) {
            console.warn("SddmShim: failed to load theme.conf:", e);
            config = { background: "bg.png" };
            configReady = true;
        }
    }

    property var userModel: ListModel {
        id: internalUserModel
        property string lastUser: Quickshell.env("USER") || "traveler"
        property int lastIndex: 0
        function rowCount() { return count; }

        function index(row, col) {
            return row;
        }

        function data(row, role) {
            var item = get(row);
            if (!item) return "";
            if (role === (Qt.UserRole + 1)) return item.name;
            if (role === (Qt.UserRole + 2)) return item.realName;
            return item.name;
        }

        Component.onCompleted: {
            if (shim.greeter) return; // filled by userEnumerator
            append({
                name: Quickshell.env("USER") || "traveler",
                realName: Quickshell.env("USER") || "Traveler",
                icon: "",
                homeDir: "/home/" + (Quickshell.env("USER") || "traveler")
            })
        }
    }

    // Greeter: regular users (UID 1000-59999 with a login shell)
    Process {
        id: userEnumerator
        command: ["getent", "passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split(":");
                    var uid = parseInt(f[2]);
                    if (f.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(f[6])) continue;
                    internalUserModel.append({ name: f[0], realName: f[4].split(",")[0] || f[0], icon: "", homeDir: f[5] });
                }
                if (internalUserModel.count > 0) internalUserModel.lastUser = internalUserModel.get(0).name;
            }
        }
    }

    property var sessionModel: ListModel {
        id: internalSessionModel
        property int lastIndex: 0
        function rowCount() { return count; }
        function index(row, col) { return row; }
        function data(row, role) {
            var item = get(row);
            if (!item) return "";
            return item.name;
        }
        Component.onCompleted: {
            // Initial session placeholder
            append({ name: "Session", file: "" });
        }
    }

    // Enumerate system sessions
    Process {
        id: sessionEnumerator
        command: [
            "bash", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop; do " +
            "if [ -f \"$f\" ]; then " +
            "NAME=$(grep -m1 '^Name=' \"$f\" | cut -d'=' -f2); " +
            "FILE=$(basename \"$f\"); " +
            "EXEC=$(grep -m1 '^Exec=' \"$f\" | cut -d'=' -f2-); " +
            "DESKTOPS=$(grep -m1 '^DesktopNames=' \"$f\" | cut -d'=' -f2); " +
            "echo \"$NAME|||$FILE|||$EXEC|||$DESKTOPS\"; " +
            "fi; done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                shim.parseSessions(this.text);
            }
        }

        onExited: (exitCode, exitStatus) => {
            // No sessions fallback
            if (internalSessionModel.count === 0) {
                internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
            }
        }
    }

    function parseSessions(output) {
        if (!output || output.trim() === "") {
            internalSessionModel.clear();
            internalSessionModel.append({ name: "Session", file: "unknown.desktop" });
            return;
        }

        internalSessionModel.clear();
        var lines = output.trim().split("\n");
        var currentDesktop = shim.greeter ? "" : (Quickshell.env("XDG_SESSION_DESKTOP") || Quickshell.env("DESKTOP_SESSION") || "").toLowerCase();
        // greeter: start on this session file
        var defaultSession = Quickshell.env("SUMI_DEFAULT_SESSION") || "hyprland.desktop";
        var bestIndex = 0;
        var added = 0;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;

            var parts = line.split("|||");
            if (parts.length >= 2 && parts[0] !== "" && parts[1] !== "") {
                internalSessionModel.append({ name: parts[0], file: parts[1], exec: parts[2] || "", desktopNames: parts[3] || "" });

                // Match current desktop
                var fileName = parts[1].toLowerCase();
                if (currentDesktop !== "" && (fileName.indexOf(currentDesktop) !== -1 || currentDesktop.indexOf(fileName.replace(".desktop", "")) !== -1)) {
                    bestIndex = added;
                } else if (currentDesktop === "" && parts[1] === defaultSession) {
                    bestIndex = added;
                }
                added++;
            }
        }

        // Fallback for sessions
        if (added === 0) {
            internalSessionModel.append({ name: "Unknown", file: "unknown.desktop" });
        } else {
            internalSessionModel.lastIndex = bestIndex;
        }
    }

    property var sddm: QtObject {
        // the theme shows the session picker only when hostName is defined (= real login screen)
        readonly property var hostName: shim.greeter ? "sumi" : undefined

        signal loginFailed()
        signal loginSucceeded()

        function login(user, password, sessionIndex) {
            if (shim.greeter) {
                shim.greetdPassword = password;
                shim.greetdSession = sessionIndex;
                Greetd.createSession(user);
                return;
            }
            pam.user = user;
            pam.pendingPassword = password;
            pam.start();
        }

        function reboot() { Quickshell.execDetached(["bash", "-c", "if [ -d /run/systemd/system ]; then systemctl reboot; else loginctl reboot; fi"]); }
        function powerOff() { Quickshell.execDetached(["bash", "-c", "if [ -d /run/systemd/system ]; then systemctl poweroff; else loginctl poweroff; fi"]); }
    }

    PamContext {
        id: pam
        property string pendingPassword: ""

        onResponseRequiredChanged: {
            if (responseRequired && pendingPassword !== "") {
                respond(pendingPassword);
                pendingPassword = "";
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                shim.sddm.loginSucceeded();
                Quickshell.execDetached(["loginctl", "unlock-session"]);
                // Notify success handlers
            } else {
                shim.sddm.loginFailed();
            }
        }
    }

    // Greeter login: createSession -> answer the password prompt -> launch the chosen session
    property string greetdPassword: ""
    property int greetdSession: 0

    function greetdFailed() {
        greetdPassword = "";
        Greetd.cancelSession();
        sddm.loginFailed();
    }

    Connections {
        target: shim.greeter ? Greetd : null

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(shim.greetdPassword);
                shim.greetdPassword = "";
            }
        }
        function onAuthFailure(message) { shim.greetdFailed(); }
        function onError(error) {
            console.warn("greetd:", error);
            shim.greetdFailed();
        }
        function onReadyToLaunch() {
            var s = internalSessionModel.get(shim.greetdSession) || internalSessionModel.get(0);
            var id = s.file.replace(/\.desktop$/, "");
            // session output goes to the journal (journalctl -t <id>), not the console behind the greeter
            var cmd = ["systemd-cat", "-t", id].concat(s.exec.split(/\s+/).filter(a => a !== "" && !a.startsWith("%")));
            var env = [
                "XDG_SESSION_TYPE=wayland",
                "XDG_SESSION_DESKTOP=" + id,
                "XDG_CURRENT_DESKTOP=" + (s.desktopNames.replace(/;+$/, "").replace(/;/g, ":") || s.name)
            ];
            shim.sddm.loginSucceeded();
            Greetd.launch(cmd, env, true);
        }
    }

    onThemePathChanged: loadConfig(themePath)
    Component.onCompleted: {
        sessionEnumerator.running = true;
        if (greeter) userEnumerator.running = true;
    }
}
