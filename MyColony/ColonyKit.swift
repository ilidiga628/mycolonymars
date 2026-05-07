import SwiftUI
import AnalyticsKit

enum ColonyKit {
    static let launchConfig = AnalyticsLaunchConfig(
        serverDomain: "sweetgarden.ink",
        analyticsToken: "e95c8353761ebb1e022ca1ebbd05762eb94132ca907a214e0f092abaf110b85d",
        bundleID: "com.ninemars.colony"
    )
}

struct ColonyLaunchEntry<NativeContent: View>: View {
    private let nativeContent: () -> NativeContent

    init(@ViewBuilder content: @escaping () -> NativeContent) {
        self.nativeContent = content
    }

    var body: some View {
        AnalyticsEntry(
            config: ColonyKit.launchConfig,
            requestReviewBeforeCheck: false
        ) {
            nativeContent()
        }
    }
}
