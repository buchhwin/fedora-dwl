import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var audioState
    property int tab: 0
    property var items: []
    property string status: ""
    property string pendingSsid: ""
    property bool wifiPowered: true
    property bool bluetoothPowered: false
    Theme { id: theme }

    function refresh() {
        if (tab === 0 && !wifiList.running) { wifiState.running = true; wifiList.running = true }
        else if (tab === 1 && !btList.running) { btState.running = true; btList.running = true }
        else if (tab === 2 && !audioList.running) audioList.running = true
    }
    function run(command, message) {
        status = message
        action.command = command
        action.running = true
    }
    onTabChanged: refresh()
    Component.onCompleted: refresh()

    Process { id: wifiState; command: ["nmcli", "-g", "WIFI", "general"]; stdout: StdioCollector { onStreamFinished: root.wifiPowered = text.trim() === "enabled" } }
    Process {
        id: wifiList
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector { onStreamFinished: {
            const found = [], seen = ({}), lines = text.split("\n")
            for (let i = 0; i < lines.length; i++) {
                const f = lines[i].split(":"); if (f.length < 4) continue
                const ssid = f[1].replace(/\\:/g, ":"); if (!ssid.length || seen[ssid]) continue
                seen[ssid] = true
                found.push({active:f[0] === "*", ssid:ssid, signal:parseInt(f[2]) || 0, security:f.slice(3).join(":")})
            }
            root.items = found
        } }
    }
    Process { id: btState; command: ["buchhwin-btctl", "status"]; stdout: StdioCollector { onStreamFinished: root.bluetoothPowered = text.split("|")[0] === "yes" } }
    Process { id: btList; command: ["buchhwin-btctl", "list"]; stdout: StdioCollector { onStreamFinished: {
        const found=[]; for (const line of text.split("\n")) { const f=line.split("|"); if(f.length >= 4) found.push({mac:f[0],name:f[1],paired:f[2]==="yes",connected:f[3]==="yes"}) } root.items=found
    } } }
    Process { id: audioList; command: ["buchhwin-audioctl", "sinks"]; stdout: StdioCollector { onStreamFinished: {
        const found=[]; for (const line of text.split("\n")) { const f=line.split("|"); if(f.length >= 5) found.push({name:f[0],description:f[1],volume:parseInt(f[2])||0,muted:f[3]==="yes",isDefault:f[4]==="yes"}) } root.items=found
    } } }
    Process { id: action; onExited: code => { root.status = code === 0 ? "Updated" : "Action failed"; refreshDelay.restart() } }
    Timer { id: refreshDelay; interval: 500; onTriggered: root.refresh() }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }

    ColumnLayout {
        anchors.fill: parent; spacing: 12
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: [["󰤨", "Wi-Fi"], ["󰂯", "Bluetooth"], ["󰕾", "Sound"]]
                delegate: Rectangle {
                    required property var modelData; required property int index
                    Layout.fillWidth: true; height: 48; radius: 9
                    color: root.tab === index ? theme.surface3 : theme.surface2
                    border.width: 1; border.color: root.tab === index ? theme.blue : theme.border
                    Row { anchors.centerIn: parent; spacing: 9
                        Text { text: modelData[0]; color: theme.blue; font.family: theme.font; font.pixelSize: 16 }
                        Text { text: modelData[1]; color: theme.text; font.family: theme.font; font.pixelSize: 13; font.bold: root.tab === index }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.tab=index; root.items=[] } }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.tab === 0 ? (root.wifiPowered ? "Available networks" : "Wi-Fi is off") : root.tab === 1 ? (root.bluetoothPowered ? "Nearby and paired devices" : "Bluetooth is off") : "Audio outputs"
                color: theme.text; font.family: theme.font; font.pixelSize: 14; font.bold: true
            }
            Rectangle {
                visible: root.tab < 2; width: 84; height: 32; radius: 7
                color: (root.tab === 0 ? root.wifiPowered : root.bluetoothPowered) ? theme.blue : theme.surface2
                Text { anchors.centerIn: parent; text: (root.tab === 0 ? root.wifiPowered : root.bluetoothPowered) ? "On" : "Off"; color: (root.tab === 0 ? root.wifiPowered : root.bluetoothPowered) ? theme.bg : theme.text; font.family: theme.font }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.run(root.tab === 0 ? ["nmcli","radio","wifi",root.wifiPowered?"off":"on"] : ["buchhwin-btctl","power",root.bluetoothPowered?"off":"on"], "Changing radio…") }
            }
            Rectangle {
                visible: root.tab === 1 && root.bluetoothPowered; width: 84; height: 32; radius: 7; color: theme.surface2; border.width: 1; border.color: theme.border
                Text { anchors.centerIn: parent; text: "Scan"; color: theme.text; font.family: theme.font }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.run(["buchhwin-btctl","scan","8"], "Scanning…") }
            }
        }

        Rectangle {
            visible: root.tab === 0 && root.pendingSsid.length > 0
            Layout.fillWidth: true; height: 52; radius: 8; color: theme.surface2; border.width: 1; border.color: theme.blue
            RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8
                Text { text: root.pendingSsid; color: theme.text; font.family: theme.font; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 34; color: theme.bg
                    TextInput { id: wifiPassword; anchors.fill: parent; anchors.margins: 8; echoMode: TextInput.Password; color: theme.text; font.family: theme.font }
                }
                Rectangle { width: 82; height: 34; radius: 6; color: theme.blue
                    Text { anchors.centerIn: parent; text: "Connect"; color: theme.bg; font.family: theme.font }
                    MouseArea { anchors.fill: parent; onClicked: { root.run(["nmcli","device","wifi","connect",root.pendingSsid,"password",wifiPassword.text], "Connecting…"); root.pendingSsid=""; wifiPassword.text="" } }
                }
            }
        }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 7
            model: root.items
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: root.tab === 2 ? 76 : 60; radius: 9
                color: theme.surface2; border.width: 1; border.color: (modelData.active || modelData.connected || modelData.isDefault) ? theme.blue : theme.border
                RowLayout { anchors.fill: parent; anchors.margins: 11; spacing: 10
                    Text { text: root.tab === 0 ? "󰤨" : root.tab === 1 ? "󰂯" : "󰕾"; color: theme.blue; font.family: theme.font; font.pixelSize: 16 }
                    ColumnLayout { Layout.fillWidth: true; spacing: 2
                        Text { Layout.fillWidth: true; text: root.tab === 0 ? modelData.ssid : root.tab === 1 ? modelData.name : modelData.description; color: theme.text; font.family: theme.font; font.pixelSize: 12; font.bold: modelData.active || modelData.connected || modelData.isDefault; elide: Text.ElideRight }
                        Text { text: root.tab === 0 ? modelData.signal + "%  " + (modelData.security || "Open") : root.tab === 1 ? (modelData.connected ? "Connected" : modelData.paired ? "Paired" : modelData.mac) : (modelData.muted ? "Muted" : modelData.volume + "%"); color: theme.subtext; font.family: theme.font; font.pixelSize: 9 }
                        ValueSlider { visible: root.tab === 2; Layout.fillWidth: true; from: 0; to: 150; value: root.tab === 2 ? modelData.volume : 0; onValueEdited: value => root.run(["buchhwin-audioctl","sink-volume",modelData.name,Math.round(value)+"%"], "Changing volume…") }
                    }
                    Rectangle { width: 92; height: 32; radius: 7; color: actionMouse.containsMouse ? theme.surface3 : theme.bg; border.width: 1; border.color: theme.border
                        Text { anchors.centerIn: parent; text: root.tab === 0 ? (modelData.active ? "Disconnect" : "Connect") : root.tab === 1 ? (modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair") : (modelData.isDefault ? "Default" : "Set default"); color: theme.text; font.family: theme.font; font.pixelSize: 9 }
                        MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: {
                            if (root.tab === 0) {
                                if (modelData.active) root.run(["nmcli","connection","down","id",modelData.ssid], "Disconnecting…")
                                else if (!modelData.security || modelData.security === "--") root.run(["nmcli","device","wifi","connect",modelData.ssid], "Connecting…")
                                else { root.pendingSsid=modelData.ssid; wifiPassword.forceActiveFocus() }
                            } else if (root.tab === 1) root.run(["buchhwin-btctl",modelData.connected?"disconnect":modelData.paired?"connect":"pair",modelData.mac], "Updating device…")
                            else if (!modelData.isDefault) root.run(["buchhwin-audioctl","default-sink",modelData.name], "Changing output…")
                        } }
                    }
                }
            }
        }
        Text { Layout.fillWidth: true; text: root.status; color: theme.blue; font.family: theme.font; font.pixelSize: 10 }
    }
}
