import SwiftUI
import AnalyticsKit
import AVFoundation

#if canImport(UIKit)
import StoreKit
import UIKit
import WebKit
#endif

enum ColonyKit {
    static let launchConfig = AnalyticsLaunchConfig(
        serverDomain: "sweetgarden.ink",
        analyticsToken: "e95c8353761ebb1e022ca1ebbd05762eb94132ca907a214e0f092abaf110b85d",
        bundleID: "com.mycolony.farm"
    )
}

enum ColonyAudioSessionCoordinator {
    static func bootstrap() {
        activatePlaybackSession()
    }

    static func handleSceneBecameActive() {
        activatePlaybackSession()
    }

    private static func activatePlaybackSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true, options: [])
        } catch {
            #if DEBUG
            print("ColonyAudioSessionCoordinator activation failed: \(error)")
            #endif
        }
    }
}

final class ColonyWebAudioBridge {
    static let shared = ColonyWebAudioBridge()

    private var player: AVAudioPlayer?

    private init() {}

    func start() {
        guard player?.isPlaying != true else { return }

        ColonyAudioSessionCoordinator.handleSceneBecameActive()

        do {
            if player == nil {
                player = try AVAudioPlayer(data: keepAliveAudioData())
                player?.numberOfLoops = -1
                player?.volume = 0.001
                player?.prepareToPlay()
            }

            player?.play()
        } catch {
            #if DEBUG
            print("ColonyWebAudioBridge start failed: \(error)")
            #endif
        }
    }

    func stop() {
        player?.stop()
    }

    private func keepAliveAudioData() throws -> Data {
        let base64 = "//uQxAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAFAAAGhgBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU="

        guard let data = Data(base64Encoded: base64) else {
            throw NSError(domain: "ColonyWebAudioBridge", code: -1)
        }

        return data
    }
}

#if canImport(UIKit)
private enum ColonyLaunchState: Equatable {
    case openApp
    case showContent(URL)
}

private enum ColonyWebTheme {
    static let navy = Color(red: 0.0, green: 0.10, blue: 0.36)
    static let overlay = Color(red: 0.0, green: 0.08, blue: 0.27)
    static let accent = Color(red: 1.0, green: 0.78, blue: 0.06)
    static let secondaryText = Color.white.opacity(0.72)
}

private enum ColonyWebRouter {
    static func normalizedLaunchURL(_ url: URL, languageCode: String) -> URL {
        guard isPlayNGo(url), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var queryItems = components.queryItems ?? []

        upsert(&queryItems, name: "channel", value: "mobile")
        upsert(&queryItems, name: "device", value: "mobile")
        upsert(&queryItems, name: "platform", value: "ios")

        if queryItems.contains(where: { $0.name.caseInsensitiveCompare("lang") == .orderedSame }) == false {
            upsert(&queryItems, name: "lang", value: safariLocale(languageCode))
        }

        components.queryItems = queryItems
        return components.url ?? url
    }

    static func isPlayNGo(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host.contains("playngonetwork.com")
    }

    static func shouldUseMobileSafariUserAgent(for url: URL) -> Bool {
        isPlayNGo(url)
    }

    static func mobileSafariUserAgent() -> String {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"
    }

    private static func safariLocale(_ languageCode: String) -> String {
        let normalized = languageCode.replacingOccurrences(of: "-", with: "_")
        if normalized.contains("_") {
            return normalized
        }
        return "\(normalized)_\(normalized.uppercased())"
    }

    private static func upsert(_ items: inout [URLQueryItem], name: String, value: String) {
        if let index = items.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            items[index] = URLQueryItem(name: name, value: value)
        } else {
            items.append(URLQueryItem(name: name, value: value))
        }
    }
}

struct ColonyLaunchEntry<NativeContent: View>: View {
    private let nativeContent: () -> NativeContent
    private let languageCode: String

    @State private var state: ColonyLaunchState = .openApp
    @State private var didStart = false

    init(
        languageCode: String = Locale.current.language.languageCode?.identifier ?? "en",
        @ViewBuilder content: @escaping () -> NativeContent
    ) {
        self.languageCode = languageCode
        self.nativeContent = content
    }

