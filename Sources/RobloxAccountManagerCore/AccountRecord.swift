import Foundation

public struct AccountRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var username: String
    public var alias: String
    public var description: String
    public var group: String
    public var userID: Int64?
    public var savedPlaceID: String
    public var savedJobID: String
    public var lastUsedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        username: String,
        alias: String = "",
        description: String = "",
        group: String = "Default",
        userID: Int64? = nil,
        savedPlaceID: String = "",
        savedJobID: String = "",
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.alias = alias
        self.description = description
        self.group = group.isEmpty ? "Default" : group
        self.userID = userID
        self.savedPlaceID = savedPlaceID
        self.savedJobID = savedJobID
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        alias.isEmpty ? username : alias
    }
}

public struct AccountSecret: Codable, Equatable, Sendable {
    public var robloxSecurityCookie: String
    public var password: String?

    public init(robloxSecurityCookie: String, password: String? = nil) {
        self.robloxSecurityCookie = robloxSecurityCookie.trimmingCharacters(in: .whitespacesAndNewlines)
        self.password = password?.isEmpty == true ? nil : password
    }
}

