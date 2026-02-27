import SwiftUI

#if os(macOS)
struct AppCommands: Commands {
    @FocusedValue(\.refreshAction) var refreshAction
    @FocusedValue(\.newCheckAction) var newCheckAction
    @FocusedValue(\.deleteCheckAction) var deleteCheckAction
    @FocusedValue(\.pauseCheckAction) var pauseCheckAction
    @FocusedValue(\.viewOnStatusCakeAction) var viewOnStatusCakeAction
    @FocusedValue(\.hasSelection) var hasSelection

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Check") {
                newCheckAction?()
            }
            .keyboardShortcut("n", modifiers: .command)
            Divider()
        }
        CommandGroup(after: .sidebar) {
            Button("Refresh") {
                refreshAction?()
            }
            .keyboardShortcut("r", modifiers: .command)
            Divider()
        }
        CommandMenu("Check") {
            Button("Pause/Resume Check") {
                pauseCheckAction?()
            }
            .disabled(hasSelection != true)

            Button("View on StatusCake") {
                viewOnStatusCakeAction?()
            }
            .disabled(hasSelection != true)

            Divider()

            Button("Delete Check") {
                deleteCheckAction?()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(hasSelection != true)
        }
    }
}

private struct RefreshActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
private struct NewCheckActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
private struct DeleteCheckActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
private struct PauseCheckActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
private struct ViewOnStatusCakeActionKey: FocusedValueKey {
    typealias Value = () -> Void
}
private struct HasSelectionKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var refreshAction: (() -> Void)? {
        get { self[RefreshActionKey.self] }
        set { self[RefreshActionKey.self] = newValue }
    }
    var newCheckAction: (() -> Void)? {
        get { self[NewCheckActionKey.self] }
        set { self[NewCheckActionKey.self] = newValue }
    }
    var deleteCheckAction: (() -> Void)? {
        get { self[DeleteCheckActionKey.self] }
        set { self[DeleteCheckActionKey.self] = newValue }
    }
    var pauseCheckAction: (() -> Void)? {
        get { self[PauseCheckActionKey.self] }
        set { self[PauseCheckActionKey.self] = newValue }
    }
    var viewOnStatusCakeAction: (() -> Void)? {
        get { self[ViewOnStatusCakeActionKey.self] }
        set { self[ViewOnStatusCakeActionKey.self] = newValue }
    }
    var hasSelection: Bool? {
        get { self[HasSelectionKey.self] }
        set { self[HasSelectionKey.self] = newValue }
    }
}
#endif

@main
struct StatusBakeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            AppCommands()
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