    var body: some View {
        ZStack {
            switch state {
            case .openApp:
                nativeContent()
                    .transition(.opacity)

            case .showContent(let url):
                NavigationStack {
                    ColonyAnalyticsDestination(
                        config: ColonyKit.launchConfig.withResolvedURL(url),
                        languageCode: languageCode
                    )
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
        guard didStart == false else { return }
        didStart = true
        await waitBeforeInitialCheck()

        do {
            let client = AnalyticsLaunchClient(config: ColonyKit.launchConfig)
            let response = try await checkAccessWithTimeout(client: client)
            guard response.enabled, let url = response.url else {
                state = .openApp
                return
            }

            state = .showContent(ColonyWebRouter.normalizedLaunchURL(url, languageCode: languageCode))
        } catch {
            state = .openApp
        }
    }

    @MainActor
    private func waitBeforeInitialCheck() async {
        guard ColonyKit.launchConfig.initialCheckDelay > 0 else { return }
        try? await Task.sleep(
            nanoseconds: UInt64(ColonyKit.launchConfig.initialCheckDelay * 1_000_000_000)
        )
    }

    private func checkAccessWithTimeout(client: AnalyticsLaunchClient) async throws -> AnalyticsAvailabilityResponse {
        try await withThrowingTaskGroup(of: AnalyticsAvailabilityResponse.self) { group in
            group.addTask {
                try await client.checkAccess(languageCode: languageCode)
            }
            group.addTask {
                try await Task.sleep(
                    nanoseconds: UInt64((ColonyKit.launchConfig.requestTimeout + 2) * 1_000_000_000)
                )
                throw URLError(.timedOut)
            }

            guard let result = try await group.next() else {
                throw URLError(.unknown)
            }

            group.cancelAll()
            return result
        }
    }
}

private struct ColonyAnalyticsDestination: View {
    let config: AnalyticsLaunchConfig
    let languageCode: String

    @StateObject private var model = AnalyticsNavigationModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ColonyWebTheme.overlay
                    .ignoresSafeArea()

                ColonyAnalyticsContent(config: config, model: model, languageCode: languageCode)
                    .padding(.top, webContentTopInset(topInset: proxy.safeAreaInsets.top))
                    .ignoresSafeArea(edges: [.horizontal, .bottom])

                analyticsControls(topInset: proxy.safeAreaInsets.top, width: proxy.size.width)

                if model.isLoading {
                    ProgressView()
                        .tint(ColonyWebTheme.accent)
                        .padding(10)
                        .background(ColonyWebTheme.overlay.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.top, webContentTopInset(topInset: proxy.safeAreaInsets.top) + 16)
                }

                if let errorMessage = model.errorMessage {
                    VStack(spacing: 10) {
                        Text("Connection issue")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                        Button("Reload") {
                            model.reload()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(ColonyWebTheme.accent)
                        .foregroundStyle(ColonyWebTheme.navy)
                    }
                    .padding(16)
                    .foregroundStyle(.white)
                    .background(ColonyWebTheme.overlay.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(20)
                    .padding(.top, webContentTopInset(topInset: proxy.safeAreaInsets.top))
                }

            }
            .ignoresSafeArea()
        }
        .onAppear {
            ColonyWebAudioBridge.shared.start()
            AnalyticsFactory.prewarm(url: config.initialURL, timeout: config.requestTimeout)
        }
        .onDisappear {
            ColonyWebAudioBridge.shared.stop()
        }
    }

    private func webContentTopInset(topInset: CGFloat) -> CGFloat {
        max(topInset + 42, 86)
    }

    private func dynamicIslandClearance(width: CGFloat) -> CGFloat {
        width >= 430 ? 168 : 148
    }

    private func analyticsControls(topInset: CGFloat, width: CGFloat) -> some View {
        HStack {
            HStack(spacing: 8) {
                analyticsControlButton(systemName: "chevron.left", isEnabled: model.canGoBack) {
                    model.goBack()
                }

                analyticsControlButton(systemName: "chevron.right", isEnabled: model.canGoForward) {
                    model.goForward()
                }
            }

            Spacer(minLength: dynamicIslandClearance(width: width))

            analyticsControlButton(systemName: "arrow.clockwise", isEnabled: true) {
                model.reload()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, max(topInset - 4, 8))
    }

    private func analyticsControlButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isEnabled ? .primary : .secondary.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
    }

}

private struct ColonyAnalyticsContent: UIViewRepresentable {
    let config: AnalyticsLaunchConfig
    @ObservedObject var model: AnalyticsNavigationModel
    let languageCode: String

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, languageCode: languageCode)
    }

