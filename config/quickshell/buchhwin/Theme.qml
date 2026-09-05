import QtQuick

QtObject {
    readonly property color bg: "#181818"
    readonly property color surface: "#242424"
    readonly property color surface2: "#303030"
    readonly property color surface3: "#414141"
    readonly property color border: "#505050"
    readonly property color text: "#eeeeee"
    readonly property color subtext: "#aaaaaa"
    readonly property color blue: "#d0d0d0"
    readonly property color mauve: "#c4c4c4"
    readonly property color green: "#d8d8d8"
    readonly property color red: "#f38ba8"
    readonly property color yellow: "#bcbcbc"
    readonly property string font: "MesloLGS Nerd Font Mono"

    // Motion.
    //
    // One vocabulary for the whole shell: every panel uses the same durations
    // and curves, so nothing feels like it was borrowed from another program.
    // Opening decelerates into place, closing accelerates away.
    readonly property int durationFast: 110    // hover and colour changes
    readonly property int durationMedium: 170  // panels opening and closing
    readonly property int durationSlow: 240    // notification popups
    readonly property int durationRecord: 12000 // one calm album-cover rotation
    readonly property int easingEnter: Easing.OutCubic
    readonly property int easingExit: Easing.InCubic

    // How far a panel travels while it fades, in pixels. Small on purpose:
    // the grayscale look stays calm, the movement only signals direction.
    readonly property real lift: 10
    readonly property real slide: 26
}
