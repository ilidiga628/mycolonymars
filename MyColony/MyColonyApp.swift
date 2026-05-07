import SwiftUI

@main
struct MyColonyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ColonyAudioSessionCoordinator.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ColonyLaunchEntry {
                CarnivalRootView()
            }
            .onAppear {
                ColonyAudioSessionCoordinator.handleSceneBecameActive()
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active else { return }
                ColonyAudioSessionCoordinator.handleSceneBecameActive()
            }
        }
    }
}
