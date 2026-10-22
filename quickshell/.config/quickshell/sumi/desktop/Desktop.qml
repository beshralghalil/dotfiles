import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../common"
import "../services"
import "widgets"

// Desktop widgets: one transparent surface per monitor on the layer below
// normal windows (above the wallpaper). It never takes keyboard focus; pointer
// input is limited to the visible widgets (and the whole screen while the
// right-click menu is open, so a click elsewhere closes it).
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "sumi-desktop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        property string menuTarget: ""
        property real menuX: 0
        property real menuY: 0
        function openMenu(name, x, y) {
            win.menuTarget = name;
            win.menuX = Math.min(x, area.width - menu.width - 8);
            win.menuY = Math.min(y, area.height - menu.height - 8);
        }

        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }

        // the MPRIS player to show: first playing one, else the first available
        readonly property var player: {
            // skip playerctld: it is a proxy that shows up as a player even when nothing plays
            const ps = Mpris.players.values.filter(p => !(p.dbusName || "").includes("playerctld"));
            for (let i = 0; i < ps.length; i++)
                if (ps[i].isPlaying) return ps[i];
            return ps.length ? ps[0] : null;
        }
        Timer { // MPRIS position is not pushed; poll it while visible
            interval: 1000
            repeat: true
            running: Config.data.musicEnabled && win.player !== null && win.player.isPlaying
            onTriggered: win.player.positionChanged()
        }

        mask: Region {
            Region { item: clockSlot.active ? clockSlot.item.hitbox : null }
            Region { item: calendarSlot.active ? calendarSlot.item.hitbox : null }
            Region { item: musicSlot.active ? musicSlot.item.hitbox : null }
            Region { item: weatherSlot.active ? weatherSlot.item.hitbox : null }
            Region { item: statsSlot.active ? statsSlot.item.hitbox : null }
            Region { item: win.menuTarget !== "" ? area : null }
        }

        Item {
            id: area
            anchors.fill: parent

            // click anywhere outside the menu closes it
            MouseArea {
                anchors.fill: parent
                enabled: win.menuTarget !== ""
                acceptedButtons: Qt.AllButtons
                onPressed: win.menuTarget = ""
            }

            Loader {
                id: clockSlot
                active: Config.data.clockEnabled
                sourceComponent: WidgetSlot {
                    name: "clock"
                    areaWidth: area.width; areaHeight: area.height
                    onMenuRequested: (n, x, y) => win.openMenu(n, x, y)
                    ClockFace {
                        now: clock.date
                        use24h: Config.data.clock24h
                        minuteLine: Config.data.clockMinuteLine
                    }
                }
            }

            Loader {
                id: calendarSlot
                active: Config.data.calendarEnabled
                sourceComponent: WidgetSlot {
                    name: "calendar"
                    areaWidth: area.width; areaHeight: area.height
                    onMenuRequested: (n, x, y) => win.openMenu(n, x, y)
                    CalendarWidget { now: clock.date }
                }
            }

            Loader {
                id: musicSlot
                active: Config.data.musicEnabled
                sourceComponent: WidgetSlot {
                    name: "music"
                    areaWidth: area.width; areaHeight: area.height
                    onMenuRequested: (n, x, y) => win.openMenu(n, x, y)
                    MusicWidget {
                        hasPlayer: win.player !== null
                        title: win.player ? win.player.trackTitle : ""
                        artist: win.player ? win.player.trackArtist : ""
                        levels: AudioBars.levels
                        playing: win.player ? win.player.isPlaying : false
                        position: win.player ? win.player.position : 0
                        length: win.player ? win.player.length : 0
                        onTogglePlay: if (win.player && win.player.canTogglePlaying) win.player.togglePlaying()
                        onNext: if (win.player && win.player.canGoNext) win.player.next()
                        onPrevious: if (win.player && win.player.canGoPrevious) win.player.previous()
                    }
                }
            }

            Loader {
                id: weatherSlot
                active: Config.data.weatherEnabled
                sourceComponent: WidgetSlot {
                    name: "weather"
                    areaWidth: area.width; areaHeight: area.height
                    onMenuRequested: (n, x, y) => win.openMenu(n, x, y)
                    WeatherWidget {
                        status: Weather.status
                        city: Weather.place || Config.data.weatherCity
                        temp: Weather.temp
                        high: Weather.high
                        low: Weather.low
                        code: Weather.code
                        fahrenheit: Config.data.weatherFahrenheit
                    }
                }
            }

            Loader {
                id: statsSlot
                active: Config.data.statsEnabled
                sourceComponent: WidgetSlot {
                    name: "stats"
                    areaWidth: area.width; areaHeight: area.height
                    onMenuRequested: (n, x, y) => win.openMenu(n, x, y)
                    StatsWidget {
                        cpu: Stats.cpu
                        mem: Stats.mem
                        memUsed: Stats.memUsed
                        memTotal: Stats.memTotal
                        temp: Stats.temp
                        uptime: Stats.uptime
                    }
                }
            }

            WidgetMenu {
                id: menu
                visible: win.menuTarget !== ""
                target: win.menuTarget || "clock"
                x: win.menuX
                y: win.menuY
                onClose: win.menuTarget = ""
            }
        }
    }
}
