import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Particles
import org.kde.kwin

ApplicationWindow {
    property var overrides: {}
    property var currentOverrides: {}
    property var currentApplications: []
    property var currentWindows: []
    property var defaultConfig: {}
    property var currentApplicationIndex: -1
    property var currentWindowIndex: -1

    id: mainMenuRoot
    width: 1000
    height: 700
    title: "Remember Window Positions - Per Application/Window Configuration"

    function initMainMenu() {
        currentOverrides = JSON.parse(JSON.stringify(overrides));
        currentApplicationIndex = -1;
        currentWindowIndex = -1;
        initApplications();
        initWindows();
        updateCurrentData();
    }

    function initApplications() {
        currentApplications = [];
        for (let key in currentOverrides) {
            currentApplications.push(key);
        }
        currentApplications.sort();
        applicationList.model = currentApplications;
    }

    function initWindows() {
        currentWindows = [];
        if (currentApplicationIndex >= 0) {
            let application = currentOverrides[currentApplications[currentApplicationIndex]];
            for (let key in application.windows) {
                currentWindows.push(key);
            }
        }
        windowList.model = currentWindows;
    }

    function addApplication(application, override) {
        if (!currentOverrides[application]) {
            currentOverrides[application] = {
                override: override,
                onClose: defaultConfig.onClose,
                position: defaultConfig.position,
                size: defaultConfig.size,
                desktop: defaultConfig.desktop,
                activity: defaultConfig.activity,
                minimized: defaultConfig.minimized,
                windows: {}
            };
        }
    }

    function addWindow(application, window) {
        if (!currentOverrides[application].windows[window]) {
            currentOverrides[application].windows[window] = {
                override: false,
                onClose: defaultConfig.onClose,
                position: defaultConfig.position,
                size: defaultConfig.size,
                desktop: defaultConfig.desktop,
                activity: defaultConfig.activity,
                minimized: defaultConfig.minimized
            };
        }
    }

    function selectWindow() {
        selectWindowButton.text = "Click on the window to select...";
        selectNewWindowButton.text = "Click on the window to select...";
        Workspace.activeWindow = Workspace.stackingOrder[0];
        root.selectWindow();
    }

    function windowSelected(window) {
        selectWindowButton.text = "Select Application/Window";
        selectNewWindowButton.text = "Select New Application/Window";

        let validWindow = root.isValidWindow(window);
        let caption = validWindow ? window.caption : "<invalid-window>";

        saveCurrentData();

        applicationName.text = window.resourceClass;
        windowCaption.text = caption;
        windowCaption.cursorPosition = 0;

        addApplication(window.resourceClass, false);
        initApplications();
        currentApplicationIndex = currentApplications.indexOf(window.resourceClass);
        applicationList.currentIndex = currentApplicationIndex;
        if (validWindow) {
            addWindow(window.resourceClass, caption);
        }
        initWindows();
        currentWindowIndex = currentWindows.indexOf(caption);
        windowList.currentIndex = currentWindowIndex;

        updateCurrentData();

        root.logDev('Applications: ' + currentApplications);
        root.logDev('Windows: ' + currentWindows);

        choiceGroupBox.visible = false;
        editSaved.visible = true;
    }

    function updateCurrentData() {
        let applicationUpdated = false;
        let windowUpdated = false;

        if (currentApplicationIndex >= 0) {
            let application = currentOverrides[currentApplications[currentApplicationIndex]];
            root.logDev('Application override: ' + JSON.stringify(application));
            if (application) {
                blacklisted.checked = root.config.blacklist.includes(applicationName.text);
                whitelisted.checked = root.config.whitelist.includes(applicationName.text);
                perfectMatch.checked = root.config.perfectMultiWindowRestoreList.includes(applicationName.text);
                aOverride.enabled = true;
                aOverride.checked = application.override;
                aOnClose.checked = application.onClose;
                aAlways.checked = !application.onClose;
                aPosition.checked = application.position;
                aSize.checked = application.size;
                aDesktop.checked = application.desktop;
                aActivity.checked = application.activity;
                aMinimized.checked = application.minimized;
                applicationUpdated = true;

                if (currentWindowIndex >= 0) {
                    let window = application.windows[currentWindows[currentWindowIndex]];

                    if (window) {
                        wOverride.enabled = true;
                        wOverride.checked = window.override;
                        wOnClose.checked = window.onClose;
                        wAlways.checked = !window.onClose;
                        wPosition.checked = window.position;
                        wSize.checked = window.size;
                        wDesktop.checked = window.desktop;
                        wActivity.checked = window.activity;
                        wMinimized.checked = window.minimized;
                        windowUpdated = true;
                    }
                }
            }
        }

        if (!applicationUpdated) {
            blacklisted.checked = false;
            whitelisted.checked = false;
            perfectMatch.checked = false;
            aOverride.enabled = false;
            aOverride.checked = defaultConfig.override;
            aOnClose.checked = defaultConfig.onClose;
            aAlways.checked = !defaultConfig.onClose;
            aPosition.checked = defaultConfig.position;
            aSize.checked = defaultConfig.size;
            aDesktop.checked = defaultConfig.desktop;
            aActivity.checked = defaultConfig.activity;
            aMinimized.checked = defaultConfig.minimized;
        }

        if (!windowUpdated) {
            wOverride.enabled = false;
            wOverride.checked = defaultConfig.override;
            wOnClose.checked = defaultConfig.onClose;
            wAlways.checked = !defaultConfig.onClose;
            wPosition.checked = defaultConfig.position;
            wSize.checked = defaultConfig.size;
            wDesktop.checked = defaultConfig.desktop;
            wActivity.checked = defaultConfig.activity;
            wMinimized.checked = defaultConfig.minimized;
        }
    }

    function saveCurrentData() {
        root.logDev('Save before: ' + JSON.stringify(currentOverrides));
        if (currentApplicationIndex >= 0) {
            let application = currentOverrides[currentApplications[currentApplicationIndex]];
            if (application) {
                if (currentWindowIndex >= 0) {
                    let window = application.windows[currentWindows[currentWindowIndex]];
                    if (window) {
                        let overrideWindow = wOverride.checked;
                        window.override = overrideWindow;
                        window.onClose = overrideWindow ? wOnClose.checked : defaultConfig.onClose;
                        window.position = overrideWindow ? wPosition.checked : defaultConfig.position;
                        window.size = overrideWindow ? wSize.checked : defaultConfig.size;
                        window.desktop = overrideWindow ? wDesktop.checked : defaultConfig.desktop;
                        window.activity = overrideWindow ? wActivity.checked : defaultConfig.activity;
                        window.minimized = overrideWindow ? wMinimized.checked : defaultConfig.minimized;
                    }
                }

                let overrideApplication = aOverride.checked;
                application.override = overrideApplication;
                application.onClose = overrideApplication ? aOnClose.checked : defaultConfig.onClose;
                application.position = overrideApplication ? aPosition.checked : defaultConfig.position;
                application.size = overrideApplication ? aSize.checked : defaultConfig.size;
                application.desktop = overrideApplication ? aDesktop.checked : defaultConfig.desktop;
                application.activity = overrideApplication ? aActivity.checked : defaultConfig.activity;
                application.minimized = overrideApplication ? aMinimized.checked : defaultConfig.minimized;
            }
        }
        root.logDev('Save after: ' + JSON.stringify(currentOverrides));
    }

    function deleteCurrentApplication() {
        if (currentApplicationIndex >= 0) {
            root.logDev('before: ' + JSON.stringify(currentOverrides));
            let application = currentApplications.splice(currentApplicationIndex, 1)[0];
            delete currentOverrides[application];
            applicationList.model = currentApplications;
            applicationIndexChanged(-1);
            root.logDev('after: ' + JSON.stringify(currentOverrides));
        }
    }

    function applicationIndexChanged(index) {
        saveCurrentData();
        applicationList.currentIndex = index;
        currentApplicationIndex = index;
        initWindows();
        windowList.model = currentWindows;
        currentWindowIndex = windowList.currentIndex;

        if (currentApplicationIndex >= 0) {
            applicationName.text = currentApplications[currentApplicationIndex];
        } else {
            applicationName.text = "";
        }

        if (currentWindowIndex >= 0) {
            windowCaption.text = currentWindows[currentWindowIndex];
            windowCaption.cursorPosition = 0;
        } else {
            windowCaption.text = "";
        }

        updateCurrentData();
    }

    function deleteCurrentWindow() {
        if (currentApplicationIndex >= 0 && currentWindowIndex >= 0) {
            root.logDev('before: ' + JSON.stringify(currentOverrides));
            let window = currentWindows.splice(currentWindowIndex, 1)[0];
            delete currentOverrides[currentApplications[currentApplicationIndex]].windows[window];
            windowList.model = currentWindows;
            windowIndexChanged(-1);
            root.logDev('after: ' + JSON.stringify(currentOverrides));
        }
    }

    function windowIndexChanged(index) {
        saveCurrentData();
        windowList.currentIndex = index;
        currentWindowIndex = index;

        if (currentWindowIndex >= 0) {
            windowCaption.text = currentWindows[currentWindowIndex];
            windowCaption.cursorPosition = 0;
        } else {
            windowCaption.text = "";
        }

        updateCurrentData();
    }

    function editSavedAppOrWindow() {
        choiceGroupBox.visible = false;
        editSaved.visible = true;
        applicationIndexChanged(applicationList.currentIndex);
        windowIndexChanged(windowList.currentIndex);
    }

    function cancelEdit() {
        choiceGroupBox.visible = true;
        editSaved.visible = false;
        initMainMenu();
    }

    function saveForReal() {
        root.logDev('Save for real before: ' + JSON.stringify(currentOverrides));
        for (let applicationKey in currentOverrides) {
            let application = currentOverrides[applicationKey];
            for (let windowKey in application.windows) {
                let window = application.windows[windowKey];
                if (!window.override) {
                    root.logDev('Deleting window: ' + JSON.stringify(window));
                    delete application.windows[windowKey];
                }
            }
            if (!application.override && Object.keys(application.windows).length == 0) {
                root.logDev('Deleting application: ' + JSON.stringify(application));
                delete currentOverrides[applicationKey];
            }
        }
        root.logDev('Save for real after: ' + JSON.stringify(currentOverrides));

        overrides = JSON.parse(JSON.stringify(currentOverrides));
    }

    function saveEdit() {
        choiceGroupBox.visible = true;
        editSaved.visible = false;
        saveCurrentData();
        saveForReal();
        initMainMenu();
    }

    GroupBox {
        id: mainGroupBox
        anchors.fill: parent

        GroupBox {
            id: choiceGroupBox
            visible: true

            spacing: 5
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                anchors.fill: parent

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Click the \"Select Application/Window\" button then click on an open window to edit its properties."
                    wrapMode: Text.WordWrap
                }

                Button {
                    id: selectWindowButton
                    text: "Select Application/Window"
                    Layout.fillWidth: true

                    onClicked: selectWindow()
                }

                Button {
                    text: "Edit Saved Applications and Windows"
                    Layout.fillWidth: true

                    onClicked: editSavedAppOrWindow()
                }
            }
        }

        RowLayout {
            id: editSaved
            anchors.fill: parent
            uniformCellSizes: true
            visible: false

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                uniformCellSizes: true

                GroupBox {
                    id: applicationListGroupBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Select Application"
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                            ListView {
                                id: applicationList
                                clip: true
                                currentIndex: -1

                                model: currentApplications
                                delegate: ItemDelegate {
                                    text: modelData
                                    width: applicationList.width
                                    highlighted: applicationList.currentIndex == index

                                    onClicked: applicationIndexChanged(index)

                                    required property int index
                                    required property string modelData
                                }
                            }
                        }

                        Button {
                            id: deleteApplication
                            Layout.fillWidth: true

                            text: "Delete Application Override Settings"

                            onClicked: deleteCurrentApplication()
                        }
                    }
                }

                GroupBox {
                    id: windowListGroupBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ColumnLayout {
                        anchors.fill: parent

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Select Window"
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                            ListView {
                                id: windowList
                                clip: true

                                model: currentWindows
                                delegate: ItemDelegate {
                                    text: modelData
                                    width: windowList.width
                                    highlighted: windowList.currentIndex == index

                                    onClicked: windowIndexChanged(index)

                                    required property int index
                                    required property string modelData
                                }
                            }
                        }

                        Button {
                            id: deleteWindow
                            Layout.fillWidth: true

                            text: "Delete Window Override Settings"

                            onClicked: deleteCurrentWindow()
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Current Application"
                        }

                        TextField {
                            id: applicationName
                            Layout.fillWidth: true
                            enabled: false
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            uniformCellSizes: true
                            enabled: false

                            CheckBox {
                                Layout.fillWidth: true
                                id: blacklisted
                                text: "Blacklisted"
                            }

                            CheckBox {
                                Layout.fillWidth: true
                                id: whitelisted
                                text: "Whitelisted"
                            }

                            CheckBox {
                                Layout.fillWidth: true
                                id: perfectMatch
                                text: "Perfect Restore"
                            }
                        }
                    }
                }

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Current Window"
                        }

                        TextField {
                            id: windowCaption
                            Layout.fillWidth: true
                            enabled: false
                        }
                    }
                }

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Override Settings"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "You can change the defaults in System Settings > Window Management > KWin Scripts > Remember Window Positions. Any overriden application or window will ignore blacklist and whitelist settings."
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            uniformCellSizes: true

                            GroupBox {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    enabled: false

                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Default"
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Remember"
                                    }
                                    RadioButton {
                                        text: "On Close Last"
                                        checked: true
                                    }
                                    RadioButton {
                                        text: "Always"
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Properties"
                                    }
                                    CheckBox {
                                        id: dSize
                                        text: "Size"
                                        checked: defaultConfig.size
                                    }
                                    CheckBox {
                                        id: dPosition
                                        text: "Position"
                                        checked: true
                                    }
                                    CheckBox {
                                        id: dDesktop
                                        text: "Desktop"
                                        checked: defaultConfig.desktop
                                    }
                                    CheckBox {
                                        id: dActivity
                                        text: "Activity"
                                        checked: defaultConfig.activity
                                    }
                                    CheckBox {
                                        id: dMinimized
                                        text: "Minimized"
                                        checked: defaultConfig.minimized
                                    }
                                }
                            }

                            GroupBox {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.fill: parent

                                    CheckBox {
                                        id: aOverride
                                        Layout.alignment: Qt.AlignHCenter
                                        rightPadding: indicator.width
                                        text: "Application"
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Remember"
                                        enabled: aOverride.checked
                                    }
                                    RadioButton {
                                        id: aOnClose
                                        text: "On Close Last"
                                        checked: true
                                        enabled: aOverride.checked
                                    }
                                    RadioButton {
                                        id: aAlways
                                        text: "Always"
                                        enabled: aOverride.checked
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Properties"
                                        enabled: aOverride.checked
                                    }
                                    CheckBox {
                                        id: aSize
                                        text: "Size"
                                        enabled: aOverride.checked
                                    }
                                    CheckBox {
                                        id: aPosition
                                        text: "Position"
                                        enabled: aOverride.checked
                                    }
                                    CheckBox {
                                        id: aDesktop
                                        text: "Desktop"
                                        enabled: aOverride.checked
                                    }
                                    CheckBox {
                                        id: aActivity
                                        text: "Activity"
                                        enabled: aOverride.checked
                                    }
                                    CheckBox {
                                        id: aMinimized
                                        text: "Minimized"
                                        enabled: aOverride.checked
                                    }
                                }
                            }

                            GroupBox {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            
                                ColumnLayout {
                                    anchors.fill: parent
                                    uniformCellSizes: true

                                    CheckBox {
                                        id: wOverride
                                        Layout.alignment: Qt.AlignHCenter
                                        rightPadding: indicator.width
                                        text: "Window"
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Remember"
                                        enabled: wOverride.checked
                                    }
                                    RadioButton {
                                        id: wOnClose
                                        text: "On Close Last"
                                        checked: true
                                        enabled: wOverride.checked
                                    }
                                    RadioButton {
                                        id: wAlways
                                        text: "Always"
                                        enabled: wOverride.checked
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Properties"
                                        enabled: wOverride.checked
                                    }
                                    CheckBox {
                                        id: wSize
                                        text: "Size"
                                        enabled: wOverride.checked
                                    }
                                    CheckBox {
                                        id: wPosition
                                        text: "Position"
                                        enabled: wOverride.checked
                                    }
                                    CheckBox {
                                        id: wDesktop
                                        text: "Desktop"
                                        enabled: wOverride.checked
                                    }
                                    CheckBox {
                                        id: wActivity
                                        text: "Activity"
                                        enabled: wOverride.checked
                                    }
                                    CheckBox {
                                        id: wMinimized
                                        text: "Minimized"
                                        enabled: wOverride.checked
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent

                        Button {
                            id: selectNewWindowButton
                            text: "Select New Application/Window"
                            Layout.fillWidth: true

                            onClicked: selectWindow()
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Button {
                                id: saveSettings
                                text: "Save Settings"
                                Layout.fillWidth: true

                                onClicked: saveEdit()
                            }

                            Button {
                                id: cancelSettingEdit
                                text: "Cancel"
                                Layout.fillWidth: true

                                onClicked: cancelEdit()
                            }
                        }
                    }
                }
            }
        }
    }
}