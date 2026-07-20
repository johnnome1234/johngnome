import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Item {
    id: settingsPopup
    
    anchors.fill: parent
    
    visible: isOpen || settingsRect.opacity > 0.01

    property bool isOpen: false
    signal closeRequested()

    property int initCornerRadius: 27
    property int initBarHeight: 70
    property bool initAnimationEnabled: true
    property string initMediaPet: "cat"
    property bool initAutoScale: false
    property bool settingsSaved: false

    onIsOpenChanged: {
        if (isOpen) {
            initCornerRadius = Settings.cornerRadius;
            initBarHeight = Settings.barHeight;
            initAnimationEnabled = Settings.animationEnabled;
            initMediaPet = Settings.mediaPet;
            initAutoScale = Settings.autoScale;
            settingsSaved = false;
        } else {
            if (!settingsSaved) {
                // Revert without writing to disk
                Settings.setValue("shell", "corner_radius", initCornerRadius, true);
                Settings.setValue("shell", "bar_height", initBarHeight, true);
                Settings.setValue("shell.animation", "enabled", initAnimationEnabled, true);
                Settings.setValue("widgets.media", "pet", initMediaPet, true);
                Settings.setValue("shell", "auto_scale", initAutoScale, true);
            }
        }
    }

    Process {
        id: saveProcess
    }

    Process {
        id: depsProcess
        command: ["python", Qt.resolvedUrl("check_deps.py").toString().replace("file://", "")]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "") {
                    depsText.text = data.trim();
                }
            }
        }
    }

    Process {
        id: resetProcess
        command: ["python", Qt.resolvedUrl("save_config.py").toString().replace("file://", ""), "shell", "corner_radius", "27", "shell", "bar_height", "70", "shell.animation", "enabled", "true"]
    }

    function resetToDefaults() {
        // Run a single python process to write all values at once to avoid race conditions
        resetProcess.running = true;
        // Update local QML state instantly so sliders snap visually (skip separate python processes)
        Settings.setValue("shell", "corner_radius", 27, true);
        Settings.setValue("shell", "bar_height", 70, true);
        Settings.setValue("shell.animation", "enabled", true, true);
    }

    Rectangle {
        anchors.fill: parent
        color: "#80000000"
        opacity: isOpen ? 1.0 : 0.0
        Behavior on opacity { enabled: Settings.animationEnabled; NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            onClicked: closeRequested()
        }
    }

    Rectangle {
        id: settingsRect
        width: 650
        height: 420
        anchors.centerIn: parent
        radius: Settings.cornerRadius
        color: Settings.backgroundColor
        border.color: Settings.borderColor
        border.width: 1
        opacity: isOpen ? 1.0 : 0.0
        scale: isOpen ? 1.0 : 0.95
        Behavior on opacity { enabled: Settings.animationEnabled; NumberAnimation { duration: 200 } }
        Behavior on scale { enabled: Settings.animationEnabled; NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Row {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 25

            // Sidebar Bookmarks
            Rectangle {
                width: 150
                height: parent.height
                color: "transparent"
                border.color: Settings.borderColor
                border.width: 1
                radius: 8

                Column {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "bookmarks"
                        color: Settings.textSecondary
                        font.bold: true
                        font.pixelSize: 12
                        font.family: Settings.fontFamily
                        padding: 5
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 6
                        color: appearanceMouse.containsMouse ? Settings.hoverLight : "transparent"
                        Text {
                            text: "appearance"
                            color: Settings.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }
                        MouseArea {
                            id: appearanceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flickable.contentY = 0
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 6
                        color: animMouse.containsMouse ? Settings.hoverLight : "transparent"
                        Text {
                            text: "behavior"
                            color: Settings.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }
                        MouseArea {
                            id: animMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flickable.contentY = Math.max(0, animSection.y - 10)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 6
                        color: depsMouse.containsMouse ? Settings.hoverLight : "transparent"
                        Text {
                            text: "dependencies"
                            color: Settings.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                        }
                        MouseArea {
                            id: depsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flickable.contentY = Math.max(0, depsSection.y - 10)
                        }
                    }
                }
                    
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    height: 30
                    radius: 6
                    color: resetMouse.containsMouse ? Settings.errorColor : "transparent"
                    border.color: Settings.errorColor
                    border.width: 1
                    Text {
                        text: "reset all"
                        color: resetMouse.containsMouse ? "#ffffff" : Settings.errorColor
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resetToDefaults()
                    }
                }
            }

            // Main Content Area
            Flickable {
                id: flickable
                width: parent.width - 175
                height: parent.height
                contentWidth: width
                contentHeight: settingsCol.height + 40
                clip: true
                Behavior on contentY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Column {
                    id: settingsCol
                    width: parent.width
                    spacing: 40
                    anchors.top: parent.top
                    anchors.topMargin: 10

                    // APPEARANCE SECTION
                    Column {
                        id: appearanceSection
                        width: parent.width
                        spacing: 20

                        Text {
                            text: "appearance"
                            color: Settings.accentColor
                            font.bold: true
                            font.pixelSize: 18
                        }

                        ColorPickerRow {
                            label: "bar color"
                            settingsKey: Settings.isDarkMode ? "theme.colors.background_dark" : "theme.colors.background"
                            defaultColor: Settings.isDarkMode ? "#2d2722" : "#e6dcce"
                            currentColor: Settings.backgroundColor
                        }

                        ColorPickerRow {
                            label: "container color"
                            settingsKey: Settings.isDarkMode ? "theme.colors.surface_dark" : "theme.colors.surface"
                            defaultColor: Settings.isDarkMode ? "#3d352d" : "#d4c4b0"
                            currentColor: Settings.surfaceColor
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "corner rounding"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // Slider
                            Item {
                                width: parent.width - 275
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Rectangle {
                                    id: crTrack
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Settings.hoverLight
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Rectangle {
                                        width: (Settings.cornerRadius / 50) * parent.width
                                        height: 4
                                        radius: 2
                                        color: Settings.accentColor
                                    }
                                }
                                
                                Rectangle {
                                    x: (Settings.cornerRadius / 50) * (parent.width - width)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Settings.textPrimary
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                            var val = Math.round(ratio * 50);
                                            Settings.setValue("shell", "corner_radius", val, true);
                                        }
                                    }
                                    onReleased: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 50);
                                        Settings.setValue("shell", "corner_radius", val, true);
                                    }
                                    onClicked: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 50);
                                        Settings.setValue("shell", "corner_radius", val, true);
                                    }
                                }
                            }
                            
                            Text {
                                text: Settings.cornerRadius + "px"
                                color: Settings.textSecondary
                                font.pixelSize: 12
                                width: 35
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetCrMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetCrMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("shell", "corner_radius", 27, true)
                                }
                            }
                        }
                        
                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "top bar height"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            // Slider
                            Item {
                                width: parent.width - 275
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Rectangle {
                                    id: bhTrack
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Settings.hoverLight
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Rectangle {
                                        width: ((Settings.barHeight - 30) / 70) * parent.width
                                        height: 4
                                        radius: 2
                                        color: Settings.accentColor
                                    }
                                }
                                
                                Rectangle {
                                    x: ((Settings.barHeight - 30) / 70) * (parent.width - width)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Settings.textPrimary
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                            var val = Math.round(30 + ratio * 70);
                                            Settings.setValue("shell", "bar_height", val, true);
                                        }
                                    }
                                    onReleased: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(30 + ratio * 70);
                                        Settings.setValue("shell", "bar_height", val, true);
                                    }
                                    onClicked: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(30 + ratio * 70);
                                        Settings.setValue("shell", "bar_height", val, true);
                                    }
                                }
                            }
                            
                            Text {
                                text: Settings.barHeight + "px"
                                color: Settings.textSecondary
                                font.pixelSize: 12
                                width: 35
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetBhMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetBhMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("shell", "bar_height", 70, true)
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "exclusive zone"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Slider
                            Item {
                                width: parent.width - 275
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    id: ezTrack
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Settings.hoverLight
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: (Settings.exclusiveZone / 100) * parent.width
                                        height: 4
                                        radius: 2
                                        color: Settings.accentColor
                                    }
                                }

                                Rectangle {
                                    x: (Settings.exclusiveZone / 100) * (parent.width - width)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Settings.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                            var val = Math.round(ratio * 100);
                                            Settings.setValue("shell", "exclusive_zone", val, true);
                                        }
                                    }
                                    onReleased: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 100);
                                        Settings.setValue("shell", "exclusive_zone", val, true);
                                    }
                                    onClicked: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 100);
                                        Settings.setValue("shell", "exclusive_zone", val, true);
                                    }
                                }
                            }

                            Text {
                                text: Settings.exclusiveZone + "px"
                                color: Settings.textSecondary
                                font.pixelSize: 12
                                width: 35
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetEzMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetEzMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("shell", "exclusive_zone", 45, true)
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "transparency"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Item {
                                width: parent.width - 275
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    id: opTrack
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Settings.hoverLight
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: (Settings.barOpacity / 100) * parent.width
                                        height: 4
                                        radius: 2
                                        color: Settings.accentColor
                                    }
                                }

                                Rectangle {
                                    x: (Settings.barOpacity / 100) * (parent.width - width)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Settings.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -10
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                            var val = Math.round(ratio * 100);
                                            Settings.setValue("shell", "bar_opacity", val, true);
                                        }
                                    }
                                    onReleased: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 100);
                                        Settings.setValue("shell", "bar_opacity", val, true);
                                    }
                                    onClicked: function(mouse) {
                                        var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        var val = Math.round(ratio * 100);
                                        Settings.setValue("shell", "bar_opacity", val, true);
                                    }
                                }
                            }
                            Text {
                                text: Settings.barOpacity + "%"
                                color: Settings.textSecondary
                                font.pixelSize: 12
                                width: 35
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetOpMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetOpMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("shell", "bar_opacity", 100, true)
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "auto scale UI"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: Settings.autoScale ? Settings.accentColor : Settings.hoverLight
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Settings.autoScale ? 23 : 3
                                    Behavior on x { enabled: Settings.animationEnabled; NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.setValue("shell", "auto_scale", !Settings.autoScale, true);
                                    }
                                }
                            }

                            Text {
                                text: "(requires quickshell restart)"
                                color: Settings.textSecondary
                                font.pixelSize: 10
                                opacity: 0.6
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Item {
                                width: parent.width - 340 // Spacer
                                height: 1
                            }
                        }
                    }

                    // BEHAVIOR SECTION
                    Column {
                        id: animSection
                        width: parent.width
                        spacing: 20

                        Text {
                            text: "behavior"
                            color: Settings.accentColor
                            font.bold: true
                            font.pixelSize: 18
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "animations"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: Settings.animationEnabled ? Settings.accentColor : Settings.hoverLight
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Settings.animationEnabled ? 23 : 3
                                    Behavior on x { enabled: Settings.animationEnabled; NumberAnimation { duration: 150 } }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.setValue("shell.animation", "enabled", !Settings.animationEnabled, true);
                                    }
                                }
                            }

                            Item {
                                width: parent.width - 275 // Spacer
                                height: 1
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetAnimMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetAnimMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("shell.animation", "enabled", true, true)
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 15
                            Text {
                                text: "alien pet"
                                color: Settings.textPrimary
                                font.pixelSize: 14
                                width: 130
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: Settings.mediaPet === "alien" ? Settings.accentColor : Settings.hoverLight
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Settings.mediaPet === "alien" ? 23 : 3
                                    Behavior on x { enabled: Settings.animationEnabled; NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.setValue("widgets.media", "pet", Settings.mediaPet === "alien" ? "cat" : "alien", true);
                                    }
                                }
                            }

                            Item {
                                width: parent.width - 275 // Spacer
                                height: 1
                            }

                            // Reset Button
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 4
                                color: resetPetMouse.containsMouse ? Settings.hoverLight : "transparent"
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
                                    id: resetPetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.setValue("widgets.media", "pet", "cat", true)
                                }
                            }
                        }
                    }

                    // DEPENDENCIES SECTION
                    Column {
                        id: depsSection
                        width: parent.width
                        spacing: 20

                        Text {
                            text: "dependencies"
                            color: Settings.accentColor
                            font.bold: true
                            font.pixelSize: 18
                        }

                        Rectangle {
                            width: 120
                            height: 28
                            radius: 14
                            color: detectMouse.containsMouse ? Settings.hoverLight : "transparent"
                            border.color: Settings.accentColor
                            border.width: 1
                            Text {
                                text: "detect"
                                color: Settings.accentColor
                                font.bold: true
                                font.pixelSize: 12
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                id: detectMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: depsProcess.running = true
                            }
                        }

                        Text {
                            id: depsText
                            text: "click detect to check missing packages (note: python3 must be installed for this button to work)"
                            color: Settings.textSecondary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            width: parent.width
                            opacity: 0.6
                        }
                    }
                }
            }
        }
        Rectangle {
            id: okButton
            width: 80
            height: 32
            radius: 8
            color: okMouse.containsMouse ? Settings.hoverLight : "transparent"
            border.color: Settings.accentColor
            border.width: 1
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 20
            
            Text {
                text: "ok"
                color: Settings.accentColor
                font.bold: true
                font.pixelSize: 14
                font.family: Settings.fontFamily
                anchors.centerIn: parent
            }

            Behavior on color { enabled: Settings.animationEnabled; ColorAnimation { duration: 150 } }

            MouseArea {
                id: okMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    settingsSaved = true;
                    saveProcess.command = [
                        "python", Qt.resolvedUrl("save_config.py").toString().replace("file://", ""),
                        "shell", "corner_radius", Settings.cornerRadius.toString(),
                        "shell", "bar_height", Settings.barHeight.toString(),
                        "shell.animation", "enabled", Settings.animationEnabled ? "true" : "false",
                        "widgets.media", "pet", Settings.mediaPet,
                        "shell", "auto_scale", Settings.autoScale ? "true" : "false"
                    ];
                    saveProcess.running = true;
                    closeRequested();
                }
            }
        }
    }
}
