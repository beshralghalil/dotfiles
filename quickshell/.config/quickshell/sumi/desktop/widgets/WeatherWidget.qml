import QtQuick
import "../../common"

// Weather, 墨 style:  [晴]  18°   CLEAR
//                           H 21° · L 12°
//                           東京 / city
// `code` is a WMO weather code (as returned by open-meteo.com).
Item {
    id: wx

    property string status: "loading"   // loading | ok | noCity | error
    property string city: ""
    property real temp: 0
    property real high: 0
    property real low: 0
    property int code: 0
    property bool fahrenheit: false
    property real scale_: 1.0
    function px(v) { return Math.round(v * wx.scale_) }

    function kanji(c) {
        if (c === 0 || c === 1) return "\u{F0599}"; // sunny
        if (c === 2 || c === 3) return "\u{F0590}"; // cloudy
        if (c === 45 || c === 48) return "\u{F0591}"; // fog
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "\u{F0598}"; // snow
        if (c >= 95) return "\u{F0593}"; // thunder
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "\u{F0597}"; // rain
        return "\u{F0590}";
    }
    function label(c) {
        if (c === 0) return "CLEAR";
        if (c === 1) return "MAINLY CLEAR";
        if (c === 2) return "PARTLY CLOUDY";
        if (c === 3) return "OVERCAST";
        if (c === 45 || c === 48) return "FOG";
        if (c >= 51 && c <= 57) return "DRIZZLE";
        if (c >= 61 && c <= 67) return "RAIN";
        if (c >= 71 && c <= 77) return "SNOW";
        if (c >= 80 && c <= 82) return "SHOWERS";
        if (c === 85 || c === 86) return "SNOW SHOWERS";
        if (c >= 95) return "THUNDERSTORM";
        return "—";
    }
    function deg(v) { return Math.round(v) + "°" }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: wx.px(22)

        Rectangle {
            width: wx.px(58); height: width
            radius: wx.px(3)
            color: wx.status === "ok" ? Theme.ink : "transparent"
            border.color: Theme.hairline
            border.width: wx.status === "ok" ? 0 : Math.max(1, wx.px(1))
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -wx.px(2)
                text: wx.status === "ok" ? wx.kanji(wx.code) : "\u{F0590}"
                color: wx.status === "ok" ? Theme.paper : Theme.inkFaint
                font.family: Theme.icon
                font.pixelSize: wx.px(36)
            }
        }

        Text {
            visible: wx.status === "ok"
            anchors.verticalCenter: parent.verticalCenter
            text: wx.deg(wx.temp)
            color: Theme.ink
            font.family: Theme.mono
            font.weight: Font.Thin
            font.styleName: "Thin"
            font.pixelSize: wx.px(72)
            font.letterSpacing: -wx.px(2)
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: wx.px(6)
            Text {
                text: wx.status === "ok" ? wx.label(wx.code)
                    : wx.status === "noCity" ? "SET weatherCity"
                    : wx.status === "error" ? "UNAVAILABLE" : "LOADING"
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.pixelSize: wx.px(14)
                font.letterSpacing: wx.px(3)
            }
            Text {
                visible: wx.status === "ok"
                text: "H " + wx.deg(wx.high) + "  ·  L " + wx.deg(wx.low)
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.pixelSize: wx.px(14)
                font.letterSpacing: wx.px(1)
            }
            Text {
                text: wx.status === "noCity" ? "~/.config/sumi/widgets.json" : wx.city
                color: Theme.inkDim
                font.family: Theme.serif
                font.weight: Font.Light
                font.pixelSize: wx.px(16)
                font.letterSpacing: wx.px(2)
            }
        }
    }
}
