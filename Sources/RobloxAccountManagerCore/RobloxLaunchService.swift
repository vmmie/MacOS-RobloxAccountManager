import Foundation

public enum RobloxLaunchError: LocalizedError, Equatable {
    case launchDisabled
    case emptyCookie
    case invalidPlaceID
    case csrfTokenMissing(String)
    case authenticationTicketMissing(String)
    case cannotBuildURL

    public var errorDescription: String? {
        switch self {
        case .launchDisabled:
            "Account launching is disabled in Settings. Enable it only if you understand the rbx-player risk."
        case .emptyCookie:
            "This account does not have a stored .ROBLOSECURITY cookie."
        case .invalidPlaceID:
            "Enter a numeric Roblox Place ID before launching."
        case let .csrfTokenMissing(response):
            "Roblox did not return an X-CSRF token. The account session may have expired. \(response)"
        case let .authenticationTicketMissing(response):
            "Roblox did not return an authentication ticket. The account may be signed out. \(response)"
        case .cannotBuildURL:
            "The Roblox launch URL could not be created."
        }
    }
}

public struct RobloxLaunchRequest: Equatable, Sendable {
    public var placeID: String
    public var jobID: String
    public var followUser: Bool
    public var privateServer: Bool

    public init(placeID: String, jobID: String = "", followUser: Bool = false, privateServer: Bool = false) {
        self.placeID = placeID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.jobID = jobID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.followUser = followUser
        self.privateServer = privateServer
    }
}

public struct RobloxLaunchService: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func buildLaunchURL(ticket: String, request: RobloxLaunchRequest, browserTrackerID: String = Self.makeBrowserTrackerID()) throws -> URL {
        guard Int64(request.placeID) != nil else { throw RobloxLaunchError.invalidPlaceID }
        let launchTime = Int(Date().timeIntervalSince1970 * 1000)
        let placeLauncherURL: String

        if request.followUser {
            placeLauncherURL = "https://assetgame.roblox.com/game/PlaceLauncher.ashx?request=RequestFollowUser&userId=\(request.placeID)"
        } else if request.privateServer {
            placeLauncherURL = "https://assetgame.roblox.com/game/PlaceLauncher.ashx?request=RequestPrivateGame&placeId=\(request.placeID)&accessCode=\(request.jobID)"
        } else {
            let requestKind = request.jobID.isEmpty ? "RequestGame" : "RequestGameJob"
            let job = request.jobID.isEmpty ? "" : "&gameId=\(request.jobID)"
            placeLauncherURL = "https://assetgame.roblox.com/game/PlaceLauncher.ashx?request=\(requestKind)&browserTrackerId=\(browserTrackerID)&placeId=\(request.placeID)\(job)&isPlayTogetherGame=false"
        }

        guard let encodedLauncher = placeLauncherURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw RobloxLaunchError.cannotBuildURL
        }

        let raw = "roblox-player:1+launchmode:play+gameinfo:\(ticket)+launchtime:\(launchTime)+placelauncherurl:\(encodedLauncher)+browsertrackerid:\(browserTrackerID)+robloxLocale:en_us+gameLocale:en_us+channel:+LaunchExp:InApp"
        guard let url = URL(string: raw) else { throw RobloxLaunchError.cannotBuildURL }
        return url
    }

    public func fetchAuthenticationTicket(cookie: String) async throws -> String {
        let trimmedCookie = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCookie.isEmpty else { throw RobloxLaunchError.emptyCookie }
        let csrf = try await fetchCSRFToken(cookie: trimmedCookie)

        var request = URLRequest(url: URL(string: "https://auth.roblox.com/v1/authentication-ticket/")!)
        request.httpMethod = "POST"
        request.addValue(".ROBLOSECURITY=\(trimmedCookie)", forHTTPHeaderField: "Cookie")
        request.addValue(csrf, forHTTPHeaderField: "X-CSRF-TOKEN")
        request.addValue("https://www.roblox.com/games/4924922222/Brookhaven-RP", forHTTPHeaderField: "Referer")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              let ticket = http.value(forHTTPHeaderField: "rbx-authentication-ticket"),
              !ticket.isEmpty else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RobloxLaunchError.authenticationTicketMissing(body)
        }
        return ticket
    }

    public static func makeBrowserTrackerID() -> String {
        "\(Int.random(in: 100_000...175_000))\(Int.random(in: 100_000...900_000))"
    }

    private func fetchCSRFToken(cookie: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://auth.roblox.com/v1/authentication-ticket/")!)
        request.httpMethod = "POST"
        request.addValue(".ROBLOSECURITY=\(cookie)", forHTTPHeaderField: "Cookie")
        request.addValue("https://www.roblox.com/games/4924922222/Brookhaven-RP", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              let token = http.value(forHTTPHeaderField: "x-csrf-token"),
              !token.isEmpty else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw RobloxLaunchError.csrfTokenMissing(body)
        }
        return token
    }
}
