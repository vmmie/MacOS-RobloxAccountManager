import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var allowAccountLaunch: Bool
    public var allowRbxPlayerLinks: Bool
    public var allowDeveloperAPI: Bool
    public var allowMultiInstance: Bool
    public var savePasswords: Bool
    public var savedPlaceID: String
    public var savedJobID: String
    public var launchDelaySeconds: Int
    public var developerAPIPort: Int

    private enum CodingKeys: String, CodingKey {
        case allowAccountLaunch
        case allowRbxPlayerLinks
        case allowDeveloperAPI
        case allowMultiInstance
        case savePasswords
        case savedPlaceID
        case savedJobID
        case launchDelaySeconds
        case developerAPIPort
    }

    public init(
        allowAccountLaunch: Bool = false,
        allowRbxPlayerLinks: Bool = false,
        allowDeveloperAPI: Bool = false,
        allowMultiInstance: Bool = false,
        savePasswords: Bool = false,
        savedPlaceID: String = "",
        savedJobID: String = "",
        launchDelaySeconds: Int = 8,
        developerAPIPort: Int = 7963
    ) {
        self.allowAccountLaunch = allowAccountLaunch
        self.allowRbxPlayerLinks = allowRbxPlayerLinks
        self.allowDeveloperAPI = allowDeveloperAPI
        self.allowMultiInstance = allowMultiInstance
        self.savePasswords = savePasswords
        self.savedPlaceID = savedPlaceID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.savedJobID = savedJobID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.launchDelaySeconds = launchDelaySeconds
        self.developerAPIPort = developerAPIPort
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            allowAccountLaunch: try container.decodeIfPresent(Bool.self, forKey: .allowAccountLaunch) ?? false,
            allowRbxPlayerLinks: try container.decodeIfPresent(Bool.self, forKey: .allowRbxPlayerLinks) ?? false,
            allowDeveloperAPI: try container.decodeIfPresent(Bool.self, forKey: .allowDeveloperAPI) ?? false,
            allowMultiInstance: try container.decodeIfPresent(Bool.self, forKey: .allowMultiInstance) ?? false,
            savePasswords: try container.decodeIfPresent(Bool.self, forKey: .savePasswords) ?? false,
            savedPlaceID: try container.decodeIfPresent(String.self, forKey: .savedPlaceID) ?? "",
            savedJobID: try container.decodeIfPresent(String.self, forKey: .savedJobID) ?? "",
            launchDelaySeconds: try container.decodeIfPresent(Int.self, forKey: .launchDelaySeconds) ?? 8,
            developerAPIPort: try container.decodeIfPresent(Int.self, forKey: .developerAPIPort) ?? 7963
        )
    }
}
