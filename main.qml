/* This file is generated and only relevant for integrating the project into a Qt 6 and cmake based
C++ project. */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.settings 1.0
import content

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 800
    minimumWidth: 960
    minimumHeight: 640

    Material.theme: Material.Dark
    Material.accent: "#35c7e4"
    Material.primary: "#102636"
    palette.window: "#0b1520"
    palette.windowText: "#e3edf5"
    palette.base: "#08121b"
    palette.text: "#e3edf5"
    palette.button: "#15394d"
    palette.buttonText: "#e4edf5"
    palette.highlight: "#0d5a70"
    palette.highlightedText: "#ffffff"
    // Merken der bereits erstellten Oberflächen
    property var sessionViews: []
    property var activeView: null
    property int pendingCloseIndex: -1
    property bool favoritesValid: true
    property string favoritesError: ""

    Settings {
        id: favoritesSettings

        fileName: settingsFile
        category: "Login"

        property string favoritesJson: "[]"
        property string lastSelectedFavoriteIp: ""
    }

    ListModel {
        id: favoritesModel
    }

    component TabStripButton : Button {
        id: stripButton

        implicitWidth: Math.max(25, contentItem.implicitWidth + 18)
        implicitHeight: 40
        leftPadding: 0
        rightPadding: 0

        contentItem: Text {
            text: stripButton.text
            color: stripButton.enabled ? "#e4edf5" : "#82909d"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        background: Rectangle {
            radius: 5
            color: stripButton.down ? "#0d5a70"
                  : stripButton.hovered ? "#1b4c61"
                  : "#15394d"
            border.color: "#29485b"
            border.width: 1
        }
    }

    function updateActiveView() {
        activeView = sessionViews[sessionManager.activeIndex] ?? null
    }

    function loadFavorites() {
        try {
            const favorites = JSON.parse(favoritesSettings.favoritesJson)

            if (!Array.isArray(favorites))
                throw new Error("Favoriten müssen eine Liste sein")

            for (let i = 0; i < favorites.length; i++) {
                const favorite = favorites[i]

                if (!favorite || typeof favorite.name !== "string"
                              || typeof favorite.ip !== "string"
                              || typeof favorite.username !== "string") {
                    throw new Error("Ungültiger Favorit an Position " + i)
                }

                favoritesModel.append({
                    name: favorite.name,
                    displayName: favorite.name.length > 0
                                 ? favorite.name : favorite.ip,
                    ip: favorite.ip,
                    username: favorite.username
                })
            }
        } catch (error) {
            favoritesModel.clear()
            favoritesValid = false
            favoritesError = "Favoriten konnten nicht geladen werden. "
                             + "Bitte settings.ini überprüfen!"
            console.error("Fehler beim Laden der Favoriten:", error)
        }
    }

    function syncSessionViews() {
        const sessions = sessionManager.sessions
        const oldViews = sessionViews.slice()
        const updatedViews = []

        for (let i = 0; i < sessions.length; ++i) {
            let view = null
            
            for (let j = 0; j < oldViews.length; ++j) {
                if (oldViews[j].appController === sessions[i]) {
                    view = oldViews.splice(j, 1)[0]
                    break
                }
            }

            if (view === null) {
                view = sessionViewComponent.createObject(sessionContainer, {
                    "appController": sessions[i],
                    "favoritesModel": favoritesModel,
                    "favoritesSettings": favoritesSettings,
                    "favoritesValid": favoritesValid,
                    "favoritesError": favoritesError
                })

                if (view === null) {
                    console.error("Sitzungsoberfläche konnte nicht erstellt werden")
                    return
                }
            }

            updatedViews.push(view)
        }

        for (const oldView of oldViews){
            oldView.destroy()
        }

        sessionViews = updatedViews
        updateActiveView()
    }

    function requestCloseSession(index, controller) {
        if (sessionManager.sessions.length <= 1) {
            return
        }

        if (controller.loggedIn) {
            pendingCloseIndex = index
            closeSessionDialog.open()
        } else {
            sessionManager.removeSession(index)
        }
    }

Component.onCompleted: {
    loadFavorites()
    syncSessionViews()
}

Connections {
    target: sessionManager

    function onSessionsChanged(){
        syncSessionViews()
    }

    function onActiveSessionChanged(){
        updateActiveView()
    }
}

Component {
    id: sessionViewComponent

    App {
        anchors.fill: parent
        anchors.topMargin: 8
        visible: appController === sessionManager.activeController
    }
}

ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        color: "#102636"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4
            
            ColumnLayout {
                Layout.rightMargin: 16
                spacing: 1

                Text { 
                    text: "ScriptExecutorApp"; 
                    color: "#e8f0f7"; 
                    font.pixelSize: 19; 
                    font.bold: true 
                }

                Text { 
                    text: "Verwalten. Automatisieren. Entlasten."; 
                    color: "#9bb0c0"; 
                    font.pixelSize: 11 
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 4

                TabStripButton {
                    text: "<"
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: tabList.height
                    visible: tabList.contentWidth > tabList.width
                    enabled: !tabList.atXBeginning
                    onClicked: tabList.scrollToIndex(tabList.firstVisibleIndex() - 4)
                }

                ListView {
                    id: tabList

                    readonly property int tabWidth: 145
                    readonly property int tabStep: tabWidth + spacing
                    readonly property int visibleCount: Math.max(1, Math.floor((width + spacing) / tabStep))

                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter

                    orientation: ListView.Horizontal
                    spacing: 4
                    clip: true
                    interactive: false
                    model: sessionManager.sessions
                    footer: Item {
                        width: tabList.spacing + 30
                        height: tabList.height

                        TabStripButton {
                            x: tabList.spacing
                            width: 30
                            height: parent.height
                            text: "+"
                            onClicked: sessionManager.addSession()
                        }
                    }

                    function firstVisibleIndex() {
                        return Math.round(contentX / tabStep)
                    }

                    function scrollToIndex(index) {
                        const clamped = Math.max(0, Math.min(index, count - 1))
                        const maxX = Math.max(0, contentWidth - width)
                        scrollAnimation.to = Math.min(clamped * tabStep, maxX)
                        scrollAnimation.restart()
                    }

                    function ensureVisible(index) {
                        const first = firstVisibleIndex()
                        if (index < first)
                            scrollToIndex(index)
                        else if (index >= first + visibleCount)
                            scrollToIndex(index - visibleCount + 1)
                    }

                    NumberAnimation {
                        id: scrollAnimation
                        target: tabList
                        property: "contentX"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                    Connections {
                        target: sessionManager
                        function onActiveSessionChanged() {
                            Qt.callLater(tabList.ensureVisible, sessionManager.activeIndex)
                        }
                    }

                    delegate: Button {
                        id: tabButton
                        required property int index
                        required property var modelData

                        width: tabList.tabWidth
                        height: tabList.height
                        leftPadding: 0
                        rightPadding: 0
                        text: modelData.serverName.length > 0
                              ? modelData.serverName
                              : "Neue Verbindung"
                        highlighted: index === sessionManager.activeIndex
                        Accessible.name: text +
                                         (root.sessionViews[index] &&
                                          root.sessionViews[index].hasUnseenCommandResult
                                              ? ", Befehl abgeschlossen"
                                              : "")
                        onClicked: sessionManager.setActiveIndex(index)

                        contentItem: Item {
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 5
                                anchors.right: tabBusyIndicator.running
                                               ? tabBusyIndicator.left : closeLabel.left
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButton.text
                                color: tabButton.enabled ? "#e4edf5" : "#82909d"
                                font.pixelSize: tabButton.modelData.serverName.length > 0 ? 14 : 13
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: notificationDot
                                anchors.right: closeLabel.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: "#35c7e4"
                                visible: !tabBusyIndicator.running &&
                                         index !== sessionManager.activeIndex &&
                                         root.sessionViews[index] &&
                                         root.sessionViews[index].hasUnseenCommandResult

                                ToolTip.visible: visible && tabButton.hovered
                                ToolTip.text: "Befehl auf diesem Server abgeschlossen"
                            }

                            BusyIndicator {
                                id: tabBusyIndicator
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: closeLabel.left
                                anchors.rightMargin: 2
                                z: 1
                                width: 24
                                height: 24
                                running: Boolean(root.sessionViews[index] &&
                                                 root.sessionViews[index].commandRunning)
                                visible: running
                                Material.accent: "#35c7e4"
                            }

                            Text {
                                id: closeLabel
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                text: "x"
                                color: closeArea.enabled ? "#ef4444" : "#82909d"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                Accessible.name: "Server-Tab schließen"

                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: sessionManager.sessions.length > 1
                                             && !(root.sessionViews[tabButton.index]
                                                  && root.sessionViews[tabButton.index].commandRunning)
                                    onClicked: root.requestCloseSession(tabButton.index,
                                                                        tabButton.modelData)
                                }
                            }
                        }

                        background: Rectangle {
                            radius: 5
                            color: tabButton.down ? "#0d5a70"
                                  : tabButton.highlighted ? "#0d5a70"
                                  : tabButton.hovered ? "#1b4c61"
                                  : "#15394d"
                            border.color: tabButton.highlighted
                                          ? "#34bfd4" : "#29485b"
                            border.width: 1
                        }
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (event) => {
                            const delta = event.angleDelta.y !== 0
                                          ? event.angleDelta.y
                                          : event.angleDelta.x
                            tabList.scrollToIndex(tabList.firstVisibleIndex() + (delta > 0 ? -1 : 1))
                        }
                    }
                }

                TabStripButton {
                    text: ">"
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: tabList.height
                    visible: tabList.contentWidth > tabList.width
                    enabled: !tabList.atXEnd
                    onClicked: tabList.scrollToIndex(tabList.firstVisibleIndex() + 4)
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Text {
                    visible: sessionManager.activeController !== null
                    text: sessionManager.activeController
                          ? sessionManager.activeController.serverAddress
                          : ""
                    color: "#d7e2eb"
                }

                Rectangle {
                    visible: sessionManager.activeController !== null
                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9
                    radius: 5
                    color: sessionManager.activeController
                           && sessionManager.activeController.loggedIn
                           ? "#22c55e" : "#ef4444"
                }

                Text {
                    visible: sessionManager.activeController !== null
                    text: sessionManager.activeController
                          && sessionManager.activeController.loggedIn
                          ? "Eingeloggt"
                          : "Ausgeloggt"
                    color: "#d7e2eb"
                }

                TabStripButton {
                    Layout.preferredHeight: tabList.height
                    visible: sessionManager.activeController !== null
                             && sessionManager.activeController.loggedIn
                    text: "Ausloggen"
                    enabled: !(root.activeView
                               && root.activeView.commandRunning)
                    onClicked: sessionManager.activeController.attemptLogout()
                }
            }
        }
    }

    Rectangle {
        id: sessionContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#0b1520"
    }
    }

    Dialog {
        id: closeSessionDialog
        anchors.centerIn: Overlay.overlay
        width: 420
        modal: true
        title: "Server Tab schließen?"
        standardButtons: Dialog.Yes | Dialog.No

        Material.theme: Material.Dark
        Material.background: "#101f2c"
        Material.foreground: "#e3edf5"
        Material.primary: "#102636"
        Material.accent: "#35c7e4"

        closePolicy: Popup.CloseOnEscape
        
        background: Rectangle {
            color: "#101f2c"
            radius: 10
            border.color: "#294354"
        }

        contentItem: Label {
            text: root.pendingCloseIndex >= 0
                  && root.pendingCloseIndex < sessionManager.sessions.length
                  ? "Die Verbindung zu "
                    + sessionManager.sessions[root.pendingCloseIndex].serverAddress
                    + " wird getrennt. Tab schließen?"
                  : "Die Verbindung wird getrennt. Tab schließen?"
            color: "#e3edf5"
            font.pixelSize: 14
            wrapMode: Text.Wrap
        }

        onAccepted: {
            if (root.pendingCloseIndex >= 0) {
                sessionManager.removeSession(root.pendingCloseIndex)
            }

            root.pendingCloseIndex = -1
        }

        onRejected: {
            root.pendingCloseIndex = -1
        }
    }
}
