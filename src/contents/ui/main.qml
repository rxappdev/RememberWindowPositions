import QtQuick
import QtCore
import org.kde.kwin

Item {
    // API and guides
    // https://develop.kde.org/docs/plasma/kwin/
    // https://develop.kde.org/docs/plasma/kwin/api/
    // https://develop.kde.org/docs/plasma/widget/configuration/
    // https://develop.kde.org/docs/features/configuration/kconfig_xt/
    // https://doc.qt.io/qt-6/qml-qtcore-settings.html
    // https://doc.qt.io/qt-6/qtquick-qmlmodule.html

    id: root

    property var debugLogs: false
    property var config: ({})
    property var windowOrder: []

    function log(string) {
        if (!debugLogs) return;
        console.warn('RememberWindowPositions: ' + string);
    }

    function logE(string) {
        if (!debugLogs) return;
        console.error('RememberWindowPositions: ' + string);
    }

    function logDev(string) {
        console.error('RememberWindowPositions: ' + string);
    }

    function logAppInfo(name) {
        let isFirstWindow = !config.windows[name] || (config.windows[name] && config.windows[name].windowCount == 0);
        if (isFirstWindow || config.printAllWindows) {
            console.warn('RememberWindowPositions - application name to add to settings: ' + name);
            var info = '';

            if (config.windows[name] && config.windows[name].saved.length > 0) {
                let len = config.windows[name].saved.length;
                info += ' - ' + len + ' saved window' + (len > 1 ? 's' : '');
            }
            if (config.whitelist.includes(name)) {
                info += ' - on whitelist';
            }
            if (config.blacklist.includes(name)) {
                info += ' - on blacklist';
            }
            if (config.perfectMultiWindowRestoreList.includes(name)) {
                info += ' - on perfect list';
            }
            if (info.length > 0) {
                console.warn('RememberWindowPositions - current status' + info);
            }
        }
    }

    function logAppInfoOnClose(name, count) {
        console.warn('RememberWindowPositions - application name to add to settings: ' + name);
        console.warn('RememberWindowPositions - application closed - saved ' + count + ' window' + (count != 1 ? 's' : ''));
    }

    function logMode() {
        if (!debugLogs) return;
        let mode = "UNKNOWN";
        if (config.appsAll) mode = 'All apps';
        else if (config.appsMultiWindowOnly) mode = 'Multi-window apps only';
        else if (config.appsNotBlacklisted) mode = 'All except blacklisted apps';
        else if (config.appsWhitelistedOnly) mode = 'Only whitelisted apps';
        log('Restoring: ' + mode + ' - minimumCaptionMatch: ' + config.minimumCaptionMatch + ' restoreWindowsWithoutCaption: ' + config.restoreWindowsWithoutCaption + ' restoreSize: ' + config.restoreSize + ' restoreMinimized: ' + config.restoreMinimized);
    }

    function stringListToArray(list) {
        let array = [];
        let items = list.split(/\r?\n/);
        for (let i = 0; i < items.length; i++) {
            let item = items[i].trim();
            if (item && item.length > 0) {
                array.push(item);
            }
        }
        return array;
    }

    function loadConfig() {
        log('Loading configuration');
        const browserList = "brave-browser\norg.mozilla.firefox\nvivaldi-stable\nlibrewolf\nchromium-browser\nChromium-browser\ngoogle-chrome\nmicrosoft-edge\nMullvad Browser\nOpera\nio.github.ungoogled_software.ungoogled_chromium\napp.zen_browser.zen\nwaterfox-default";
        config = {
            // user settings
            restoreType: KWin.readConfig("restoreType", 2),
            restoreSize: KWin.readConfig("restoreSize", true),
            restoreVirtualDesktop: KWin.readConfig("restoreVirtualDesktop", true),
            restoreActivities: KWin.readConfig("restoreActivities", true),
            restoreMinimized: KWin.readConfig("restoreMinimized", true),
            restoreWindowsWithoutCaption: KWin.readConfig("restoreWindowsWithoutCaption", true),
            minimumCaptionMatch: KWin.readConfig("minimumCaptionMatch", 0),
            printType: KWin.readConfig("printType", 0),
            instantRestore: KWin.readConfig("instantRestore", true),
            multiWindowRestoreAttempts: KWin.readConfig("multiWindowRestoreAttempts", 5),
            usePerfectMultiWindowRestore: KWin.readConfig("usePerfectMultiWindowRestore", true),
            perfectMultiWindowRestoreAttempts: KWin.readConfig("perfectMultiWindowRestoreAttempts", 12),
            perfectMultiWindowRestoreList: stringListToArray(KWin.readConfig("perfectMultiWindowRestoreList", browserList)),
            printApplicationNameToLog: KWin.readConfig("printApplicationNameToLog", true),
            blacklist: stringListToArray(KWin.readConfig("blacklist", "org.kde.spectacle\norg.kde.polkit-kde-authentication-agent-1\nsteam_proton\nsteam")),
            whitelist: stringListToArray(KWin.readConfig("whitelist", browserList)),
            // confidence
            confidence: [
                { caption: 100, matchingDimentions: 2, allowHeightShrinking: false }, // Caption and size match
                { caption: 100, matchingDimentions: 2, allowHeightShrinking: true  }, // Caption, width and shrinked height match
                { caption: 100, matchingDimentions: 1, allowHeightShrinking: false }, // Caption match and width or height match
                { caption: 100, matchingDimentions: 0, allowHeightShrinking: false }, // Caption match
                { caption:  85, matchingDimentions: 2, allowHeightShrinking: false }, // Partial caption match and size match
                { caption:  85, matchingDimentions: 2, allowHeightShrinking: true  }, // Partial caption match and width and shrinked height match
                { caption:  85, matchingDimentions: 1, allowHeightShrinking: false }, // Partial caption match and width or height match
                { caption:  85, matchingDimentions: 0, allowHeightShrinking: false }, // Partial caption match
                { caption:  50, matchingDimentions: 0, allowHeightShrinking: false }, // Half caption match
                { caption:   0, matchingDimentions: 2, allowHeightShrinking: false }, // Size match
                { caption:   0, matchingDimentions: 2, allowHeightShrinking: true  }, // With and partial height match
                { caption:   0, matchingDimentions: 1, allowHeightShrinking: false }, // Width or height match
                { caption:   0, matchingDimentions: 0, allowHeightShrinking: true  }  // Pick anything - this is a fallback and must always be the last option
            ],
            // window list
            windows: {}
        }
        // convert user setting to simple booleans
        config.appsAll = config.restoreType == 0;
        config.appsMultiWindowOnly = config.restoreType == 1;
        config.appsNotBlacklisted = config.restoreType == 2;
        config.appsWhitelistedOnly = config.restoreType == 3;
        config.printAllWindows = config.printType == 1;
        log('Whitelist: ' + JSON.stringify(config.whitelist));
        logMode();
    }

    function isValidWindow(client) {
        if (!client) return false;
        if (!client.normalWindow) return false;
        if (client.popupWindow) return false;
        if (client.skipTaskbar) return false;
        if (!client.resourceClass) return false;
        if (client.resourceClass.trim().length == 0) return false;

        return true;
    }

    function matchCaption(a, b) {
        if (a === b) return 100;
        if (!a || !b) return 0;

        let lengthA = a.length;
        let lengthB = b.length;
        let lengthMin = Math.min(lengthA, lengthB);
        let lengthMax = Math.max(lengthA, lengthB);

        if (lengthMin > 0) {
            let match = 0;
            let matchReverse = 0;

            for (let i = 0; i < lengthMin; i++) {
                if (a[i] === b[i]) match++;
                if (a[lengthA - i - 1] === b[lengthB - i - 1]) matchReverse++;
            }

            let bestMatch = Math.max(match, matchReverse);
            return Math.max(Math.min((bestMatch * 100 / lengthMax), 100), 0);
        }

        return 0;
    }

    function getHighestCaptionScore(windowData, client) {
        var highestScore = 0;

        for (let i = 0; i < windowData.saved.length; i++) {
            let score = matchCaption(windowData.saved[i].caption, client.caption);
            if (score > highestScore) {
                highestScore = score;
            }
        }

        return highestScore;
    }

    function restoreWindowPlacement(saveData, client, captionScore, restoreZ = true) {
        if (!client) return;
        if (!saveData) return;
        if (captionScore < config.minimumCaptionMatch) return;
        if (!config.restoreWindowsWithoutCaption && (!client.caption || client.caption.trim().length == 0)) return;
        let positionRestored = false;
        let virtualDesktopRestored = false;
        let minimizeRestored = false;
        let zRestored = false;

        if (!client.rwp_partiallyRestored) {
            client.rwp_partiallyRestored = true;

            // Restore frame geometry
            if (config.restoreSize) {
                if (client.x != saveData.x || client.y != saveData.y || client.width != saveData.width || client.height != saveData.height) {
                    log('Attempting to restore window size and position');
                    client.frameGeometry = Qt.rect(saveData.x, saveData.y, saveData.width, saveData.height);
                    positionRestored = true;
                }
            } else if (client.x != saveData.x || client.y != saveData.y) {
                log('Attempting to restore window position');
                client.frameGeometry = Qt.rect(saveData.x, saveData.y, client.width, client.height);
                positionRestored = true;
            }

            // Restore activities
            if (config.restoreActivities) {
                if (saveData.activities && client.activities) {
                    log('Attempting to restore window activities');
                    let activities = [];
                    let activitiesLength = saveData.activities.length;
                    if (activitiesLength > 0) {
                        for (let i = 0; i < activitiesLength; i++) {
                            if (Workspace.activities.includes(saveData.activities[i])) {
                                activities.push(saveData.activities[i]);
                            }
                        }
                    }
                    client.activities = activities;
                }
            }

            // Restore virtual desktop
            if (config.restoreVirtualDesktop) {
                let desktopNumber = client.onAllDesktops ? -1 : client.desktops[0].x11DesktopNumber;
                if (saveData.desktopNumber != desktopNumber) {
                    if (saveData.desktopNumber == -1) {
                        log('Attempting to restore window on all virtual desktops');
                        client.onAllDesktops = true;
                    } else {
                        log('Attempting to restore window virtual desktop');
                        let desktop = Workspace.desktops.find((d) => d.x11DesktopNumber == saveData.desktopNumber);
                        if (desktop) {
                            client.desktops = [desktop];
                        } else {
                            logE('Failed to restore window virtual desktop');
                        }
                    }
                    virtualDesktopRestored = true;
                }
            }

            // Restore screen
            // - this seems to be handled by restoring frame geometry as it spans all screens - if anything changes will have to implement this. The screen is saved just in case.
        }

        // Restore z-index
        if (restoreZ) {
            log('Attempting to restore window z-index');
            Workspace.raiseWindow(client);
            zRestored = true;
        }

        // Restore minimized
        if (saveData.minimized && config.restoreMinimized) {
            log('Attempting to restore window minimized');
            client.minimized = true;
            minimizeRestored = true;
        }

        logE(client.resourceClass + ' restored - z: ' + zRestored + ' positon: ' + positionRestored + ' desktop: ' + virtualDesktopRestored + ' minimized: ' + minimizeRestored + ' caption score: ' + captionScore + ' internalId: ' + client.internalId);
        log('- caption   save: ' + saveData.caption);
        log('- caption window: ' + client.caption);
    }

    function twoWayMatch(windowData, confidence) {
        let results = [];
        let loadingIndex = 0;

        while (loadingIndex < windowData.loading.length) {
            var highestSaveCaptionScore = -1;
            var highestSaveMatchingDimentions = 0;
            var highestSaveIndex = -1;
            var saveFound = false;
            var loadingFound = false;

            if (loadingIndex < windowData.loading.length) {
                // Find highest matching save for current loading window
                let loading = windowData.loading[loadingIndex];
                for (let saveIndex = 0; saveIndex < windowData.saved.length; saveIndex++) {
                    let saved = windowData.saved[saveIndex];
                    let matchingDimentions = 0;
                    if (saved.width == loading.width) matchingDimentions++;
                    if (saved.height == loading.height || confidence.allowHeightShrinking && Math.abs(saved.height - loading.height) < 60) matchingDimentions++;
                    if (matchingDimentions < confidence.matchingDimentions) continue;
                    let captionScore = matchCaption(saved.caption, loading.caption);
                    if (captionScore < confidence.caption) continue;

                    if (captionScore >= highestSaveCaptionScore) {
                        if (matchingDimentions > highestSaveMatchingDimentions || captionScore > highestSaveCaptionScore) {
                            highestSaveCaptionScore = captionScore;
                            highestSaveMatchingDimentions = matchingDimentions;
                            highestSaveIndex = saveIndex;
                            saveFound = true;
                        }
                    }
                }
            }

            if (saveFound) {
                // Make sure the save does not have a better matching loading window
                var highestLoadingCaptionScore = highestSaveCaptionScore;
                var highestLoadingMatchingDimentions = highestSaveMatchingDimentions;
                var highestLoadingIndex = loadingIndex;
                let saved = windowData.saved[highestSaveIndex];

                for (let loadingReverseMatchIndex = 0; loadingReverseMatchIndex < windowData.loading.length; loadingReverseMatchIndex++) {
                    let loading = windowData.loading[loadingReverseMatchIndex];
                    let matchingDimentions = 0;
                    if (saved.width == loading.width) matchingDimentions++;
                    if (saved.height == loading.height || confidence.allowHeightShrinking && Math.abs(saved.height - loading.height) < 60) matchingDimentions++;
                    if (matchingDimentions < confidence.matchingDimentions) continue;
                    let captionScore = matchCaption(saved.caption, loading.caption);
                    if (captionScore < confidence.caption) continue;

                    if (captionScore >= highestLoadingCaptionScore) {
                        if (matchingDimentions > highestLoadingMatchingDimentions || captionScore > highestLoadingCaptionScore) {
                            highestLoadingCaptionScore = captionScore;
                            highestLoadingMatchingDimentions = matchingDimentions;
                            highestLoadingIndex = loadingReverseMatchIndex;
                            loadingFound = true;
                        }
                    }
                }

                log('Highest caption score: ' + highestLoadingCaptionScore + ' matching dimentions: ' + highestLoadingMatchingDimentions + ' best match for: ' + (loadingFound ? 'saved' : 'loading') + ' saved caption: ' + saved.caption);
                results.push({ loading: windowData.loading.splice(highestLoadingIndex, 1)[0], saved: windowData.saved.splice(highestSaveIndex, 1)[0], captionScore: highestLoadingCaptionScore });
                // Do not increase loadingIndex since we need to match first item again
            } else {
                // No save for given confidence level found
                loadingIndex++;
            }
        }

        if (results.length > 0) {
            log('Two way match - caption: ' + confidence.caption + ' matching dimentions: ' + confidence.matchingDimentions + ' allow height shrinking: ' + confidence.allowHeightShrinking + ' matches: ' + results.length);
        }

        return results;
    }

    function restoreWindowsBasedOnConfidence(clientName, minConfidence, repeats) {
        let windowData = config.windows[clientName];
        logE('Timeout restore for client: ' + clientName + ' loading count: ' + windowData.loading.length + ' minConfidence: ' + minConfidence + ' repeats: ' + repeats);

        if (minConfidence > 0 && repeats > 0) {
            if (windowData.lastNonMatchingIndex != undefined && getHighestCaptionScore(windowData, windowData.loading[windowData.lastNonMatchingIndex]) < minConfidence) {
                logE('Still could not find a match for caption: ' + windowData.loading[windowData.lastNonMatchingIndex].caption);
                restoreTimer.setTimeout(1000, clientName, minConfidence, repeats - 1);
                return;
            } else {
                for (let i = 0; i < windowData.loading.length; i++) {
                    if (getHighestCaptionScore(windowData, windowData.loading[i]) < minConfidence) {
                        logE('Could not find a match for caption: ' + windowData.loading[i].caption);
                        windowData.lastNonMatchingIndex = i;
                        restoreTimer.setTimeout(1000, clientName, minConfidence, repeats - 1);
                        return;
                    }
                }
            }
        }

        if (windowData.lastNonMatchingIndex) {
            delete windowData.lastNonMatchingIndex;
        }

        if (windowData.loading.length > 0) {
            let results = [];
            let confidenceIndex = 0;

            while (windowData.loading.length > 0 && confidenceIndex < config.confidence.length) {
                results.push(...twoWayMatch(windowData, config.confidence[confidenceIndex]));
                confidenceIndex++;
            }

            results.sort((a, b) => a.saved.stackingOrder - b.saved.stackingOrder);

            for (let i = 0; i < results.length; i++) {
                restoreWindowPlacement(results[i].saved, results[i].loading, results[i].captionScore);
            }

            windowData.saved = [];
            windowData.loading = [];
        }
    }

    function addWindow(client) {
        if (!isValidWindow(client)) return;
        if (config.printApplicationNameToLog) logAppInfo(client.resourceClass);
        if (config.appsWhitelistedOnly && !config.whitelist.includes(client.resourceClass)) return;
        if (config.appsNotBlacklisted && config.blacklist.includes(client.resourceClass)) return;
        log('Adding window for client: ' + client.resourceClass);
        log('- internalId: ' + client.internalId + ' width: ' + client.width + ' height: ' + client.height);
        log('- caption: ' + client.caption);

        client.closed.connect(onClosed);

        function onClosed() {
            client.closed.disconnect(onClosed);
            removeWindow(client);
        }

        onActivateWindow(client);

        if (!config.windows[client.resourceClass]) {
            config.windows[client.resourceClass] = {
                lastAccessTime: Date.now(),
                windowCount: 0,
                windowCountLastSession: 0,
                instantMatchRestored: 0,
                loading: [],
                closed: [],
                saved: []
            };
        }

        let windowData = config.windows[client.resourceClass];
        windowData.windowCount++;

        if (windowData.saved.length > 0) {
            logE('windowCountLastSession: ' + windowData.windowCountLastSession + ' windowCount: ' + windowData.windowCount);
            if (windowData.windowCountLastSession == 1) {
                if (!config.appsMultiWindowOnly) {
                    // Single window application - just restore it to last known state
                    if (windowData.saved.length == 1) {
                        let captionScore = getHighestCaptionScore(windowData, client);
                        let saved = windowData.saved.splice(0, 1)[0];
                        restoreWindowPlacement(saved, client, captionScore);
                    } else {
                        // This should never happen, but does not hurt to have as backup
                        restoreTimer.setTimeout(1000, client.resourceClass, 0, 0);
                    }
                }
            } else {
                let repeats = config.multiWindowRestoreAttempts;
                if (config.usePerfectMultiWindowRestore && config.perfectMultiWindowRestoreList.includes(client.resourceClass)) {
                    repeats = config.perfectMultiWindowRestoreAttempts;
                }

                if (config.instantRestore) {
                    let instantMatchSaveIndex = windowData.saved.findIndex((s) => client.caption === s.caption && client.width === s.width && client.height === s.height);
                    if (instantMatchSaveIndex != -1) {
                        // Instantly found a 100% match, restore everything except z-index
                        logE('Found multi-window perfect match, instant restoring window - z index will be restored later');
                        restoreWindowPlacement(windowData.saved[instantMatchSaveIndex], client, 100, false);
                        client.rwp_saveIndex = instantMatchSaveIndex;
                        client.rwp_stackingOrder = windowData.saved[instantMatchSaveIndex].stackingOrder;
                        windowData.instantMatchRestored++;
                    }
                }

                windowData.loading.push(client);

                // Backup timer - if captions do not match enough by the timeout, this makes sure windows are restored to best ability
                restoreTimer.setTimeout(repeats * 1000 + 1000 + (windowData.windowCountLastSession * 100), client.resourceClass, 0, 0);

                // All windows from previous session have opened, try to restore based on best caption and size match with minimum caption match of 85
                if (windowData.windowCountLastSession == windowData.windowCount) {
                    // TODO: In case I ever implement caption change listener
                    // TODO: Match captions and if mismatch do:
                    // client.onCaptionChanged.connect(onCaptionChanged);

                    // TODO: Might cause issues with Firefox - revert to "slower" restore for now
                    // Trigger first restore ASAP to make it appear smooth in case all captions match right away
                    //restoreTimer.setTimeout(1, client.resourceClass, 85, repeats + 1);

                    log('All windows for ' + client.resourceClass + ' loaded - windowCountLastSession: ' + windowData.windowCountLastSession + ' instantMatchRestored: ' + windowData.instantMatchRestored);

                    if (config.instantRestore && windowData.instantMatchRestored == windowData.windowCountLastSession) {
                        // All windows restored - restore z-positions
                        restoreTimer.removeTimeoutsFor(client.resourceClass);
                        windowData.loading.sort((a, b) => a.rwp_stackingOrder - b.rwp_stackingOrder);
                        for (let i = 0; i < windowData.loading.length; i++) {
                            restoreWindowPlacement(windowData.saved[windowData.loading[i].rwp_saveIndex], windowData.loading[i], 100);
                        }
                        windowData.saved = [];
                        windowData.loading = [];
                    } else {
                        restoreTimer.setTimeout(1000, client.resourceClass, 85, repeats);
                    }
                    windowData.instantMatchRestored = 0;
                }
            }
        }

        // TODO: In case I ever implement caption change listener
        // function onCaptionChanged() {
        //     client.captionChanged.disconnect(onCaptionChanged);
        // }
    }

    function removeWindow(client) {
        if (!isValidWindow(client)) return;

        let windowData = config.windows[client.resourceClass];

        log('Removing window for client: ' + client.resourceClass);
        log(' - internalId: ' + client.internalId);
        log(' - windowCount: ' + windowData.windowCount);
        log(' - caption: ' + client.caption);

        if (windowData && windowData.windowCount > 0) {
            windowData.windowCount--;

            // Starting to close windows - save order in case all windows are closed to be able to restore the z order
            if (windowData.closed.length == 0 || (Date.now() - windowData.closed[windowData.closed.length - 1].closeTime > 1000)) {
                windowData.windowOrder = [...windowOrder];
            }

            let currentWindowOrder = windowData.windowOrder.indexOf(client.internalId);

            windowData.closed.push({
                internalId    : client.internalId,
                caption       : client.caption.toString(),
                x             : client.x,
                y             : client.y,
                width         : client.width,
                height        : client.height,
                minimized     : client.minimized,
                outputName    : client.output.name,
                stackingOrder : currentWindowOrder == -1 ? client.stackingOrder : currentWindowOrder,
                desktopNumber : client.onAllDesktops ? -1 : client.desktops[0].x11DesktopNumber,
                activities    : [...client.activities],
                closeTime     : Date.now()
            });

            if (windowData.windowCount == 0) {
                windowData.loading = [];
                windowData.saved = [];
                windowData.lastAccessTime = Date.now();
                windowData.windowCountLastSession = 0;

                var saving = windowData.closed.pop();
                var lastValidClosingTime = Date.now();

                while (saving != undefined) {
                    let index = windowOrder.indexOf(saving.internalId);

                    if (index != -1) {
                        windowOrder.splice(index, 1);
                        delete saving.internalId;
                    }

                    log('Closing - time since last: ' + (lastValidClosingTime - saving.closeTime));
                    if (lastValidClosingTime - saving.closeTime <= 1000) {
                        // Valid save
                        windowData.windowCountLastSession++;
                        windowData.saved.push(saving);
                        lastValidClosingTime = saving.closeTime;
                    }

                    saving = windowData.closed.pop();
                }

                delete windowData.windowOrder;

                // Save to settings
                saveWindowsToSettings();

                if (config.printApplicationNameToLog) logAppInfoOnClose(client.resourceClass, windowData.saved.length);
            }
        }
    }

    function clearExpiredApps() {
        let changed = false;

        // Remove saves for all apps that have not been accessed for 30 days
        // TODO: Make this a setting perhaps - 7 - 90 days?
        const expirationDate = Date.now() - (30 * 24 * 60 * 60 * 1000);

        for (let key in config.windows) {
            if (config.windows[key].lastAccessTime < expirationDate) {
                log('Clearing expired app: ' + key);
                delete config.windows[key];
                changed = true;
            }
        }

        if (changed) {
            // Save after cleanup
            saveWindowsToSettings();
        }
    }

    function cacheWindowOrder() {
        windowOrder = [];
        const clients = Workspace.stackingOrder;
        for (var i = 0; i < clients.length; i++) {
            windowOrder.push(clients[i].internalId);
        }
    }

    function onActivateWindow(client) {
        if (!isValidWindow(client)) return;
        let index = windowOrder.indexOf(client.internalId);
        if (index != -1) {
            windowOrder.splice(index, 1);
        }
        windowOrder.push(client.internalId);
    }

    Timer {
        id: restoreTimer

        property var timeoutIsRunning: false
        property var timeoutData: []

        function setTimeout(delay, name, minConfidence, repeats) {
            logE('Setting timout for ' + delay + ' isRunning: ' + timeoutIsRunning + ' timer count: ' + timeoutData.length);
            timeoutData.push({time: Date.now() + delay, name: name, minConfidence: minConfidence, repeats: repeats});
            timeoutData.sort((a, b) => a.time - b.time);

            if (!timeoutIsRunning) {
                restoreTimer.interval = 250;
                restoreTimer.repeat = true,
                restoreTimer.triggered.connect(onTimeoutTriggered);
                timeoutIsRunning = true;

                restoreTimer.start();
            }
        }

        function removeTimeoutsFor(name) {
            for (var i = timeoutData.length - 1; i >= 0; i--) {
                if (timeoutData[i].name == name) {
                    timeoutData.splice(i, 1);
                }
            }
            if (timeoutData.length == 0 && timeoutIsRunning) {
                restoreTimer.triggered.disconnect(onTimeoutTriggered);
                timeoutIsRunning = false;
                restoreTimer.stop();
            }
        }

        function onTimeoutTriggered() {
            while (timeoutData.length > 0 && timeoutData[0].time <= Date.now()) {
                let data = timeoutData.shift();
                restoreWindowsBasedOnConfidence(data.name, data.minConfidence, data.repeats);
            }

            if (timeoutData.length == 0) {
                restoreTimer.triggered.disconnect(onTimeoutTriggered);
                timeoutIsRunning = false;
                restoreTimer.stop();
            }
        }
    }

    function loadWindowsFromSettings() {
        let savedWindows = JSON.parse(settings.rememberwindowpositions_windows);
        let convertedWindows = {};

        logE('Loading application windows from settings');

        for (let key in savedWindows) {
            let window = savedWindows[key];
            convertedWindows[key] = {
                saved                  : [],       // saved
                lastAccessTime         : window.l, // lastAccessTime
                windowCountLastSession : window.w, // windowCountLastSession
                windowCount            : 0,        // windowCount
                instantMatchRestored   : 0,        // instantMatchRestored
                loading                : [],       // loading
                closed                 : []        // closed
            }
            logE('Saved windows for: ' + key + ' windowCountLastSession: ' + window.w + ' lastAccessTime: ' + window.l);

            for (let i = 0; i < window.s.length; i++) {
                let save = window.s[i];
                convertedWindows[key].saved.push({
                    caption       : save.c,      // caption
                    x             : save.x,      // x
                    y             : save.y,      // y
                    width         : save.w,      // width
                    height        : save.h,      // height
                    minimized     : save.m == 1, // minimized
                    outputName    : save.o,      // outputName
                    stackingOrder : save.s,      // stackingOrder
                    desktopNumber : save.d,      // desktopNumber
                    activities    : save.a       // activities
                    // --- Ommited fields ---
                    // closeTime  : save.t       // closeTime
                    // internalId : save.i       // internalId
                });
                log('Window ' + i + ' - x: ' + save.x + ' y: ' + save.y + ' width: ' + save.w + ' height: ' + save.h + ' minimized: ' + (save.m == 1) + ' outputName: ' + save.o + ' stackingNumber: ' + save.s + ' desktopNumber: ' + save.d);
                log('- activities: ' + JSON.stringify(save.a));
                log('- caption: ' + save.c + '\n');
            }
        }

        //log('Load - converted windows: ' + JSON.stringify(convertedWindows));
        config.windows = convertedWindows;
    }

    function saveWindowsToSettings() {
        // Convert save data to minimaze size in storage - ommit all data that is not relevant for the save
        let convertedWindows = {};

        for (let key in config.windows) {
            let window = config.windows[key];
            if (window.saved.length > 0) {
                convertedWindows[key] = {
                    s: [],                            // saved
                    l: window.lastAccessTime,         // lastAccessTime
                    w: window.windowCountLastSession  // windowCountLastSession
                    // --- Ommited fields ---
                    // c: window.windowCount          // windowCount
                    // i: window.instantMatchRestored // instantMatchRestored
                    // o: window.loading              // loading
                    // e: window.closed               // closed
                };
                for (let i = 0; i < window.saved.length; i++) {
                    let save = window.saved[i];
                    convertedWindows[key].s.push({
                        c: save.caption,           // caption
                        x: save.x,                 // x
                        y: save.y,                 // y
                        w: save.width,             // width
                        h: save.height,            // height
                        m: save.minimized ? 1 : 0, // minimized
                        o: save.outputName,        // outputName
                        s: save.stackingOrder,     // stackingOrder
                        d: save.desktopNumber,     // desktopNumber
                        a: save.activities         // activities
                        // --- Ommited fields ---
                        // t: save.closeTime       // closeTime
                        // i: save.internalId      // internalId
                    });
                }
            }
        }

        // log('Save - converted windows: ' + JSON.stringify(convertedWindows));
        log('Attempting to save windows...');
        settings.rememberwindowpositions_windows = JSON.stringify(convertedWindows);
        log('Windows saved!');
    }

    Settings {
        // Saved in default settings file ~/.config/kde.org/kwin.conf
        id: settings
        property string rememberwindowpositions_windows: "{}"
    }

    Connections {
        target: Workspace

        function onWindowAdded(client) {
            addWindow(client);
        }

        // Using client.closed.connect(onClosed); instead since it's faster and more accurate
        // function onWindowRemoved(client) {
        //     removeWindow(client);
        // }

        function onWindowActivated(client) {
            onActivateWindow(client);
        }
    }

    Component.onCompleted: {
        debugLogs = KWin.readConfig("debugLogs", false);
        // Script is loaded - init config
        log('Loaded...');
        cacheWindowOrder();
        loadConfig();
        loadWindowsFromSettings();

        // Add existing windows
        const clients = Workspace.stackingOrder;
        for (var i = 0; i < clients.length; i++) {
            addWindow(clients[i]);
        }

        // Clear expired apps to reduce used save-file space
        clearExpiredApps();

        // logE('config:\n' + JSON.stringify(config));
    }

    Component.onDestruction: {
        log('Closing...');
        saveWindowsToSettings();
    }
}
