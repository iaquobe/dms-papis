import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "papisLauncher"

    Component.onCompleted: {
        const currentTrigger = root.loadValue("trigger", ":p");
        if (!currentTrigger || currentTrigger.trim().length === 0)
            root.saveValue("trigger", ":p");
    }

    StyledText {
        width: parent.width
        text: "Papis Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Search the documents in your papis library and open them from the launcher."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StringSetting {
        settingKey: "trigger"
        label: "Trigger"
        description: "Examples: :p, pa, etc. Avoid triggers reserved by DMS or other plugins (e.g., / for file search)."
        placeholder: ":p"
        defaultValue: ":p"
    }

    ToggleSetting {
        settingKey: "useDMS"
        label: "Clipboard Program"
        description: value ? "Use DMS clipboard command (dms cl copy) with wl-copy fallback." : "Use wl-copy for clipboard operations."
        defaultValue: true
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Usage"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingXS
        leftPadding: Theme.spacingM
        bottomPadding: Theme.spacingL

        Repeater {
            model: ["1. Open Launcher (Ctrl+Space or click launcher button)", "2. Type your trigger (default: :p) followed by words from the title, author or year", "3. Press Enter to open the document with 'papis open'", "4. Press Shift+Enter to paste the title into the focused app"]

            StyledText {
                required property string modelData
                text: modelData
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
