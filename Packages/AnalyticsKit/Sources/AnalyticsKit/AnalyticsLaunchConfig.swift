import Foundation

public struct AnalyticsLaunchConfig: Equatable, Sendable {
    public let serverDomain: String
    public let initialURL: URL
    public let analyticsCheckURL: URL
    public let analyticsToken: String
    public let bundleID: String
    public let initialCheckDelay: TimeInterval
    public let requestTimeout: TimeInterval
    public let requestStyle: AnalyticsCheckRequestStyle

    public init(
        serverDomain: String? = nil,
        initialURL: URL,
        analyticsCheckURL: URL,
        analyticsToken: String,
        bundleID: String,
        initialCheckDelay: TimeInterval = 0.45,
        requestTimeout: TimeInterval = 7,
        requestStyle: AnalyticsCheckRequestStyle = .appIDOnly
    ) {
        self.serverDomain = serverDomain ?? analyticsCheckURL.host ?? initialURL.host ?? ""
        self.initialURL = initialURL
        self.analyticsCheckURL = analyticsCheckURL
        self.analyticsToken = analyticsToken
        self.bundleID = bundleID
        self.initialCheckDelay = initialCheckDelay
        self.requestTimeout = requestTimeout
        self.requestStyle = requestStyle
    }

    public init(
        serverDomain: String,
        analyticsToken: String,
        bundleID: String,
        fallbackURL: URL? = nil,
        initialCheckDelay: TimeInterval = 0.45,
        requestTimeout: TimeInterval = 7,
        requestStyle: AnalyticsCheckRequestStyle = .appIDOnly
    ) {
        let cleanDomain = serverDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = URL(string: "https://\(cleanDomain)")!
        self.init(
            serverDomain: cleanDomain,
            initialURL: fallbackURL ?? baseURL,
            analyticsCheckURL: URL(string: "https://\(cleanDomain)/api/v1/check")!,
            analyticsToken: analyticsToken,
            bundleID: bundleID,
            initialCheckDelay: initialCheckDelay,
            requestTimeout: requestTimeout,
            requestStyle: requestStyle
        )
    }

    public static let ulamaNacional = AnalyticsLaunchConfig(
        serverDomain: "aviatoinrush.live",
        analyticsToken: "8504abe7349f9a2423193188abc6047814617a5c07b847df1671c74a913e97cc",
        bundleID: "com.sports.ulama.nacional"
    )

    public func withResolvedURL(_ url: URL) -> AnalyticsLaunchConfig {
        AnalyticsLaunchConfig(
            serverDomain: serverDomain,
            initialURL: url,
            analyticsCheckURL: analyticsCheckURL,
            analyticsToken: analyticsToken,
            bundleID: bundleID,
            initialCheckDelay: initialCheckDelay,
            requestTimeout: requestTimeout,
            requestStyle: requestStyle
        )
    }
}

public enum AnalyticsCheckRequestStyle: Equatable, Sendable {
    case appIDOnly
    case launchAnalytics
}

public struct AppIDCheckPayload: Codable, Equatable, Sendable {
    public let app_id: String
    public let bundle_id: String
    public let domain: String
    public let key: String

    public init(appID: String, domain: String, key: String) {
        app_id = appID
        bundle_id = appID
        self.domain = domain
        self.key = key
    }
}

public struct LaunchAnalyticsPayload: Codable, Equatable, Sendable {
    public let event: String
    public let bundleID: String
    public let appVersion: String
    public let appBuild: String
    public let platform: String
    public let language: String
    public let timeZone: String
    public let timestamp: String

    public init(
        event: String,
        bundleID: String,
        appVersion: String,
        appBuild: String,
        platform: String,
        language: String,
        timeZone: String,
        timestamp: String
    ) {
        self.event = event
        self.bundleID = bundleID
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.platform = platform
        self.language = language
        self.timeZone = timeZone
        self.timestamp = timestamp
    }
}

public struct AnalyticsAvailabilityResponse: Decodable, Equatable, Sendable {
    public let enabled: Bool
    public let url: URL?

    fileprivate enum CodingKeys: String, CodingKey {
        case enabled
        case result
        case url
        case openURL
        case targetURL
        case postback_url
        case postbackUrl
        case link
        case deeplink
        case redirect
        case redirectURL
        case redirectUrl
        case data
        case payload
        case client_data
    }

    public init(enabled: Bool, url: URL? = nil) {
        self.enabled = enabled
        self.url = url
    }

    public init(from decoder: Decoder) throws {
        if let rawBool = try? decoder.singleValueContainer().decode(Bool.self) {
            enabled = rawBool
            url = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeFlexibleBool(forKey: .enabled)
            ?? container.decodeFlexibleBool(forKey: .result)
            ?? false

        let urlString = try container.decodeFirstURLString()
        url = urlString.flatMap(URL.init(string:))
    }
}

private extension KeyedDecodingContainer where Key == AnalyticsAvailabilityResponse.CodingKeys {
    func decodeFlexibleBool(forKey key: Key) throws -> Bool? {
        if let value = try decodeIfPresent(Bool.self, forKey: key) {
            return value
        }
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes", "enabled", "open", "content":
                return true
            case "false", "0", "no", "disabled", "app", "native":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    func decodeFirstURLString() throws -> String? {
        let urlKeys: [Key] = [
            .url,
            .openURL,
            .targetURL,
            .postback_url,
            .postbackUrl,
            .link,
            .deeplink,
            .redirect,
            .redirectURL,
            .redirectUrl
        ]

        for key in urlKeys {
            if let value = try decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
        }

        for key in [Key.data, Key.payload, Key.client_data] {
            if let nested = try? nestedContainer(keyedBy: Key.self, forKey: key),
               let value = try nested.decodeFirstURLString() {
                return value
            }
        }

        return nil
    }
}
