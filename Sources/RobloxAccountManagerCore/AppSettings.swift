import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var allowAccountLaunch: Bool
    public var allowRbxPlayerLinks: Bool
    public var allowDeveloperAPI: Bool
    public var allowMultiInstance: Bool
    public var savePasswords: Bool
    public var launchDelaySeconds: Int
    public var developerAPIPort: Int

    public init(
        allowAccountLaunch: Bool = false,
        allowRbxPlayerLinks: Bool = false,
        allowDeveloperAPI: Bool = false,
        allowMultiInstance: Bool = false,
        savePasswords: Bool = false,
        launchDelaySeconds: Int = 8,
        developerAPIPort: Int = 7963
    ) {
        self.allowAccountLaunch = allowAccountLaunch
        self.allowRbxPlayerLinks = allowRbxPlayerLinks
        self.allowDeveloperAPI = allowDeveloperAPI
        self.allowMultiInstance = allowMultiInstance
        self.savePasswords = savePasswords
        self.launchDelaySeconds = launchDelaySeconds
        self.developerAPIPort = developerAPIPort
    }
}

