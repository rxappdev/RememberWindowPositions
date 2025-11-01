import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kwin
import org.kde.kirigami as Kirigami

ApplicationWindow {
    property var overrides: {}
    property var currentOverrides: {}
    property var currentApplications: []
    property var currentWindows: []
    property var defaultConfig: {}
    property var currentApplicationIndex: -1
    property var currentWindowIndex: -1
    // property var isX11: Qt.platform.pluginName == 'xcb'
    // property var showFirstTimeHint: false
    property var mouseStartX
    property var mouseStartY
    property var windowStartX
    property var windowStartY

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property var lightTheme: {
        return Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light;
    }

    property var headerColor: {
        if (lightTheme) {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "white", 0.4);
        } else {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.3);
        }
    }

    property var headerBorderColor: {
        if (lightTheme) {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.2);
        } else {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "white", 0.2);
        }
    }

    id: mainMenuRoot
    width: 1000
    height: 734
    title: "Remember Window Positions - Per Application/Window Configuration"
    color: Kirigami.Theme.backgroundColor
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.BypassWindowManagerHint
    // flags: ixX11 ? Qt.X11BypassWindowManagerHint : flags

    // x: isX11 ? Workspace.virtualScreenSize.width / 2 - width / 2 : x
    // y: isX11 ? Workspace.virtualScreenSize.height / 2 - height / 2 : y
    x: Workspace.virtualScreenSize.width / 2 - width / 2
    y: Workspace.virtualScreenSize.height / 2 - height / 2

    function initMainMenu() {
        currentOverrides = JSON.parse(JSON.stringify(overrides));
        currentApplicationIndex = -1;
        currentWindowIndex = -1;
        // firstTimeHint.visible = showFirstTimeHint;
        mainChoice.visible = true;
        editSaved.visible = false;
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
                config: {
                    override: override,
                    rememberOnClose: defaultConfig.rememberOnClose,
                    rememberNever: defaultConfig.rememberNever,
                    rememberAlways: defaultConfig.rememberAlways,
                    position: defaultConfig.position,
                    size: defaultConfig.size,
                    desktop: defaultConfig.desktop,
                    activity: defaultConfig.activity,
                    minimized: defaultConfig.minimized
                },
                windows: {}
            };
        }
    }

    function addWindow(application, window) {
        if (!currentOverrides[application].windows[window]) {
            currentOverrides[application].windows[window] = {
                override: false,
                rememberOnClose: false,
                rememberNever: false,
                rememberAlways: true,
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

        mainChoice.visible = false;
        editSaved.visible = true;
    }

    function updateCurrentData() {
        let applicationUpdated = false;
        let windowUpdated = false;

        if (currentApplicationIndex >= 0) {
            let application = currentOverrides[currentApplications[currentApplicationIndex]];
            if (application) {
                blacklisted.checked = root.config.blacklist.includes(applicationName.text);
                whitelisted.checked = root.config.whitelist.includes(applicationName.text);
                perfectMatch.checked = root.config.perfectMultiWindowRestoreList.includes(applicationName.text);

                let config = application.config;
                aOverride.enabled = true;
                aOverride.checked = config.override;
                aOnClose.checked = config.rememberOnClose;
                aAlways.checked = config.rememberAlways;
                aNever.checked = config.rememberNever
                aPosition.checked = config.position;
                aSize.checked = config.size;
                aDesktop.checked = config.desktop;
                aActivity.checked = config.activity;
                aMinimized.checked = config.minimized;
                applicationUpdated = true;

                if (currentWindowIndex >= 0) {
                    let window = application.windows[currentWindows[currentWindowIndex]];

                    if (window) {
                        wOverride.enabled = true;
                        wOverride.checked = window.override;
                        wOnClose.checked = window.rememberOnClose;
                        wAlways.checked = window.rememberAlways;
                        wNever.checked = window.rememberNever;
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
            aOnClose.checked = defaultConfig.rememberOnClose;
            aAlways.checked = defaultConfig.rememberAlways;
            aNever.checked = defaultConfig.rememberNever;
            aPosition.checked = defaultConfig.position;
            aSize.checked = defaultConfig.size;
            aDesktop.checked = defaultConfig.desktop;
            aActivity.checked = defaultConfig.activity;
            aMinimized.checked = defaultConfig.minimized;
        }

        if (!windowUpdated) {
            wOverride.enabled = false;
            wOverride.checked = false;
            wOnClose.checked = false;
            wAlways.checked = true;
            wNever.checked = defaultConfig.rememberNever;
            wPosition.checked = defaultConfig.position;
            wSize.checked = defaultConfig.size;
            wDesktop.checked = defaultConfig.desktop;
            wActivity.checked = defaultConfig.activity;
            wMinimized.checked = defaultConfig.minimized;
        }
    }

    function saveCurrentData() {
        if (currentApplicationIndex >= 0) {
            let application = currentOverrides[currentApplications[currentApplicationIndex]];
            if (application) {
                if (currentWindowIndex >= 0) {
                    let window = application.windows[currentWindows[currentWindowIndex]];
                    if (window) {
                        let overrideWindow = wOverride.checked;
                        window.override = overrideWindow;
                        window.rememberOnClose = overrideWindow ? wOnClose.checked : defaultConfig.rememberOnClose;
                        window.rememberNever = overrideWindow ? wNever.checked : defaultConfig.rememberNever;
                        window.rememberAlways = overrideWindow ? wAlways.checked : defaultConfig.rememberAlways;
                        window.position = overrideWindow ? wPosition.checked : defaultConfig.position;
                        window.size = overrideWindow ? wSize.checked : defaultConfig.size;
                        window.desktop = overrideWindow ? wDesktop.checked : defaultConfig.desktop;
                        window.activity = overrideWindow ? wActivity.checked : defaultConfig.activity;
                        window.minimized = overrideWindow ? wMinimized.checked : defaultConfig.minimized;
                    }
                }

                let overrideApplication = aOverride.checked;
                application.config.override = overrideApplication;
                application.config.rememberOnClose = overrideApplication ? aOnClose.checked : defaultConfig.rememberOnClose;
                application.config.rememberNever = overrideApplication ? aNever.checked : defaultConfig.rememberNever;
                application.config.rememberAlways = overrideApplication ? aAlways.checked : defaultConfig.rememberAlways;
                application.config.position = overrideApplication ? aPosition.checked : defaultConfig.position;
                application.config.size = overrideApplication ? aSize.checked : defaultConfig.size;
                application.config.desktop = overrideApplication ? aDesktop.checked : defaultConfig.desktop;
                application.config.activity = overrideApplication ? aActivity.checked : defaultConfig.activity;
                application.config.minimized = overrideApplication ? aMinimized.checked : defaultConfig.minimized;
            }
        }
    }

    function deleteCurrentApplication() {
        if (currentApplicationIndex >= 0) {
            let application = currentApplications.splice(currentApplicationIndex, 1)[0];
            delete currentOverrides[application];
            applicationList.model = currentApplications;
            applicationIndexChanged(-1);
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
            let window = currentWindows.splice(currentWindowIndex, 1)[0];
            delete currentOverrides[currentApplications[currentApplicationIndex]].windows[window];
            windowList.model = currentWindows;
            windowIndexChanged(-1);
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

    // function closeHint() {
    //     firstTimeHint.visible = false;
    //     mainChoice.visible = true;
    // }

    function editSavedAppOrWindow() {
        mainChoice.visible = false;
        editSaved.visible = true;
        applicationIndexChanged(applicationList.currentIndex);
        windowIndexChanged(windowList.currentIndex);
    }

    function cancelEdit() {
        mainChoice.visible = true;
        editSaved.visible = false;
        initMainMenu();
    }

    function saveForReal() {
        for (let applicationKey in currentOverrides) {
            let application = currentOverrides[applicationKey];
            for (let windowKey in application.windows) {
                let window = application.windows[windowKey];
                if (!window.override) {
                    delete application.windows[windowKey];
                }
            }
            if (!application.config.override && Object.keys(application.windows).length == 0) {
                delete currentOverrides[applicationKey];
            }
        }

        overrides = JSON.parse(JSON.stringify(currentOverrides));
        root.saveOverridesToSettings(overrides);
    }

    function saveEdit() {
        mainChoice.visible = true;
        editSaved.visible = false;
        saveCurrentData();
        saveForReal();
        initMainMenu();
    }

    function deleteSavedApplicationWindowsForSelected() {
        if (currentApplicationIndex >= 0) {
            root.clearSaves(currentApplications[currentApplicationIndex], true);
        }
    }

    function deleteSavedWindowsForSelected() {
        if (currentApplicationIndex >= 0 && currentWindowIndex >= 0) {
            root.clearSaves(currentApplications[currentApplicationIndex], false, currentWindows[currentWindowIndex]);
        }
    }

    Rectangle {
        color: headerColor
        height: 34
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        border.color: headerBorderColor
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton

            onPressed: {
                mouseStartX = Workspace.cursorPos.x;
                mouseStartY = Workspace.cursorPos.y;
                windowStartX = mainMenuRoot.x;
                windowStartY = mainMenuRoot.y;
            }

            onPositionChanged: {
                mainMenuRoot.x = windowStartX + (Workspace.cursorPos.x - mouseStartX);
                mainMenuRoot.y = windowStartY + (Workspace.cursorPos.y - mouseStartY);
            }

            onReleased: {
                mainMenuRoot.x = windowStartX + (Workspace.cursorPos.x - mouseStartX);
                mainMenuRoot.y = windowStartY + (Workspace.cursorPos.y - mouseStartY);
            }

            Label {
                text: "Remember Window Positions - Per Application/Window Configuration"
                anchors.centerIn: parent
            }

            Button {
                text: "X"
                flat: true

                width: 26
                height: 26
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 4

                onClicked: root.closeMainMenu()
            }
        }
    }

    GroupBox {
        id: mainGroupBox
        anchors.fill: parent
        anchors.topMargin: 35


        // GroupBox {
        //     id: firstTimeHint
        //     spacing: 5
        //     anchors.left: parent.left
        //     anchors.right: parent.right
        //     anchors.verticalCenter: parent.verticalCenter
        //     visible: showFirstTimeHint

        //     ColumnLayout {
        //         anchors.fill: parent

        //         Label {
        //             Layout.fillWidth: true
        //             horizontalAlignment: Text.AlignHCenter
        //             text: "Welcome to Remember Window Positions"
        //             wrapMode: Text.WordWrap
        //         }

        //         Label {
        //             Layout.fillWidth: true
        //             text: "This window is only shown once after installation. To view it again, you need to use the \"<b>Remember Window Positions: Show Config</b>\" keyboard shortcut - \"<b>Meta+Ctrl+W</b>\" by default. If this keyboard shortcut does not work, please manually asign it (or any shortcut you like) in \"<b>System Settings > Keyboard > Shortcuts > Window Management > Remember Window Positions: Show Config</b>\"."
        //             wrapMode: Text.WordWrap
        //         }

        //         Button {
        //             text: "I Understand"
        //             Layout.fillWidth: true
        //             Layout.topMargin: 20

        //             onClicked: closeHint()
        //         }
        //     }
        // }

        ColumnLayout {
            id: mainChoice
            visible: true
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            GroupBox {
                spacing: 5
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Instructions"
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "It is highly recommended to create a good default configuration in the \"<b>System Settings > Window Management > KWin Scripts > Remember Window Positions</b>\" configuration dialog intead of relying on application/window specifiy overrides."
                        wrapMode: Text.WordWrap
                    }
                }
            }

            GroupBox {
                spacing: 5
                Layout.fillWidth: true

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
                            id: deleteSavedApplicationWindows
                            text: "Remove All Windows From Savefile (Cannot Be Undone)"
                            Layout.fillWidth: true

                            onClicked: deleteSavedApplicationWindowsForSelected()
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
                            id: deleteSavedWindows
                            text: "Remove All Window Instances From Savefile (Cannot Be Undone)"
                            Layout.fillWidth: true

                            onClicked: deleteSavedWindowsForSelected()
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

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Windows with same caption might get mixed up during restoration."
                            wrapMode: Text.WordWrap
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
                            text: "You can change the defaults in System Settings > Window Management > KWin Scripts > Remember Window Positions. Any overriden application or window will ignore blacklist, whitelist and multi-window only settings."
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

                                    CheckBox {
                                        Layout.alignment: Qt.AlignHCenter
                                        rightPadding: indicator.width
                                        text: "Default"
                                        font.bold: true
                                        tristate: true
                                        checkState: Qt.PartiallyChecked
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: "Remember On"
                                    }
                                    RadioButton {
                                        text: "Close Last Window"
                                        checked: true
                                    }
                                    RadioButton {
                                        text: "Close Any Window"
                                    }
                                    RadioButton {
                                        text: "Never"
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
                                        text: "Remember On"
                                        enabled: aOverride.checked
                                    }
                                    RadioButton {
                                        id: aOnClose
                                        text: "Close Last Window"
                                        checked: true
                                        enabled: aOverride.checked
                                    }
                                    RadioButton {
                                        id: aAlways
                                        text: "Close Any Window"
                                        enabled: aOverride.checked
                                    }
                                    RadioButton {
                                        id: aNever
                                        text: "Never"
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
                                        text: "Remember On"
                                        enabled: wOverride.checked
                                    }
                                    RadioButton {
                                        id: wOnClose
                                        text: "Close Last Window"
                                        checked: true
                                        enabled: wOverride.checked
                                    }
                                    RadioButton {
                                        id: wAlways
                                        text: "Close This Window"
                                        enabled: wOverride.checked
                                    }
                                    RadioButton {
                                        id: wNever
                                        text: "Never"
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
                            uniformCellSizes: true

                            Button {
                                id: saveSettings
                                text: "Save Override Settings"
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