import AppKit
import Foundation
import RobloxAccountManagerCore
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var accounts: [AccountRecord] = []
    @Published var settings = AppSettings()
    @Published var selectedAccountID: UUID?
    @Published var searchText = ""
    @Published var statusMessage = "Ready"
    @Published var logText = ""
    @Published var showingSettings = false
    @Published var showingAccountEditor = false
    @Published var editingAccount: AccountRecord?
    @Published var pendingSecret = AccountSecret(robloxSecurityCookie: "")
    private var cleanupTimers: [pid_t: Timer] = [:]

    let storage: FileStorage
    let keychain: KeychainStore
    let importer = ImportExportService()
    let launcher = RobloxLaunchService()
    let multiInstance: MultiInstanceService

    init() {
        do {
            storage = try FileStorage()
            keychain = KeychainStore()
            multiInstance = try MultiInstanceService()
            accounts = try storage.loadAccounts()
            settings = try storage.loadSettings()
            selectedAccountID = accounts.first?.id
            logText = try storage.readLog()
            log("Application started.")
        } catch {
            fatalError("Failed to initialize storage: \(error.localizedDescription)")
        }
    }

    var filteredAccounts: [AccountRecord] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return accounts.sorted(by: accountSort) }
        return accounts.filter {
            $0.username.lowercased().contains(needle)
                || $0.group.lowercased().contains(needle)
                || $0.description.lowercased().contains(needle)
        }
        .sorted(by: accountSort)
    }

    var selectedAccount: AccountRecord? {
        guard let selectedAccountID else { return nil }
        return accounts.first { $0.id == selectedAccountID }
    }

    func addAccount() {
        editingAccount = nil
        pendingSecret = AccountSecret(robloxSecurityCookie: "")
        showingAccountEditor = true
    }

    func editSelectedAccount() {
        guard let selectedAccount else { return }
        editingAccount = selectedAccount
        pendingSecret = (try? keychain.readSecret(accountID: selectedAccount.id)) ?? AccountSecret(robloxSecurityCookie: "")
        showingAccountEditor = true
    }

    func saveAccount(record: AccountRecord, secret: AccountSecret) {
        do {
            guard !record.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ValidationError("Username is required.")
            }
            guard !secret.robloxSecurityCookie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ValidationError(".ROBLOSECURITY token is required.")
            }

            var updated = record
            updated.updatedAt = Date()
            if let index = accounts.firstIndex(where: { $0.id == updated.id }) {
                accounts[index] = updated
            } else {
                accounts.append(updated)
            }

            let storedSecret = settings.savePasswords ? secret : AccountSecret(robloxSecurityCookie: secret.robloxSecurityCookie)
            try keychain.saveSecret(storedSecret, accountID: updated.id)
            try storage.saveAccounts(accounts)
            selectedAccountID = updated.id
            showingAccountEditor = false
            log("Saved account \(updated.username).")
        } catch {
            report(error)
        }
    }

    func deleteSelectedAccount() {
        guard let selectedAccount else { return }
        do {
            accounts.removeAll { $0.id == selectedAccount.id }
            try keychain.deleteSecret(accountID: selectedAccount.id)
            try storage.saveAccounts(accounts)
            selectedAccountID = accounts.first?.id
            log("Deleted account \(selectedAccount.username).")
        } catch {
            report(error)
        }
    }

    func saveSettings() {
        do {
            try storage.saveSettings(settings)
            log("Saved settings.")
        } catch {
            report(error)
        }
    }

    func backupAccounts() {
        do {
            let url = try storage.backupAccounts()
            log("Created metadata backup at \(url.path).")
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            report(error)
        }
    }

    func cleanupMultiInstanceCopies() {
        do {
            try multiInstance.cleanupManagedCopies()
            log("Cleaned multi-instance Roblox app copies.")
        } catch {
            report(error)
        }
    }

    func exportAccounts() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MacOS-RobloxAccountManager-Accounts.json"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try importer.encodeExport(importer.makeExport(accounts: accounts))
            try data.write(to: url, options: [.atomic])
            log("Exported account metadata to \(url.path).")
        } catch {
            report(error)
        }
    }

    func importAccounts() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let envelope = try importer.decodeImport(Data(contentsOf: url), allowPlaintextSecrets: false)
            for item in envelope.accounts {
                if !accounts.contains(where: { $0.id == item.record.id }) {
                    accounts.append(item.record)
                }
            }
            try storage.saveAccounts(accounts)
            selectedAccountID = accounts.first?.id
            log("Imported \(envelope.accounts.count) account metadata records from \(url.path).")
        } catch {
            report(error)
        }
    }

    func launchSelectedAccount() {
        guard settings.allowAccountLaunch && settings.allowRbxPlayerLinks else {
            report(RobloxLaunchError.launchDisabled)
            return
        }
        guard let account = selectedAccount else { return }
        let request = RobloxLaunchRequest(placeID: account.savedPlaceID, jobID: account.savedJobID)

        Task {
            do {
                guard let secret = try keychain.readSecret(accountID: account.id) else {
                    throw RobloxLaunchError.emptyCookie
                }
                log("Requesting Roblox authentication ticket for \(account.username).")
                let ticket = try await launcher.fetchAuthenticationTicket(cookie: secret.robloxSecurityCookie)
                let url = try launcher.buildLaunchURL(ticket: ticket, request: request)
                if settings.allowMultiInstance {
                    log("Preparing multi-instance Roblox app copy for \(account.username).")
                    let preparation = try multiInstance.prepareRobloxApplicationCopy(accountID: account.id)
                    if !preparation.singletonSemaphoreReleased {
                        log("Multi-instance warning: Roblox single-instance semaphore could not be released. Launch may still fail.")
                    }
                    try openRoblox(url, account: account, request: request, applicationURL: preparation.applicationURL)
                } else {
                    try openRoblox(url, account: account, request: request)
                }
            } catch {
                report(error)
            }
        }
    }

    private func openRoblox(
        _ url: URL,
        account: AccountRecord,
        request: RobloxLaunchRequest,
        applicationURL: URL? = nil
    ) throws {
        if let applicationURL {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open([url], withApplicationAt: applicationURL, configuration: configuration) { runningApplication, error in
                Task { @MainActor in
                    if let error {
                        self.report(ValidationError("macOS could not launch the Roblox app copy: \(error.localizedDescription)"))
                        try? self.multiInstance.cleanupManagedCopy(at: applicationURL)
                        return
                    }
                    if let runningApplication {
                        self.cleanupCopy(applicationURL, whenApplicationTerminates: runningApplication)
                    } else {
                        self.report(ValidationError("macOS launched the Roblox app copy but did not return a running application handle. The copy may need manual cleanup later."))
                    }
                    self.markUsed(account)
                    self.log("Opened Roblox app copy for \(account.username) at Place ID \(request.placeID).")
                }
            }
            return
        }

        guard NSWorkspace.shared.open(url) else {
            throw ValidationError("macOS did not accept the Roblox launch URL. Reinstall Roblox or check the roblox-player URL handler.")
        }
        markUsed(account)
        log("Opened Roblox for \(account.username) at Place ID \(request.placeID).")
    }

    private func cleanupCopy(_ applicationURL: URL, whenApplicationTerminates application: NSRunningApplication) {
        let processIdentifier = application.processIdentifier
        cleanupTimers[processIdentifier]?.invalidate()
        cleanupTimers[processIdentifier] = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self, weak application] timer in
            guard let self, let application else {
                timer.invalidate()
                return
            }
            guard application.isTerminated else { return }
            timer.invalidate()
            Task { @MainActor in
                self.cleanupTimers[processIdentifier] = nil
                do {
                    try self.multiInstance.cleanupManagedCopy(at: applicationURL)
                    self.log("Removed multi-instance Roblox app copy after Roblox closed.")
                } catch {
                    self.report(error)
                }
            }
        }
    }

    private func markUsed(_ account: AccountRecord) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index].lastUsedAt = Date()
        accounts[index].updatedAt = Date()
        try? storage.saveAccounts(accounts)
    }

    private func accountSort(lhs: AccountRecord, rhs: AccountRecord) -> Bool {
        if lhs.group != rhs.group { return lhs.group.localizedCaseInsensitiveCompare(rhs.group) == .orderedAscending }
        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }

    private func report(_ error: Error) {
        log("ERROR: \(error.localizedDescription)")
    }

    private func log(_ message: String) {
        statusMessage = message
        try? storage.appendLog(message)
        logText = (try? storage.readLog()) ?? logText
    }
}

struct ValidationError: LocalizedError {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
