import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Low-battery alerts (replaces batsignal): one notification per level per discharge, at the
// batteryWarn / batteryCritical / batteryDanger percentages in ~/.config/sumi/widgets.json,
// reset when the charger is plugged in; optional "charging" / "discharging" messages.
// Policy adapted from Ryoku's BatteryAlerts (github.com/ryoku-dev/ryoku, GPL-3.0).
Scope {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool ready: device.ready && device.isLaptopBattery && device.isPresent
    readonly property bool onBattery: UPower.onBattery
    readonly property int percent: ready ? Math.round(device.percentage * 100) : -1

    // highest level already announced this discharge: 0 none, 1 warn, 2 critical, 3 danger
    property int announced: 0

    function levels() {
        return [
            { level: 3, at: Config.data.batteryDanger, title: "Battery danger", urgency: "critical" },
            { level: 2, at: Config.data.batteryCritical, title: "Battery critical", urgency: "critical" },
            { level: 1, at: Config.data.batteryWarn, title: "Battery low", urgency: "normal" }
        ];
    }

    function send(urgency, title, body, icon) {
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", urgency, "-i", icon,
                                 "-h", "string:x-canonical-private-synchronous:sumi-battery", title, body]);
    }

    function evaluate() {
        if (!ready || !onBattery || percent < 0) return;
        const hit = levels().find(l => l.at > 0 && percent <= l.at);
        if (!hit || hit.level <= root.announced) return;
        root.announced = hit.level;
        send(hit.urgency, hit.title, percent + "% left. Connect the charger.", "battery-caution");
    }

    onOnBatteryChanged: {
        if (!ready) return;
        if (!onBattery) root.announced = 0;
        if (Config.data.batteryPlugMessages)
            send("low", onBattery ? "Discharging" : "Charging", "Battery at " + percent + "%.",
                 onBattery ? "battery" : "battery-good-charging");
        evaluate();
    }
    onPercentChanged: evaluate()
    onReadyChanged: evaluate()

    IpcHandler {
        target: "battery"
        function status(): string {
            return JSON.stringify({ percent: root.percent, onBattery: root.onBattery, announced: root.announced,
                                    warn: Config.data.batteryWarn, critical: Config.data.batteryCritical,
                                    danger: Config.data.batteryDanger });
        }
        function test(): void { root.send("normal", "Battery alerts", "Test: alerts at " + Config.data.batteryWarn
            + "% / " + Config.data.batteryCritical + "% / " + Config.data.batteryDanger + "%.", "battery-caution") }
    }
}
