import QtQuick
import QtQuick.Controls

Column {
    id: root
    width: parent.width
    spacing: 10

    property string label: "color"
    property string settingsKey: ""
    property string defaultColor: "#ffffff"
    property color currentColor: "#ffffff"

    onCurrentColorChanged: {
        cp.selectedColor = currentColor;
    }

    Row {
        width: parent.width
        spacing: 15

        Text {
            text: root.label
            color: Settings.textPrimary
            font.pixelSize: 14
            width: 130
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 30
            height: 20
            radius: 4
            color: root.currentColor
            border.color: Settings.borderColor
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pickerContainer.visible = !pickerContainer.visible
            }
        }

        // Reset Button
        Rectangle {
            width: 40
            height: 22
            radius: 4
            color: resetMouse.containsMouse ? Settings.hoverLight : "transparent"
            border.color: Settings.borderColor
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "reset"
                font.pixelSize: 10
                font.bold: true
                color: Settings.textSecondary
                anchors.centerIn: parent
            }
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var lastDot = root.settingsKey.lastIndexOf(".");
                    if (lastDot !== -1) {
                        var section = root.settingsKey.substring(0, lastDot);
                        var key = root.settingsKey.substring(lastDot + 1);
                        Settings.setValue(section, key, root.defaultColor, false);
                    }
                }
            }
        }
    }

    Item {
        id: pickerContainer
        width: parent.width
        height: visible ? 150 : 0
        visible: false
        Behavior on height { enabled: Settings.animationEnabled; NumberAnimation { duration: 150 } }
        clip: true

        Row {
            anchors.fill: parent
            anchors.leftMargin: 145
            spacing: 10

            ColorPicker {
                id: cp
                width: 150
                height: 140
                onColorChanged: function(newColor) {
                    var lastDot = root.settingsKey.lastIndexOf(".");
                    if (lastDot !== -1) {
                        var section = root.settingsKey.substring(0, lastDot);
                        var key = root.settingsKey.substring(lastDot + 1);
                        Settings.setValue(section, key, newColor.toString(), true);
                    }
                }
                onColorSettled: function(newColor) {
                    var lastDot = root.settingsKey.lastIndexOf(".");
                    if (lastDot !== -1) {
                        var section = root.settingsKey.substring(0, lastDot);
                        var key = root.settingsKey.substring(lastDot + 1);
                        Settings.setValue(section, key, newColor.toString(), false);
                    }
                }
            }
        }
    }
}
