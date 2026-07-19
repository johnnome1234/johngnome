import QtQuick
import Quickshell

ShellWindow {
    width: 400; height: 400
    color: "black"
    Component.onCompleted: {
        try {
            console.log("typeof Quickshell.execDetached = " + typeof Quickshell.execDetached);
            Quickshell.execDetached(["touch", "/tmp/execDetached_works"]);
        } catch (e) {
            console.log("Error: " + e);
        }
    }
}
