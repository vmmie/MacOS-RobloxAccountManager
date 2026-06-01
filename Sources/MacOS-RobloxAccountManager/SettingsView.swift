import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.title.bold())

            Form {
                Section("General") {
                    Toggle("Save optional account passwords in Keychain", isOn: $store.settings.savePasswords)
                    Stepper("Launch delay: \(store.settings.launchDelaySeconds) seconds", value: $store.settings.launchDelaySeconds, in: 0...60)
                }

                Section("Risky Features") {
                    Toggle("Allow account launching", isOn: $store.settings.allowAccountLaunch)
                    Toggle("Allow rbx-player launch URLs", isOn: $store.settings.allowRbxPlayerLinks)
                    Toggle("Developer API", isOn: $store.settings.allowDeveloperAPI)
                    TextField("Developer API port", value: $store.settings.developerAPIPort, format: .number)
                        .disabled(true)

                    Toggle("Multi-instance mode", isOn: $store.settings.allowMultiInstance)
                        .disabled(true)
                    Text("Developer API and multi-instance mode are intentionally disabled in v0.1.0. The Windows port uses local web server/websocket code and a Windows named mutex; this macOS port does not ship an unsafe replacement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Security", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                Text("Only use accounts you own. Never share cookies, exported files containing secrets, or rbx-player links. Launching is disabled by default because Roblox launch links can give control of a session to whoever receives them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Button {
                    store.backupAccounts()
                } label: {
                    Label("Backup Metadata", systemImage: "externaldrive")
                }

                Spacer()

                Button("Done") {
                    store.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .onDisappear {
            store.saveSettings()
        }
    }
}

