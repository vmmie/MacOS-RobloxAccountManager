import Foundation

public struct AccountExportEnvelope: Codable, Equatable, Sendable {
    public var format: String
    public var version: Int
    public var exportedAt: Date
    public var includesSensitiveSecrets: Bool
    public var accounts: [ExportedAccount]

    public init(
        format: String = "MacOS-RobloxAccountManager.accounts",
        version: Int = 1,
        exportedAt: Date = Date(),
        includesSensitiveSecrets: Bool = false,
        accounts: [ExportedAccount]
    ) {
        self.format = format
        self.version = version
        self.exportedAt = exportedAt
        self.includesSensitiveSecrets = includesSensitiveSecrets
        self.accounts = accounts
    }
}

public struct ExportedAccount: Codable, Equatable, Sendable {
    public var record: AccountRecord
    public var robloxSecurityCookie: String?
    public var password: String?

    public init(record: AccountRecord, robloxSecurityCookie: String? = nil, password: String? = nil) {
        self.record = record
        self.robloxSecurityCookie = robloxSecurityCookie
        self.password = password
    }
}

public enum ImportExportError: LocalizedError {
    case unsupportedFormat
    case plaintextSecretsNotAllowed

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "The selected file is not a supported MacOS-RobloxAccountManager export."
        case .plaintextSecretsNotAllowed:
            "This export contains plaintext secrets. Import it only from a file you created and trust."
        }
    }
}

public struct ImportExportService: Sendable {
    public init() {}

    public func makeExport(accounts: [AccountRecord]) -> AccountExportEnvelope {
        AccountExportEnvelope(accounts: accounts.map { ExportedAccount(record: $0) })
    }

    public func encodeExport(_ envelope: AccountExportEnvelope) throws -> Data {
        try JSONCoding.encoder.encode(envelope)
    }

    public func decodeImport(_ data: Data, allowPlaintextSecrets: Bool = false) throws -> AccountExportEnvelope {
        let envelope = try JSONCoding.decoder.decode(AccountExportEnvelope.self, from: data)
        guard envelope.format == "MacOS-RobloxAccountManager.accounts", envelope.version == 1 else {
            throw ImportExportError.unsupportedFormat
        }
        if envelope.includesSensitiveSecrets && !allowPlaintextSecrets {
            throw ImportExportError.plaintextSecretsNotAllowed
        }
        return envelope
    }
}

