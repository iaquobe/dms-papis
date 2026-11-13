import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    readonly property string pluginId: "papisLauncher"
    // Fields requested from papis, separated by tabs (one document per line).
    readonly property string listFormat: "{doc[papis_id]}\t{doc[title]}\t{doc[author]}\t{doc[year]}"
    // Re-run `papis list` at most this often while the launcher is used.
    readonly property int refreshIntervalMs: 60000

    property var pluginService: null
    property string trigger: ":p"
    property bool useDMS: true

    signal itemsChanged

    // [{id, title, author, year, search}]
    property var documents: []
    property string loadError: ""
    property bool loaded: false
    property double lastRefresh: 0

    Component.onCompleted: {
        loadSettings();
        refreshDocuments();
    }

    onPluginServiceChanged: {
        if (pluginService)
            loadSettings();
    }

    property var pluginDataChangedConnection: Connections {
        target: pluginService
        enabled: pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.loadSettings();
        }
    }

    property var listProcess: Process {
        command: ["papis", "list", "--all", "--format", root.listFormat]
        stdout: StdioCollector {
            onStreamFinished: root.parseDocuments(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("papisLauncher: papis list:", text.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loadError = "papis list exited with code " + exitCode;
                root.itemsChanged();
            }
        }
    }

    function loadSettings() {
        if (!pluginService)
            return;
        trigger = pluginService.loadPluginData(pluginId, "trigger", ":p");
        useDMS = pluginService.loadPluginData(pluginId, "useDMS", true);
    }

    function refreshDocuments() {
        if (listProcess.running)
            return;
        lastRefresh = Date.now();
        loadError = "";
        listProcess.running = true;
    }

    function parseDocuments(output) {
        const docs = [];
        const lines = String(output || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.trim().length === 0)
                continue;
            const fields = line.split("\t");
            const doc = {
                id: (fields[0] || "").trim(),
                title: (fields[1] || "").trim(),
                author: (fields[2] || "").trim(),
                year: (fields[3] || "").trim()
            };
            if (!doc.id && !doc.title)
                continue;
            doc.search = (doc.title + " " + doc.author + " " + doc.year).toLowerCase();
            docs.push(doc);
        }
        documents = docs;
        loaded = true;
        itemsChanged();
    }

    function tokenizeQuery(query) {
        const trimmed = String(query || "").trim().toLowerCase();
        return trimmed.length === 0 ? [] : trimmed.split(/\s+/);
    }

    // Higher is better; 0 means no match. Every token must match somewhere.
    function scoreDocument(doc, lowerQuery, tokens) {
        const titleLower = doc.title.toLowerCase();
        let score = 1000;
        if (titleLower === lowerQuery)
            score += 3000;
        else if (titleLower.startsWith(lowerQuery))
            score += 2000;
        else if (titleLower.includes(lowerQuery))
            score += 1000;

        for (let i = 0; i < tokens.length; i++) {
            const token = tokens[i];
            const titlePos = titleLower.indexOf(token);
            if (titlePos !== -1)
                score += titlePos === 0 || /\W/.test(titleLower.charAt(titlePos - 1)) ? 60 : 30;
            else if (doc.search.includes(token))
                score += 10;
            else
                return 0;
        }
        return score;
    }

    function makeItem(doc, score, index) {
        const details = [doc.author, doc.year].filter(part => part.length > 0).join(" · ");
        return {
            name: doc.title || "(untitled)",
            comment: details,
            action: "open:" + doc.id,
            icon: "material:description",
            categories: ["Papis Documents"],
            _title: doc.title,
            _preScored: score,
            _idx: index
        };
    }

    function getItems(query) {
        if (!listProcess.running && (!loaded || Date.now() - lastRefresh > refreshIntervalMs))
            refreshDocuments();

        if (!loaded || documents.length === 0) {
            let message = "Loading papis documents…";
            if (loadError)
                message = "Could not list papis documents";
            else if (loaded)
                message = "No papis documents found";
            return [{
                name: message,
                comment: loadError || "papis list --all",
                action: "none:",
                icon: "material:description",
                categories: ["Papis Documents"]
            }];
        }

        const trimmedQuery = String(query || "").trim();
        const items = [];
        if (trimmedQuery.length === 0) {
            for (let i = 0; i < documents.length && items.length < 50; i++)
                items.push(makeItem(documents[i], 0, i));
            return items;
        }

        const lowerQuery = trimmedQuery.toLowerCase();
        const tokens = tokenizeQuery(trimmedQuery);
        for (let i = 0; i < documents.length; i++) {
            const score = scoreDocument(documents[i], lowerQuery, tokens);
            if (score > 0)
                items.push(makeItem(documents[i], score, i));
        }
        items.sort((a, b) => b._preScored - a._preScored || a._idx - b._idx);
        return items.slice(0, 50);
    }

    function findDocument(id) {
        for (let i = 0; i < documents.length; i++) {
            if (documents[i].id === id)
                return documents[i];
        }
        return null;
    }

    function executeItem(item) {
        if (!item?.action)
            return;
        const separator = item.action.indexOf(":");
        const actionType = item.action.slice(0, separator);
        const id = item.action.slice(separator + 1);
        if (actionType !== "open")
            return;

        const doc = findDocument(id);
        // Prefer the unique papis_id; fall back to a title query for libraries
        // whose papis version does not provide ids.
        const query = id ? "papis_id:" + id : (doc ? doc.title : item._title || item.name);
        Quickshell.execDetached(["setsid", "papis", "open", query]);
        ToastService?.showInfo("Opening " + (doc ? doc.title : item.name));
    }

    // Shift+Enter pastes the document title into the focused app.
    function getPasteText(item) {
        if (!item?.action || !item.action.startsWith("open:"))
            return null;
        const doc = findDocument(item.action.slice(5));
        return doc ? doc.title : (item._title || item.name);
    }

    function getPasteArgs(item) {
        const text = getPasteText(item);
        if (!text)
            return null;
        const copyCommand = useDMS
            ? "if command -v dms >/dev/null 2>&1; then printf '%s' \"$1\" | setsid dms cl copy; else printf '%s' \"$1\" | wl-copy; fi"
            : "printf '%s' \"$1\" | wl-copy";
        return ["sh", "-c", copyCommand, "copy", text];
    }

    onTriggerChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData(pluginId, "trigger", trigger);
        itemsChanged();
    }

    onUseDMSChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData(pluginId, "useDMS", useDMS);
    }
}
