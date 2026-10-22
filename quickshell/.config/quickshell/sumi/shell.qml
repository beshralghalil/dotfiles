//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// 墨 sumi shell: black-and-white, Japanese-styled desktop widgets (and, later,
// bar, launcher, picker and session menu). Inspired by Ryoku
// (github.com/ryoku-dev/ryoku, GPL-3.0).
//
// Run:     qs -p ~/.config/quickshell/sumi
// Toggle:  qs -p ~/.config/quickshell/sumi ipc call widgets toggle calendar
// Config:  ~/.config/sumi/widgets.json  (watched; edits apply immediately)
import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "desktop"
import "bar"
import "launcher"
import "picker"
import "session"

ShellRoot {
    Desktop {}

    // opt-in modules (off by default; switch on in ~/.config/sumi/widgets.json)
    LazyLoader {
        active: Config.data.barEnabled
        Bar {
            // the 墨 seal toggles the sumi launcher
            launcherCommand: "qs -p " + Quickshell.env("HOME") + "/.config/quickshell/sumi ipc call launcher toggle"
        }
    }
    LazyLoader {
        id: launcherLoader
        active: Config.data.launcherEnabled
        Launcher {}
    }

    // lock screen: separate process, see ~/.config/quickshell/sumi-lock (qylock "orbital" theme)

    IpcHandler {
        target: "launcher"
        function toggle(): string {
            if (!launcherLoader.item) return "launcher disabled (set launcherEnabled: true)";
            launcherLoader.item.toggle();
            return launcherLoader.item.open ? "open" : "closed";
        }
        function open(): string {
            if (!launcherLoader.item) return "launcher disabled (set launcherEnabled: true)";
            launcherLoader.item.show();
            return "open";
        }
        function close(): string {
            if (!launcherLoader.item) return "launcher disabled";
            launcherLoader.item.hide();
            return "closed";
        }
    }

    // dmenu-style menus, driven by the ~/.local/bin/sumi-menu script
    Picker { id: picker }
    IpcHandler {
        target: "picker"
        // open the request JSON the shim wrote; the answer goes to <request>.result
        function open(requestPath: string): string { return picker.openRequest(requestPath); }
        function cancel(): string { return picker.cancel(); }
        function windows(): string { return picker.openWindows(); }
        // shim internals: is its request still the open one / it was killed
        function status(requestPath: string): string { return picker.status(requestPath); }
        function dismiss(requestPath: string): string { return picker.dismiss(requestPath); }
    }

    // session / power menu (replaces wlogout)
    Session { id: session }
    IpcHandler {
        target: "session"
        function toggle(): string { session.toggle(); return session.open ? "open" : "closed"; }
        function open(): string { session.show(); return "open"; }
        function close(): string { session.hide(); return "closed"; }
    }

    IpcHandler {
        target: "widgets"

        // toggle / on / off a desktop widget: clock calendar music weather stats
        function toggle(name: string): string {
            if (!Config.isWidget(name)) return "unknown widget: " + name + " (use: " + Config.widgetNames.join(" ") + ")";
            Config.toggle(name + "Enabled");
            return name + (Config.data[name + "Enabled"] ? " on" : " off");
        }
        function on(name: string): string {
            if (!Config.isWidget(name)) return "unknown widget: " + name;
            Config.set(name + "Enabled", true);
            return name + " on";
        }
        function off(name: string): string {
            if (!Config.isWidget(name)) return "unknown widget: " + name;
            Config.set(name + "Enabled", false);
            return name + " off";
        }
        function lock(name: string): string {
            if (!Config.isWidget(name)) return "unknown widget: " + name;
            Config.toggle(name + "Locked");
            return name + (Config.data[name + "Locked"] ? " locked" : " unlocked");
        }
        function reset(name: string): string {
            if (!Config.isWidget(name)) return "unknown widget: " + name;
            Config.resetPosition(name);
            return name + " position reset";
        }
        function list(): string {
            return Config.widgetNames.map(n => n + ": " + (Config.data[n + "Enabled"] ? "on" : "off")
                                              + (Config.data[n + "Locked"] ? " (locked)" : "")).join("\n");
        }
    }
}
