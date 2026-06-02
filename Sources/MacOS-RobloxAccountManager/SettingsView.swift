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
                    Toggle("Allow account launching", isOn: $store.settings.allowAccountLaunch)
                    Toggle("Allow roblox-player launch URLs", isOn: $store.settings.allowRbxPlayerLinks)
                    Text("Set the universal Game ID / Place ID and optional Job ID above the Launch Roblox button in the account detail view.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Advanced") {
                    Toggle("Developer API", isOn: $store.settings.allowDeveloperAPI)
                    TextField("Developer API port", value: $store.settings.developerAPIPort, format: .number)
                        .disabled(true)

                    Toggle("Multi-instance mode", isOn: $store.settings.allowMultiInstance)
                    if store.settings.allowMultiInstance {
                        Text("Multi-instance is experimental. It launches through managed Roblox app copies and may break when Roblox updates.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("Developer API is intentionally disabled. Multi-instance does not modify the installed Roblox app. Temporary app copies are removed after the launched Roblox instance closes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Security", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                Text("Only use accounts you own. Never share tokens, exported files containing secrets, or roblox-player links.")
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

                Button {
                    store.cleanupMultiInstanceCopies()
                } label: {
                    Label("Clean Multi-Instance Copies", systemImage: "trash")
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
