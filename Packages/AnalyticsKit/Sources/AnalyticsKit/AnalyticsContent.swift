import SwiftUI
#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
import WebKit

public struct AnalyticsContent: UIViewRepresentable {
    public let config: AnalyticsLaunchConfig
    @ObservedObject public var model: AnalyticsNavigationModel

    public init(config: AnalyticsLaunchConfig, model: AnalyticsNavigationModel) {
        self.config = config
        self.model = model
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: AnalyticsFactory.makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        #if os(iOS)
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        AnalyticsFactory.activatePlaybackAudioSessionIfNeeded()
        #endif
        model.webView = webView

        webView.load(URLRequest(url: config.initialURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: config.requestTimeout))
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        if model.webView !== webView {
            model.webView = webView
        }
    }

    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        coordinator.model.webView = nil
    }

    public final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIDocumentPickerDelegate {
        fileprivate let model: AnalyticsNavigationModel
        private var fileSelectionHandler: (([URL]?) -> Void)?

        init(model: AnalyticsNavigationModel) {
            self.model = model
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                model.isLoading = true
                model.errorMessage = nil
                model.refreshNavigationState()
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                model.isLoading = false
                model.refreshNavigationState()
                #if os(iOS)
                AnalyticsFactory.activatePlaybackAudioSessionIfNeeded()
                #endif
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                model.isLoading = false
                model.errorMessage = error.localizedDescription
                model.refreshNavigationState()
            }
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                model.isLoading = false
                model.errorMessage = error.localizedDescription
                model.refreshNavigationState()
            }
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else {
                return .cancel
            }

            if isAboutBlank(url) {
                return .allow
            }

            if shouldOpenExternally(url) {
                await openExternally(url)
                return .cancel
            }

            return .allow
        }

        public func webView(
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
        public func webView(
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

            guard let presenter = webView.analyticsTopViewController() else {
                fileSelectionHandler = nil
                completionHandler(nil)
                return
            }

            presenter.present(picker, animated: true)
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            fileSelectionHandler?(nil)
            fileSelectionHandler = nil
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let copiedURLs = urls.compactMap { copyToTemporaryUploadDirectory($0) }
            fileSelectionHandler?(copiedURLs.isEmpty ? nil : copiedURLs)
            fileSelectionHandler = nil
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
            return !["http", "https", "file", "about"].contains(scheme)
        }

        @MainActor
        private func openExternally(_ url: URL) {
            guard UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url)
        }
    }
}

private extension WKWebView {
    func analyticsTopViewController() -> UIViewController? {
        var topController = window?.rootViewController

        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }

        return topController
    }
}

@MainActor
public final class AnalyticsNavigationModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var canGoBack = false
    @Published public var canGoForward = false
    @Published public var errorMessage: String?
    public weak var webView: WKWebView?

    public init() {}

    public func goBack() {
        guard webView?.canGoBack == true else { return }
        webView?.goBack()
        refreshNavigationState()
    }

    public func goForward() {
        guard webView?.canGoForward == true else { return }
        webView?.goForward()
        refreshNavigationState()
    }

    public func reload() {
        webView?.reload()
    }

    public func refreshNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
    }
}
#endif
