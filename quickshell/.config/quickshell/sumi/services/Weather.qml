pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Weather from open-meteo.com (no API key). Only runs while the weather widget
// is enabled. Set "weatherCity" in ~/.config/sumi/widgets.json; it is geocoded
// once, then current conditions refresh every 30 minutes.
Singleton {
    id: root

    property bool active: Config.data.weatherEnabled
    property string city: Config.data.weatherCity
    property bool fahrenheit: Config.data.weatherFahrenheit

    property string status: "loading"   // loading | ok | noCity | error
    property string place: ""
    property real lat: NaN
    property real lon: NaN
    property real temp: 0
    property real high: 0
    property real low: 0
    property int code: 0

    function refresh() {
        if (!root.active) return;
        if (root.city.trim() === "") { root.status = "noCity"; return; }
        if (isNaN(root.lat)) geo.running = true;
        else forecast.running = true;
    }

    onActiveChanged: refresh()
    onCityChanged: { root.lat = NaN; root.status = "loading"; refresh(); }
    onFahrenheitChanged: refresh()

    Process {
        id: geo
        command: ["curl", "-sf", "--max-time", "10",
                  "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&name=" + encodeURIComponent(root.city.trim())]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(this.text).results;
                    if (!r || !r.length) { root.status = "error"; root.place = root.city; return; }
                    root.lat = r[0].latitude;
                    root.lon = r[0].longitude;
                    root.place = r[0].name;
                    forecast.running = true;
                } catch (e) { root.status = "error"; }
            }
        }
        onExited: code => { if (code !== 0) root.status = "error"; }
    }

    Process {
        id: forecast
        command: ["curl", "-sf", "--max-time", "10",
                  "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat + "&longitude=" + root.lon
                  + "&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min"
                  + "&timezone=auto&forecast_days=1" + (root.fahrenheit ? "&temperature_unit=fahrenheit" : "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text);
                    root.temp = j.current.temperature_2m;
                    root.code = j.current.weather_code;
                    root.high = j.daily.temperature_2m_max[0];
                    root.low = j.daily.temperature_2m_min[0];
                    root.status = "ok";
                } catch (e) { root.status = "error"; }
            }
        }
        onExited: code => { if (code !== 0) root.status = "error"; }
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
