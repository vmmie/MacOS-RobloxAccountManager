import Foundation
@testable import RobloxAccountManagerCore
import XCTest

final class ImportExportTests: XCTestCase {
    func testMetadataExportDoesNotIncludeSecrets() throws {
        let account = AccountRecord(username: "exampleUser", group: "Primary")
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
        let settings = AppSettings(
            allowAccountLaunch: true,
            allowRbxPlayerLinks: true,
            savePasswords: true,
            savedPlaceID: "1818",
            savedJobID: "job"
        )

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

    func testSettingsDecodeOlderFilesWithoutGlobalLaunchTarget() throws {
        let json = """
        {
          "allowAccountLaunch" : true,
          "allowDeveloperAPI" : false,
          "allowMultiInstance" : true,
          "allowRbxPlayerLinks" : true,
          "developerAPIPort" : 7963,
          "launchDelaySeconds" : 8,
          "savePasswords" : false
        }
        """

        let settings = try JSONCoding.decoder.decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertTrue(settings.allowAccountLaunch)
        XCTAssertTrue(settings.allowRbxPlayerLinks)
        XCTAssertTrue(settings.allowMultiInstance)
        XCTAssertEqual(settings.savedPlaceID, "")
        XCTAssertEqual(settings.savedJobID, "")
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

    func testMultiInstanceServicePreparesManagedRobloxCopy() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("SourceRoblox.app", isDirectory: true)
        let contents = source.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let infoPlistURL = contents.appendingPathComponent("Info.plist")
        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.roblox.RobloxPlayer",
            "CFBundleName": "Roblox",
            "LSMultipleInstancesProhibited": true
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: infoPlistURL)

        let service = try MultiInstanceService(
            rootDirectory: root.appendingPathComponent("Copies", isDirectory: true),
            robloxSourceCandidates: [source],
            codeSignPreparedCopies: false
        )
        let accountID = UUID()
        let preparation = try service.prepareRobloxApplicationCopy(accountID: accountID)

        XCTAssertTrue(FileManager.default.fileExists(atPath: preparation.applicationURL.path))
        let copiedInfoPlistURL = preparation.applicationURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist")
        let copiedData = try Data(contentsOf: copiedInfoPlistURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        let copiedPlist = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: copiedData,
            options: [],
            format: &format
        ) as? [String: Any])
        XCTAssertEqual(copiedPlist["LSMultipleInstancesProhibited"] as? Bool, false)
        XCTAssertNotEqual(copiedPlist["CFBundleIdentifier"] as? String, "com.roblox.RobloxPlayer")
    }
}
