import Foundation
@testable import RobloxAccountManagerCore
import XCTest

final class ImportExportTests: XCTestCase {
    func testMetadataExportDoesNotIncludeSecrets() throws {
        let account = AccountRecord(username: "exampleUser", group: "Primary", savedPlaceID: "1818")
        let envelope = ImportExportService().makeExport(accounts: [account])

        XCTAssertFalse(envelope.includesSensitiveSecrets)
        XCTAssertEqual(envelope.accounts.count, 1)
        XCTAssertNil(envelope.accounts[0].robloxSecurityCookie)
        XCTAssertNil(envelope.accounts[0].password)

        let data = try ImportExportService().encodeExport(envelope)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(json.contains(".ROBLOSECURITY"))
    }

    func testImportRejectsPlaintextSecretsUnlessExplicitlyAllowed() throws {
        let account = AccountRecord(username: "exampleUser")
        let envelope = AccountExportEnvelope(
            includesSensitiveSecrets: true,
            accounts: [ExportedAccount(record: account, robloxSecurityCookie: "secret-cookie")]
        )
        let data = try ImportExportService().encodeExport(envelope)

        XCTAssertThrowsError(try ImportExportService().decodeImport(data)) { error in
            XCTAssertEqual(error as? ImportExportError, .plaintextSecretsNotAllowed)
        }

        let decoded = try ImportExportService().decodeImport(data, allowPlaintextSecrets: true)
        XCTAssertEqual(decoded.accounts[0].robloxSecurityCookie, "secret-cookie")
    }

    func testFileStorageRoundTripsAccountsAndSettings() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let storage = try FileStorage(rootDirectory: root)
        let accounts = [AccountRecord(username: "one"), AccountRecord(username: "two", group: "Alts")]
        let settings = AppSettings(allowAccountLaunch: true, allowRbxPlayerLinks: true, savePasswords: true)

        try storage.saveAccounts(accounts)
        try storage.saveSettings(settings)

        let loadedAccounts = try storage.loadAccounts()
        XCTAssertEqual(loadedAccounts.map(\.id), accounts.map(\.id))
        XCTAssertEqual(loadedAccounts.map(\.username), ["one", "two"])
        XCTAssertEqual(loadedAccounts.map(\.group), ["Default", "Alts"])
        XCTAssertEqual(try storage.loadSettings(), settings)

        let backupURL = try storage.backupAccounts()
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
    }

    func testLaunchURLMatchesRobloxSchemeShape() throws {
        let service = RobloxLaunchService()
        let request = RobloxLaunchRequest(placeID: "1818", jobID: "job")
        let url = try service.buildLaunchURL(ticket: "ticket", request: request, browserTrackerID: "123456")
        let raw = url.absoluteString

        XCTAssertTrue(raw.hasPrefix("roblox-player:1+launchmode:play"))
        XCTAssertTrue(raw.contains("gameinfo:ticket"))
        XCTAssertTrue(raw.contains("browsertrackerid:123456"))
        XCTAssertTrue(raw.contains("RequestGameJob"))
    }
}
