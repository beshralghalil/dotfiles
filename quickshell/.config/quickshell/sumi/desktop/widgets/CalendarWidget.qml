import QtQuick
import "../../common"

// Month calendar, 墨 style:
//   OCTOBER  神無月                2026
//   ───────────────────────────────
//   S   M   T   W   T   F   S
//                1   2   3   4
//   ...           [21]  <- today: ink-filled square
// `shown` picks the month to draw, `today` marks the current day (only when it
// falls in that month). Plain QtQuick so it can be previewed off-screen.
Item {
    id: cal

    property date now: new Date()      // kept for compatibility: sets both below
    property date shown: now
    property date today: now
    property real scale_: 1.0
    function px(v) { return Math.round(v * cal.scale_) }

    readonly property var monthLatin: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
                                       "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    readonly property var weekdayLetters: ["S", "M", "T", "W", "T", "F", "S"]

    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    readonly property bool isCurrentMonth: today.getFullYear() === year && today.getMonth() === month
    readonly property int todayDay: isCurrentMonth ? today.getDate() : -1
    readonly property int firstDow: new Date(year, month, 1).getDay()
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property int rows: Math.ceil((firstDow + daysInMonth) / 7)
    readonly property int cell: px(38)

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        spacing: cal.px(10)

        // heading
        Item {
            width: grid.width
            height: monthName.implicitHeight
            Row {
                spacing: cal.px(12)
                Text {
                    id: monthName
                    text: cal.monthLatin[cal.month]
                    color: Theme.ink
                    font.family: Theme.mono
                    font.weight: Font.Light
                    font.styleName: "Light"
                    font.pixelSize: cal.px(20)
                    font.letterSpacing: cal.px(4)
                }
                Text { // traditional month name, decorative
                    anchors.bottom: monthName.bottom
                    anchors.bottomMargin: cal.px(2)
                    text: Theme.monthNames[cal.month]
                    color: Theme.inkFaint
                    font.family: Theme.serif
                    font.weight: Font.Light
                    font.pixelSize: cal.px(14)
                    font.letterSpacing: cal.px(3)
                }
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: cal.px(2)
                text: cal.year
                color: Theme.inkDim
                font.family: Theme.mono
                font.weight: Font.Light
                font.styleName: "Light"
                font.pixelSize: cal.px(15)
                font.letterSpacing: cal.px(3)
            }
        }

        Rectangle { width: grid.width; height: Math.max(1, cal.px(1)); color: Theme.hairline }

        // weekday header
        Row {
            Repeater {
                model: 7
                Text {
                    required property int index
                    width: cal.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: cal.weekdayLetters[index]
                    color: index === 0 || index === 6 ? Theme.inkDim : Theme.ink
                    font.family: Theme.mono
                    font.weight: Font.Light
                    font.styleName: "Light"
                    font.pixelSize: cal.px(13)
                    font.letterSpacing: cal.px(1)
                }
            }
        }

        Grid {
            id: grid
            columns: 7
            Repeater {
                model: cal.rows * 7
                Item {
                    required property int index
                    readonly property int day: index - cal.firstDow + 1
                    readonly property bool inMonth: day >= 1 && day <= cal.daysInMonth
                    readonly property bool isToday: day === cal.todayDay
                    readonly property int dow: index % 7
                    width: cal.cell
                    height: cal.px(34)

                    Rectangle {
                        anchors.centerIn: parent
                        width: cal.px(30); height: width
                        radius: cal.px(3)
                        color: Theme.ink
                        visible: parent.isToday
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: parent.inMonth
                        text: parent.day
                        color: parent.isToday ? Theme.paper
                             : (parent.dow === 0 || parent.dow === 6) ? Theme.inkDim : Theme.ink
                        font.family: Theme.mono
                        font.weight: parent.isToday ? Font.Medium : Font.Light
                        font.pixelSize: cal.px(15)
                    }
                }
            }
        }
    }
}