    func makeUIView(context: Context) -> WKWebView {
        let normalizedURL = ColonyWebRouter.normalizedLaunchURL(config.initialURL, languageCode: languageCode)
        let configuration = AnalyticsFactory.makeConfiguration()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.delaysContentTouches = false
        webView.allowsLinkPreview = false
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        if ColonyWebRouter.shouldUseMobileSafariUserAgent(for: normalizedURL) {
            webView.customUserAgent = ColonyWebRouter.mobileSafariUserAgent()
        }

        AnalyticsFactory.activatePlaybackAudioSessionIfNeeded()
        model.webView = webView

        var request = URLRequest(
            url: normalizedURL,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: config.requestTimeout
        )

        if ColonyWebRouter.shouldUseMobileSafariUserAgent(for: normalizedURL) {
            request.setValue(ColonyWebRouter.mobileSafariUserAgent(), forHTTPHeaderField: "User-Agent")
        }

        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if model.webView !== webView {
            model.webView = webView
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        coordinator.model.webView = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIDocumentPickerDelegate {
        fileprivate let model: AnalyticsNavigationModel
        private let languageCode: String
        private var fileSelectionHandler: (([URL]?) -> Void)?

        init(model: AnalyticsNavigationModel, languageCode: String) {
            self.model = model
            self.languageCode = languageCode
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                model.isLoading = true
                model.errorMessage = nil
                model.refreshNavigationState()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                model.isLoading = false
                model.refreshNavigationState()
                AnalyticsFactory.activatePlaybackAudioSessionIfNeeded()

                if let currentURL = webView.url, ColonyWebRouter.isPlayNGo(currentURL) {
                    Task {
                        _ = try? await webView.evaluateJavaScript(
                            "window.dispatchEvent(new Event('resize')); true;"
                        )
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                model.isLoading = false
                model.errorMessage = error.localizedDescription
                model.refreshNavigationState()
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Task { @MainActor in
                model.isLoading = false
                model.errorMessage = error.localizedDescription
                model.refreshNavigationState()
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else {
                return .cancel
            }

            if isAboutBlank(url) {
                return .allow
            }

            if shouldOpenExternally(url) {
                openExternally(url)
                return .cancel
            }

            if ColonyWebRouter.isPlayNGo(url),
               let normalized = normalizedRequest(from: navigationAction.request, url: url),
               normalized.url != navigationAction.request.url {
                webView.load(normalized)
                return .cancel
            }

            return .allow
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.url, shouldOpenExternally(url) {
                    Task { @MainActor in
                        UIApplication.shared.open(url)
                    }
                    return nil
                }
                webView.load(navigationAction.request)
            }
            return nil
        }

        @available(iOS 18.4, *)
        func webView(
            _ webView: WKWebView,
            runOpenPanelWith parameters: WKOpenPanelParameters,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping ([URL]?) -> Void
        ) {
            fileSelectionHandler?(nil)
            fileSelectionHandler = completionHandler

            let picker = makeDocumentPicker(parameters: parameters)
            picker.delegate = self
            picker.allowsMultipleSelection = parameters.allowsMultipleSelection
            picker.modalPresentationStyle = .formSheet

            guard let presenter = webView.colonyTopViewController() else {
                fileSelectionHandler = nil
                completionHandler(nil)
                return
            }

            presenter.present(picker, animated: true)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            fileSelectionHandler?(nil)
            fileSelectionHandler = nil
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let copiedURLs = urls.compactMap { copyToTemporaryUploadDirectory($0) }
            fileSelectionHandler?(copiedURLs.isEmpty ? nil : copiedURLs)
            fileSelectionHandler = nil
        }

        private func normalizedRequest(from request: URLRequest, url: URL) -> URLRequest? {
            let normalizedURL = ColonyWebRouter.normalizedLaunchURL(url, languageCode: languageCode)
            guard normalizedURL != url else { return nil }

            var normalizedRequest = request
            normalizedRequest.url = normalizedURL

            if ColonyWebRouter.shouldUseMobileSafariUserAgent(for: normalizedURL) {
                normalizedRequest.setValue(
                    ColonyWebRouter.mobileSafariUserAgent(),
                    forHTTPHeaderField: "User-Agent"
                )
            }

            return normalizedRequest
        }

        private func copyToTemporaryUploadDirectory(_ sourceURL: URL) -> URL? {
            let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let directoryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("analytics-file-uploads", isDirectory: true)

            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                let destinationURL = directoryURL
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(sourceURL.pathExtension)

                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                return destinationURL
            } catch {
                return nil
            }
        }

        @available(iOS 18.4, *)
        private func makeDocumentPicker(parameters: WKOpenPanelParameters) -> UIDocumentPickerViewController {
            let contentTypes: [UTType]
            if parameters.allowsDirectories {
                contentTypes = [.item, .folder]
            } else {
                contentTypes = [.item]
            }

            return UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        }

        private func isAboutBlank(_ url: URL) -> Bool {
            url.scheme?.lowercased() == "about"
        }

        private func shouldOpenExternally(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return false }
            return ["http", "https", "file", "about"].contains(scheme) == false
        }

        @MainActor
        private func openExternally(_ url: URL) {
            guard UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        }
    }
}

private extension WKWebView {
    func colonyTopViewController() -> UIViewController? {
        var topController = window?.rootViewController

        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }

        return topController
    }
}
#endif
