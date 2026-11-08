pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// The bar glyph: the Proton mark, solid while protected and dimmed otherwise.
//   left click   open the panel
//   right click  connect to the fastest server, or disconnect
//   middle click force a status refresh
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0
    property bool open: false
    property real reveal: 0
    property bool tabActive: false
    signal requestClose()

    readonly property var vpn: pluginApi ? pluginApi.mainInstance : null
    readonly property bool protectedNow: vpn ? vpn.connected : false

    implicitWidth: icon.implicitWidth
    implicitHeight: Math.max(icon.implicitHeight, 18 * root.s)

    ProtonIcon {
        id: icon
        s: root.s
        anchors.verticalCenter: parent.verticalCenter
        iconSize: 16 * root.s
        color: root.protectedNow ? Theme.accent : Theme.dim
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (!root.pluginApi)
                return;
            if (mouse.button === Qt.RightButton) {
                if (root.vpn) root.vpn.toggle();
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.vpn) root.vpn.refresh();
            } else if (root.open) {
                root.requestClose();
            } else if (root.pluginApi.togglePanel) {
                root.pluginApi.togglePanel();
            }
        }
    }
}
