import Darwin
import Foundation

public enum MultiInstanceError: LocalizedError, Equatable {
    case robloxApplicationNotFound([String])
    case missingInfoPlist(String)
    case invalidInfoPlist(String)
    case codeSigningFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .robloxApplicationNotFound(paths):
            "Roblox.app was not found. Checked: \(paths.joined(separator: ", "))"
        case let .missingInfoPlist(path):
            "The Roblox app copy is missing Info.plist at \(path)."
        case let .invalidInfoPlist(path):
            "The Roblox app copy has an unreadable Info.plist at \(path)."
        case let .codeSigningFailed(message):
            "The Roblox app copy could not be ad-hoc signed after preparation. \(message)"
        }
    }
}

public struct MultiInstancePreparation: Equatable, Sendable {
    public let applicationURL: URL
    public let singletonSemaphoreReleased: Bool

    public init(applicationURL: URL, singletonSemaphoreReleased: Bool) {
        self.applicationURL = applicationURL
        self.singletonSemaphoreReleased = singletonSemaphoreReleased
    }
}

public struct MultiInstanceService {
    public let rootDirectory: URL
    public let robloxSourceCandidates: [URL]
    public let codeSignPreparedCopies: Bool

    public init(
        rootDirectory: URL? = nil,
        robloxSourceCandidates: [URL]? = nil,
        codeSignPreparedCopies: Bool = true
    ) throws {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw StorageError.applicationSupportUnavailable
            }
            self.rootDirectory = appSupport
                .appendingPathComponent("MacOS-RobloxAccountManager", isDirectory: true)
                .appendingPathComponent("MultiInstanceCopies", isDirectory: true)
        }

        self.robloxSourceCandidates = robloxSourceCandidates ?? [
            URL(fileURLWithPath: "/Applications/Roblox.app"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent("Roblox.app", isDirectory: true)
        ]
        self.codeSignPreparedCopies = codeSignPreparedCopies
    }

    public func prepareRobloxApplicationCopy(accountID: UUID, launchID: UUID = UUID()) throws -> MultiInstancePreparation {
        let source = try findRobloxApplication()
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        let copyURL = rootDirectory.appendingPathComponent("Roblox-\(launchID.uuidString).app", isDirectory: true)
        if FileManager.default.fileExists(atPath: copyURL.path) {
            try FileManager.default.removeItem(at: copyURL)
        }
        try FileManager.default.copyItem(at: source, to: copyURL)
        try configureCopyInfoPlist(at: copyURL, accountID: accountID, launchID: launchID)
        if codeSignPreparedCopies {
            try adHocSignApplicationCopy(at: copyURL)
        }

        // Roblox for macOS also uses a named POSIX semaphore as a single-instance guard.
        // Removing that OS-level semaphore is best-effort and does not modify Roblox files.
        let released = releaseRobloxSingletonSemaphore()
        return MultiInstancePreparation(applicationURL: copyURL, singletonSemaphoreReleased: released)
    }

    public func cleanupManagedCopies() throws {
        guard FileManager.default.fileExists(atPath: rootDirectory.path) else { return }
        try FileManager.default.removeItem(at: rootDirectory)
    }

    public func cleanupManagedCopy(at applicationURL: URL) throws {
        let standardizedRoot = rootDirectory.standardizedFileURL.path
        let standardizedCopy = applicationURL.standardizedFileURL.path
        guard standardizedCopy.hasPrefix(standardizedRoot) else { return }
        guard FileManager.default.fileExists(atPath: applicationURL.path) else { return }
        try FileManager.default.removeItem(at: applicationURL)
    }

    public func findRobloxApplication() throws -> URL {
        for candidate in robloxSourceCandidates where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        throw MultiInstanceError.robloxApplicationNotFound(robloxSourceCandidates.map(\.path))
    }

    public func releaseRobloxSingletonSemaphore() -> Bool {
        let result = sem_unlink("/RobloxPlayerUniq")
        return result == 0 || errno == ENOENT
    }

    private func configureCopyInfoPlist(at appURL: URL, accountID: UUID, launchID: UUID) throws {
        let infoPlistURL = appURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
            throw MultiInstanceError.missingInfoPlist(infoPlistURL.path)
        }

        let data = try Data(contentsOf: infoPlistURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard var plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [.mutableContainersAndLeaves],
            format: &format
        ) as? [String: Any] else {
            throw MultiInstanceError.invalidInfoPlist(infoPlistURL.path)
        }

        let accountIdentifier = accountID.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let launchIdentifier = launchID.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        plist["CFBundleIdentifier"] = "com.github.vmmie.MacOS-RobloxAccountManager.roblox.\(accountIdentifier).\(launchIdentifier)"
        plist["CFBundleName"] = "Roblox \(String(launchIdentifier.prefix(8)))"
        plist["LSMultipleInstancesProhibited"] = false

        let output = try PropertyListSerialization.data(fromPropertyList: plist, format: format, options: 0)
        try output.write(to: infoPlistURL, options: [.atomic])
    }

    private func adHocSignApplicationCopy(at appURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--force", "--deep", "--sign", "-", appURL.path]

        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8) ?? "codesign exited with status \(process.terminationStatus)."
            throw MultiInstanceError.codeSigningFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
