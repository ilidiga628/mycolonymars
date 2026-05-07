import SwiftUI

#if canImport(UIKit)
public struct AnalyticsStart: View {
    public let config: AnalyticsLaunchConfig
    public let languageCode: String
    @State private var isChecking = false
    @State private var statusMessage: String?
    @State private var activeExperience: ActiveAnalyticsDestination?

    public init(config: AnalyticsLaunchConfig, languageCode: String = Locale.current.identifier) {
        self.config = config
        self.languageCode = languageCode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Analytics Check", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(AnalyticsTheme.accent)

            Text("Sends the launch analytics check and continues with the server-provided destination when available.")
                .font(.subheadline)
                .foregroundStyle(AnalyticsTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await checkAndOpen() }
            } label: {
                HStack {
                    if isChecking {
                        ProgressView()
                            .tint(AnalyticsTheme.navy)
                    }
                    Text(isChecking ? "Checking..." : "Check and open")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AnalyticsTheme.accent)
            .foregroundStyle(AnalyticsTheme.navy)
            .disabled(isChecking)

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(AnalyticsTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AnalyticsTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .fullScreenCover(item: $activeExperience) { item in
            NavigationStack {
                AnalyticsDestination(config: item.config)
            }
        }
    }

    @MainActor
    private func checkAndOpen() async {
        isChecking = true
        statusMessage = nil
        defer { isChecking = false }

        do {
            let client = AnalyticsLaunchClient(config: config)
            let response = try await client.checkAccess(languageCode: languageCode)

            guard response.enabled else {
                statusMessage = "Server returned false. Continuing with the local app."
                return
            }

            guard let url = response.url else {
                statusMessage = "Server returned true but did not include a URL."
                return
            }

            activeExperience = ActiveAnalyticsDestination(config: config.withResolvedURL(url))
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
#endif

public struct ActiveAnalyticsDestination: Identifiable {
    public let id = UUID()
    public let config: AnalyticsLaunchConfig

    public init(config: AnalyticsLaunchConfig) {
        self.config = config
    }
}
