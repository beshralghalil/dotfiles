import QtQuick
import Quickshell.Services.UPower

// Laptop battery for the theme's HUD (UPower): present / percent (0-100) / charging / full
QtObject {
    readonly property var device: UPower.displayDevice
    readonly property bool present: device.ready && device.isLaptopBattery
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property bool charging: !UPower.onBattery && !full
}
