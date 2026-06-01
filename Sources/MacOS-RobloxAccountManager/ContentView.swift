import RobloxAccountManagerCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationSplitView {
            AccountSidebar()
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } detail: {
            AccountDetailView(account: store.selectedAccount)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.addAccount()
                } label: {
                    Label("Add", systemImage: "plus")
                }

                Button {
                    store.editSelectedAccount()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(store.selectedAccount == nil)

                Button {
                    store.showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            StatusBar()
        }
        .sheet(isPresented: $store.showingAccountEditor) {
            AccountEditorView(
                original: store.editingAccount,
                secret: store.pendingSecret
            )
            .environmentObject(store)
        }
        .sheet(isPresented: $store.showingSettings) {
            SettingsView()
                .environmentObject(store)
                .frame(width: 560, height: 520)
        }
    }
}

struct AccountSidebar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            List(store.filteredAccounts, selection: $store.selectedAccountID) { account in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(account.displayName)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                        Text(account.group)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(account.username)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
                .tag(account.id)
            }
            .searchable(text: $store.searchText, placement: .sidebar, prompt: "Search accounts")

            HStack {
                Button {
                    store.importAccounts()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Button {
                    store.exportAccounts()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(.borderless)
            .padding(10)
        }
    }
}

struct AccountDetailView: View {
    @EnvironmentObject private var store: AppStore
    let account: AccountRecord?

    var body: some View {
        Group {
            if let account {
                VStack(alignment: .leading, spacing: 20) {
                    header(account)
                    actionRow(account)
                    details(account)
                    logPanel
                    Spacer()
                }
                .padding(24)
            } else {
                ContentUnavailableView("No Account Selected", systemImage: "person.crop.circle.badge.questionmark", description: Text("Add an account or select one from the sidebar."))
            }
        }
    }

    private func header(_ account: AccountRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(account.displayName)
                .font(.largeTitle.bold())
                .lineLimit(1)
            Text(account.username)
                .font(.title3)
                .foregroundStyle(.secondary)
            if !account.description.isEmpty {
                Text(account.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private func actionRow(_ account: AccountRecord) -> some View {
        HStack(spacing: 10) {
            Button {
                store.launchSelectedAccount()
            } label: {
                Label("Launch Roblox", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.settings.allowAccountLaunch || !store.settings.allowRbxPlayerLinks || account.savedPlaceID.isEmpty)
            .help("Uses Roblox's roblox-player URL handler.")

            Button {
                store.editSelectedAccount()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.deleteSelectedAccount()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func details(_ account: AccountRecord) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            detailRow("Group", account.group)
            detailRow("Saved Game ID / Place ID", account.savedPlaceID.isEmpty ? "Not set" : account.savedPlaceID)
            detailRow("Saved Job ID", account.savedJobID.isEmpty ? "Not set" : account.savedJobID)
            detailRow("Last Used", account.lastUsedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
            detailRow("Stored Data", "Metadata in Application Support, tokens in macOS Keychain")
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Logs")
                .font(.headline)
            ScrollView {
                Text(store.logText.isEmpty ? "No logs yet." : store.logText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 140)
            .padding(10)
            .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct StatusBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack {
            Text(store.statusMessage)
                .lineLimit(1)
            Spacer()
            if !store.settings.allowAccountLaunch {
                Label("Launch disabled", systemImage: "lock.fill")
            }
            if !store.settings.allowDeveloperAPI {
                Label("Developer API off", systemImage: "network.slash")
            }
            if store.settings.allowMultiInstance {
                Label("Multi-instance on", systemImage: "rectangle.stack")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.bar)
    }
}
