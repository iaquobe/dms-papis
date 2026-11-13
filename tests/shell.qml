import QtQuick
import Quickshell
import Quickshell.Io
import "." as Plugin

ShellRoot {
    id: testRoot

    QtObject {
        id: settings
        signal pluginDataChanged(string pluginId)
        function loadPluginData(pluginId, key, fallback) { return fallback; }
        function savePluginData(pluginId, key, value) {}
    }

    Plugin.PapisLauncher {
        id: launcher
        pluginService: settings
        onItemsChanged: if (loaded) Qt.callLater(testRoot.runChecks)
    }

    property FileView completionFile: FileView {
        path: Quickshell.env("PAPIS_TEST_RESULT")
        blockWrites: true
    }

    property bool done: false

    function check(condition, label) {
        if (!condition)
            throw new Error(label);
    }

    function runChecks() {
        if (done)
            return;
        done = true;
        try {
            const all = launcher.getItems("");
            check(all.length === 3, "expected 3 documents, got " + all.length);
            check(all[0].name === "Attention Is All You Need", "first title: " + all[0].name);
            check(all[0].comment === "Vaswani, Ashish · 2017", "comment: " + all[0].comment);
            check(all[0].action === "open:id1", "action: " + all[0].action);
            check(all[2].name === "(untitled)" || all[2].name.length > 0, "untitled handling");

            const byAuthor = launcher.getItems("knuth");
            check(byAuthor.length === 1 && byAuthor[0].action === "open:id2", "author search");
            const multi = launcher.getItems("art programming 1968");
            check(multi.length === 1 && multi[0].action === "open:id2", "multi-token search");
            check(launcher.getItems("nonexistent words").length === 0, "no match");
            const ranked = launcher.getItems("attention");
            check(ranked[0].action === "open:id1", "title prefix ranks first");

            check(launcher.getPasteText(all[0]) === "Attention Is All You Need", "paste text");
            console.log("PASS: papis launcher listing, search, ranking and paste text");
            completionFile.setText("passed");
            Qt.exit(0);
        } catch (error) {
            console.error("FAIL: " + error.message);
            Qt.exit(1);
        }
    }
}
