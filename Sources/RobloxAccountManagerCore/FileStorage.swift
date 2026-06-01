import Foundation

public enum StorageError: LocalizedError {
    case applicationSupportUnavailable

    public var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            "The Application Support directory could not be located."
        }
    }
}

public struct FileStorage: Sendable {
    public let rootDirectory: URL
    public let accountsURL: URL
    public let settingsURL: URL
    public let logURL: URL

    public init(rootDirectory: URL? = nil) throws {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw StorageError.applicationSupportUnavailable
            }
            self.rootDirectory = appSupport.appendingPathComponent("MacOS-RobloxAccountManager", isDirectory: true)
        }
        self.accountsURL = self.rootDirectory.appendingPathComponent("Accounts.json")
        self.settingsURL = self.rootDirectory.appendingPathComponent("Settings.json")
        self.logURL = self.rootDirectory.appendingPathComponent("Logs.txt")
        try FileManager.default.createDirectory(at: self.rootDirectory, withIntermediateDirectories: true)
    }

    public func loadAccounts() throws -> [AccountRecord] {
        guard FileManager.default.fileExists(atPath: accountsURL.path) else { return [] }
        let data = try Data(contentsOf: accountsURL)
        return try JSONCoding.decoder.decode([AccountRecord].self, from: data)
    }

    public func saveAccounts(_ accounts: [AccountRecord]) throws {
        let data = try JSONCoding.encoder.encode(accounts)
        try atomicWrite(data, to: accountsURL)
    }

    public func loadSettings() throws -> AppSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return AppSettings() }
        let data = try Data(contentsOf: settingsURL)
        return try JSONCoding.decoder.decode(AppSettings.self, from: data)
    }

    public func saveSettings(_ settings: AppSettings) throws {
        let data = try JSONCoding.encoder.encode(settings)
        try atomicWrite(data, to: settingsURL)
    }

    public func backupAccounts() throws -> URL {
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupURL = rootDirectory.appendingPathComponent("Accounts-\(stamp).backup.json")
        let accounts = try loadAccounts()
        let envelope = ImportExportService().makeExport(accounts: accounts)
        let data = try ImportExportService().encodeExport(envelope)
        try atomicWrite(data, to: backupURL)
        return backupURL
    }

    public func appendLog(_ message: String) throws {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        let data = Data(line.utf8)
        if FileManager.default.fileExists(atPath: logURL.path) {
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } else {
            try atomicWrite(data, to: logURL)
        }
    }

    public func readLog() throws -> String {
        guard FileManager.default.fileExists(atPath: logURL.path) else { return "" }
        return try String(contentsOf: logURL, encoding: .utf8)
    }

    private func atomicWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
    }
}

