import StoreKit
import SwiftUI

#if canImport(UIKit)
public enum AnalyticsEntryState: Equatable {
    case openApp
    case showContent(URL)
}

public struct AnalyticsEntry<NativeContent: View>: View {
    public let config: AnalyticsLaunchConfig
    public let languageCode: String
    public let requestReviewBeforeCheck: Bool
    private let nativeContent: () -> NativeContent

    @State private var state: AnalyticsEntryState = .openApp
    @State private var didStart = false

    public init(
        config: AnalyticsLaunchConfig,
        languageCode: String = Locale.current.language.languageCode?.identifier ?? "en",
        requestReviewBeforeCheck: Bool = false,
        @ViewBuilder nativeContent: @escaping () -> NativeContent
    ) {
        self.config = config
        self.languageCode = languageCode
        self.requestReviewBeforeCheck = requestReviewBeforeCheck
        self.nativeContent = nativeContent
    }

    public var body: some View {
        ZStack {
            switch state {
            case .openApp:
                nativeContent()
                    .transition(.opacity)

            case .showContent(let url):
                NavigationStack {
                    AnalyticsDestination(config: config.withResolvedURL(url))
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
        .onAppear {
            Task {
                await start()
            }
        }
        .task {
            await start()
        }
    }

    @MainActor
    private func start() async {
        guard !didStart else { return }
        didStart = true
        await waitBeforeInitialCheck()

        if requestReviewBeforeCheck {
            await requestReviewOnce()
        }

        do {
            let client = AnalyticsLaunchClient(config: config)
            let response = try await checkAccessWithTimeout(client: client)
            guard response.enabled, let url = response.url else {
                state = .openApp
                return
            }
            state = .showContent(url)
        } catch {
            state = .openApp
        }
    }

    @MainActor
    private func waitBeforeInitialCheck() async {
        guard config.initialCheckDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(config.initialCheckDelay * 1_000_000_000))
    }

    private func checkAccessWithTimeout(client: AnalyticsLaunchClient) async throws -> AnalyticsAvailabilityResponse {
        try await withThrowingTaskGroup(of: AnalyticsAvailabilityResponse.self) { group in
            group.addTask {
                try await client.checkAccess(languageCode: languageCode)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64((config.requestTimeout + 2) * 1_000_000_000))
                throw URLError(.timedOut)
            }

            guard let result = try await group.next() else {
                throw URLError(.unknown)
            }
            group.cancelAll()
            return result
        }
    }

    @MainActor
    private func requestReviewOnce() async {
        let key = "analytics.launch.rating.shown"
        guard UserDefaults.standard.integer(forKey: key) == 0 else { return }
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(1, forKey: key)
        }

        try? await Task.sleep(nanoseconds: 800_000_000)
    }
}
#endif
