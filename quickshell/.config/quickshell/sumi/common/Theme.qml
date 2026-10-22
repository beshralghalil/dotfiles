pragma Singleton
import QtQuick

// 墨 (sumi) design tokens: black-and-white, Japanese editorial.
// Plain QtObject (not a Quickshell Singleton) so widget faces can also be
// rendered off-screen by plain Qt for previews.
QtObject {
    readonly property color ink: "#eaeaeb"
    readonly property color inkDim: "#8d8d90"
    readonly property color inkFaint: "#3a3a3d"
    readonly property color paper: "#0b0b0c"
    readonly property color card: Qt.rgba(0.043, 0.043, 0.047, 0.86)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.14)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.07)

    readonly property string mono: "JetBrains Mono"
    readonly property string serif: "Noto Serif CJK JP"
    readonly property string sans: "Noto Sans CJK JP"
    // monochrome line icons (Material Design glyphs from the Nerd Font)
    readonly property string icon: "JetBrainsMono Nerd Font Propo"

    readonly property int radius: 4

    readonly property var weekdayKanji: ["日", "月", "火", "水", "木", "金", "土"]
    readonly property var weekdayLatin: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    // traditional month names (和風月名)
    readonly property var monthNames: ["睦月", "如月", "弥生", "卯月", "皐月", "水無月",
                                       "文月", "葉月", "長月", "神無月", "霜月", "師走"]

    function pad2(n) { return n < 10 ? "0" + n : "" + n }
    function kanjiNum(n) {
        var d = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
        if (n < 10) return n === 0 ? "〇" : d[n];
        if (n >= 100) return "" + n;
        var tens = Math.floor(n / 10), ones = n % 10;
        return (tens > 1 ? d[tens] : "") + "十" + d[ones];
    }
    function season(m) { // m: 0..11
        return m >= 2 && m <= 4 ? "春" : m >= 5 && m <= 7 ? "夏" : m >= 8 && m <= 10 ? "秋" : "冬";
    }
    function era(y) {
        return y >= 2019 ? "令和" + (y === 2019 ? "元" : kanjiNum(y - 2018)) + "年" : "" + y;
    }
}
