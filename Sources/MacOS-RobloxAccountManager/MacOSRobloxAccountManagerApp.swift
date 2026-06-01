import SwiftUI

@main
struct MacOSRobloxAccountManagerApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 620)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Account") { store.addAccount() }
                    .keyboardShortcut("n")
                Button("Edit Account") { store.editSelectedAccount() }
                    .keyboardShortcut("e")
                    .disabled(store.selectedAccount == nil)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

