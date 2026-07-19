pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var _settingsObj: ({})

    property string internalConfigText: ""

    FileView {
        id: configFile
        path: Qt.resolvedUrl("config.toml").toString().replace("file:// ", "")
        onTextChanged: {
            var val = typeof configFile.text === "function" ? configFile.text() : configFile.text;
            root.internalConfigText = val;
            root.parseToml(val);
        }
    }

    function parseToml(tomlString) {
        if (!tomlString) return;
        var lines = tomlString.split("\n");
        var obj = {};
        var currentSection = obj;
        var currentSectionPath = "";

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            // skip comments and empty lines
            if (line.length === 0 || line.startsWith("#")) continue;

            // match section header
            var sectionMatch = line.match(/^\[(.*)\]$/);
            if (sectionMatch) {
                currentSectionPath = sectionMatch[1];
                var parts = currentSectionPath.split(".");
                var cur = obj;
                for (var j = 0; j < parts.length; j++) {
                    if (!cur[parts[j]]) {
                        cur[parts[j]] = {};
                    }
                    cur = cur[parts[j]];
                }
                currentSection = cur;
                continue;
            }

            // match key value
            var kvMatch = line.match(/^([a-zA-Z0-9_-]+)\s*=\s*(.*)$/);
            if (kvMatch) {
                var key = kvMatch[1].trim();
                var valStr = kvMatch[2].trim();
                // strip comments
                if (valStr.indexOf("#") !== -1 && !valStr.startsWith("\"")) {
                    var quoteIndex = valStr.indexOf("\"");
                    if (quoteIndex === -1) {
                         valStr = valStr.substring(0, valStr.indexOf("#")).trim();
                    } else {
                        // handle quotes
                        var lastQuote = valStr.lastIndexOf("\"");
                        if (valStr.indexOf("#", lastQuote) !== -1) {
                            valStr = valStr.substring(0, valStr.indexOf("#", lastQuote)).trim();
                        }
                    }
                }

                var val;
                if (valStr === "true") val = true;
                else if (valStr === "false") val = false;
                else if (valStr.startsWith("\"") && valStr.endsWith("\"")) {
                    val = valStr.substring(1, valStr.length - 1);
                } else if (!isNaN(Number(valStr))) {
                    val = Number(valStr);
                } else {
                    val = valStr; // fallback string
                }
                currentSection[key] = val;
            }
        }
        _settingsObj = obj;
        isDarkMode = (_get("theme.mode", "light") === "dark");
    }

    function setValue(sectionPath, key, value, skipDisk) {
        if (!root.internalConfigText) {
            root.internalConfigText = typeof configFile.text === "function" ? configFile.text() : configFile.text;
        }
        var currentText = root.internalConfigText;
        if (!currentText) return;

        var lines = currentText.split("\n");
        var inTargetSection = false;
        var keyFound = false;
        
        var valStr = value;
        if (typeof value === "string") valStr = '"' + value + '"';
        else if (typeof value === "boolean") valStr = value ? "true" : "false";
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.startsWith("[")) {
                var sectionMatch = line.match(/^\[(.*)\]$/);
                if (sectionMatch) {
                    if (inTargetSection && !keyFound) {
                        lines.splice(i, 0, key + " = " + valStr);
                        keyFound = true;
                        break;
                    }
                    inTargetSection = (sectionMatch[1] === sectionPath);
                }
            } else if (inTargetSection) {
                var kvMatch = line.match(/^([a-zA-Z0-9_-]+)\s*=\s*(.*)$/);
                if (kvMatch && kvMatch[1].trim() === key) {
                    var comment = "";
                    var existingVal = kvMatch[2].trim();
                    if (existingVal.indexOf("#") !== -1 && !existingVal.startsWith("\"")) {
                        comment = existingVal.substring(existingVal.indexOf("#"));
                    } else if (existingVal.startsWith("\"")) {
                        var lastQuote = existingVal.lastIndexOf("\"");
                        if (existingVal.indexOf("#", lastQuote) !== -1) {
                            comment = existingVal.substring(existingVal.indexOf("#", lastQuote));
                        }
                    }
                    
                    var indent = lines[i].substring(0, lines[i].indexOf(kvMatch[1]));
                    lines[i] = indent + key + " = " + valStr + (comment ? " " + comment : "");
                    keyFound = true;
                    break;
                }
            }
        }
        
        if (!keyFound) {
            if (!inTargetSection) {
                lines.push("");
                lines.push("[" + sectionPath + "]");
            }
            lines.push(key + " = " + valStr);
        }
        
        // Instead of writing to FileView, we use our python script to persist.
        // We still parse the TOML to update internal QML state instantly.
        var newText = lines.join("\n");
        root.internalConfigText = newText;
        parseToml(newText);

        if (skipDisk !== true) {
            configSaverProcess.section = sectionPath;
            configSaverProcess.key = key;
            configSaverProcess.val = valStr;
            configSaverProcess.running = true;
        }
    }

    Process {
        id: configSaverProcess
        property string section
        property string key
        property string val
        command: ["python", Qt.resolvedUrl("save_config.py").toString().replace("file://", ""), section, key, val]
    }

    function setDarkMode(dark) {
        setValue("theme", "mode", dark ? "dark" : "light");
    }

    function _get(path, defaultVal) {
        var parts = path.split(".");
        var cur = _settingsObj;
        for (var i = 0; i < parts.length; i++) {
            if (cur === undefined || cur === null) return defaultVal;
            cur = cur[parts[i]];
        }
        return (cur !== undefined && cur !== null) ? cur : defaultVal;
    }

    // exposed properties

    property bool isDarkMode: false

    // theme colors
    property string backgroundColor: isDarkMode ? _get("theme.colors.background_dark", "#2d2722") : _get("theme.colors.background", "#e6dcce")
    property string backgroundDark: isDarkMode ? _get("theme.colors.background", "#e6dcce") : _get("theme.colors.background_dark", "#2d2722")
    property string borderColor: isDarkMode ? "#4d4239" : _get("theme.colors.border", "#cbbda8")
    property string accentColor: _get("theme.colors.accent", "#a05e26")
    property string textPrimary: isDarkMode ? "#f5e0c3" : _get("theme.colors.text_primary", "#2d2722")
    property string textSecondary: isDarkMode ? "#a0988e" : _get("theme.colors.text_secondary", "#8a7e72")
    property string textOnDark: isDarkMode ? "#2d2722" : _get("theme.colors.text_on_dark", "#f5e0c3")
    property string surfaceColor: isDarkMode ? "#3d352d" : _get("theme.colors.surface", "#d4c4b0")
    property string hoverColor: isDarkMode ? "#24ffffff" : _get("theme.colors.hover", "#24000000")
    property string hoverLight: isDarkMode ? "#12ffffff" : _get("theme.colors.hover_light", "#12000000")
    property string errorColor: _get("theme.colors.error", "#c04040")
    property string activeAccent: _get("theme.colors.active_accent", "#e0af68")
    property string notificationBadge: _get("theme.colors.notification_badge", "#d04040")

    // shell
    readonly property real uiScale: _get("shell.ui_scale", 1.0)
    readonly property int cornerRadius: _get("shell.corner_radius", 16)
    readonly property string fontFamily: _get("shell.font_family", "sans-serif")
    readonly property int exclusiveZone: _get("shell.exclusive_zone", 45)
    readonly property int barHeight: _get("shell.bar_height", 70)

    // animation
    readonly property bool animationEnabled: _get("shell.animation.enabled", true)
    readonly property real animationSpeed: _get("shell.animation.speed", 1.0)

    // weather
    readonly property real weatherLatitude: _get("widgets.weather.latitude", 0)
    readonly property real weatherLongitude: _get("widgets.weather.longitude", 0)
    readonly property string temperatureUnit: _get("widgets.weather.temperature_unit", "fahrenheit")
    readonly property int weatherInterval: _get("widgets.weather.update_interval", 1800000)

    // nightlight
    readonly property int nightlightTempHigh: _get("widgets.nightlight.temperature_high", 6500)
    readonly property int nightlightTempLow: _get("widgets.nightlight.temperature_low", 4000)

    // media
    readonly property string mediaPet: _get("widgets.media.pet", "cat")
}

