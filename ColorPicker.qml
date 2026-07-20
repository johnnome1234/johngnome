import QtQuick

Item {
    id: root
    width: 200
    height: 180

    property color selectedColor: "#ffffff"
    signal colorChanged(string newColor)
    signal colorSettled(string newColor)

    property real currentHue: 0.0
    property real currentSat: 1.0
    property real currentVal: 1.0

    onSelectedColorChanged: {
        // Only update sliders if we aren't actively dragging
        if (!svMouse.pressed && !hueMouse.pressed) {
            setFromHex(selectedColor.toString());
        }
    }

    function setFromHex(hex) {
        if (!hex) return;
        if (hex.startsWith("#")) hex = hex.substring(1);
        if (hex.length === 8) hex = hex.substring(2); // skip alpha for HSV
        if (hex.length === 3) hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
        if (hex.length !== 6) return;
        var r = parseInt(hex.substring(0,2), 16) / 255.0;
        var g = parseInt(hex.substring(2,4), 16) / 255.0;
        var b = parseInt(hex.substring(4,6), 16) / 255.0;
        var max = Math.max(r, g, b), min = Math.min(r, g, b);
        var h = 0, s = 0, v = max;
        var d = max - min;
        s = max === 0 ? 0 : d / max;
        if (max === min) {
            h = 0;
        } else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        currentHue = h;
        currentSat = s;
        currentVal = v;
    }

    function updateColor(settled) {
        var c = Qt.hsva(currentHue, currentSat, currentVal, 1.0);
        
        // Output standard #RRGGBB instead of #AARRGGBB since QML is weird with it
        var rHex = Math.round(c.r * 255).toString(16).padStart(2, '0');
        var gHex = Math.round(c.g * 255).toString(16).padStart(2, '0');
        var bHex = Math.round(c.b * 255).toString(16).padStart(2, '0');
        var hexColor = "#" + rHex + gHex + bHex;
        
        selectedColor = hexColor;
        colorChanged(hexColor);
        if (settled) {
            colorSettled(hexColor);
        }
    }

    // Color Box (Saturation and Value)
    Rectangle {
        id: svBox
        width: parent.width - 30
        height: parent.height
        color: Qt.hsva(currentHue, 1.0, 1.0, 1.0)
        
        // White to transparent (left to right)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
        
        // Transparent to black (top to bottom)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#ff000000" }
            }
        }

        Rectangle {
            id: svCursor
            width: 10
            height: 10
            radius: 5
            border.color: "white"
            border.width: 2
            color: "transparent"
            x: currentSat * svBox.width - width/2
            y: (1.0 - currentVal) * svBox.height - height/2
        }

        MouseArea {
            id: svMouse
            anchors.fill: parent
            function updateSV(mouse, settled) {
                currentSat = Math.max(0, Math.min(1, mouse.x / svBox.width));
                currentVal = 1.0 - Math.max(0, Math.min(1, mouse.y / svBox.height));
                updateColor(settled);
            }
            onPositionChanged: function(mouse) { if (pressed) updateSV(mouse, false); }
            onPressed: function(mouse) { updateSV(mouse, false); }
            onReleased: function(mouse) { updateSV(mouse, true); }
        }
    }

    // Hue Slider
    Rectangle {
        id: hueSlider
        width: 20
        height: parent.height
        anchors.right: parent.right
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff0000" }
            GradientStop { position: 0.166; color: "#ffff00" }
            GradientStop { position: 0.333; color: "#00ff00" }
            GradientStop { position: 0.5; color: "#00ffff" }
            GradientStop { position: 0.666; color: "#0000ff" }
            GradientStop { position: 0.833; color: "#ff00ff" }
            GradientStop { position: 1.0; color: "#ff0000" }
        }

        Rectangle {
            width: parent.width + 4
            height: 6
            x: -2
            y: currentHue * hueSlider.height - height/2
            border.color: "white"
            border.width: 1
            color: "black"
        }

        MouseArea {
            id: hueMouse
            anchors.fill: parent
            function updateHue(mouse, settled) {
                currentHue = Math.max(0, Math.min(1, mouse.y / hueSlider.height));
                updateColor(settled);
            }
            onPositionChanged: function(mouse) { if (pressed) updateHue(mouse, false); }
            onPressed: function(mouse) { updateHue(mouse, false); }
            onReleased: function(mouse) { updateHue(mouse, true); }
        }
    }
}
