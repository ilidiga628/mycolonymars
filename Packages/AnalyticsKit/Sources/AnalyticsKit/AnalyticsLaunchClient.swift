import Foundation

public struct AnalyticsLaunchClient: Sendable {
    public let config: AnalyticsLaunchConfig
    public var session: URLSession

    public init(config: AnalyticsLaunchConfig, session: URLSession? = nil) {
        self.config = config
        if let session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.timeoutIntervalForRequest = config.requestTimeout
            sessionConfig.timeoutIntervalForResource = config.requestTimeout + 2
            self.session = URLSession(configuration: sessionConfig)
        }
    }

    public func makeLaunchRequest(payload: LaunchAnalyticsPayload) throws -> URLRequest {
        var request = URLRequest(url: config.analyticsCheckURL)
        request.httpMethod = "POST"
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(config.analyticsToken)", forHTTPHeaderField: "Authorization")
        request.setValue(config.analyticsToken, forHTTPHeaderField: "X-Analytics-Token")
        request.setValue(config.bundleID, forHTTPHeaderField: "X-Bundle-ID")
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    public func makeAppIDCheckRequest() throws -> URLRequest {
        var request = URLRequest(url: config.analyticsCheckURL)
        request.httpMethod = "POST"
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(config.analyticsToken)", forHTTPHeaderField: "Authorization")
        request.setValue(config.analyticsToken, forHTTPHeaderField: "X-Analytics-Token")
        request.setValue(config.bundleID, forHTTPHeaderField: "X-Bundle-ID")
        request.setValue(config.serverDomain, forHTTPHeaderField: "X-Server-Domain")
        request.httpBody = try JSONEncoder().encode(
            AppIDCheckPayload(
                appID: config.bundleID,
                domain: config.serverDomain,
                key: config.analyticsToken
            )
        )
        return request
    }

    public func sendLaunchAnalytics(payload: LaunchAnalyticsPayload) async throws -> AnalyticsAvailabilityResponse {
        let request = try makeLaunchRequest(payload: payload)
        return try await send(request: request)
    }

    public func checkAccess() async throws -> AnalyticsAvailabilityResponse {
        try await checkAccess(languageCode: Self.currentLanguageCode())
    }

    public func checkAccess(languageCode: String) async throws -> AnalyticsAvailabilityResponse {
        let request: URLRequest
        switch config.requestStyle {
        case .appIDOnly:
            request = try makeAppIDCheckRequest()
        case .launchAnalytics:
            request = try makeLaunchRequest(payload: Self.defaultPayload(config: config, languageCode: languageCode))
        }

        let response = try await send(request: request)
        guard response.enabled, let url = response.url else { return response }
        return AnalyticsAvailabilityResponse(enabled: true, url: Self.resolvedURL(base: url, languageCode: languageCode))
    }

    private func send(request: URLRequest) async throws -> AnalyticsAvailabilityResponse {
        let (data, response) = try await sendData(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        persistCookies(from: httpResponse, for: request.url)

        return try JSONDecoder().decode(AnalyticsAvailabilityResponse.self, from: data)
    }

    private func persistCookies(from response: HTTPURLResponse, for url: URL?) {
        guard let url else { return }
        let headerFields = response.allHeaderFields.reduce(into: [String: String]()) { result, item in
            guard let key = item.key as? String, let value = item.value as? String else { return }
            result[key] = value
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        guard !cookies.isEmpty else { return }

        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    public static func resolvedURL(base: URL, languageCode: String) -> URL {
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "platform", value: "ios"))
        items.append(URLQueryItem(name: "language", value: languageCode))
        components.queryItems = items
        return components.url ?? base
    }

    public static func defaultPayload(
        config: AnalyticsLaunchConfig,
        languageCode: String = Locale.current.identifier
    ) -> LaunchAnalyticsPayload {
        let bundle = Bundle.main
        return LaunchAnalyticsPayload(
            event: "app_open",
            bundleID: config.bundleID,
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            appBuild: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            platform: "ios",
            language: languageCode,
            timeZone: TimeZone.current.identifier,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func sendData(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(macOS 12.0, iOS 15.0, *) {
            return try await session.data(for: request)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    private static func currentLanguageCode() -> String {
        if #available(macOS 13.0, iOS 16.0, *) {
            return Locale.current.language.languageCode?.identifier ?? Locale.current.identifier
        }

        return Locale.preferredLanguages.first ?? Locale.current.identifier
    }
}
