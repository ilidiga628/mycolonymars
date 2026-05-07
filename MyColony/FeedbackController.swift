import AVFoundation
import UIKit
import Foundation

enum GameFeedbackCue {
    case tapSuccess
    case tapDenied
    case purchaseSuccess
    case autopilotPurchased
    case eventSafe
    case eventRiskySuccess
    case eventRiskyFail
    case hazardProgress
    case hazardResolved
}

final class FeedbackController: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    init() {
        ColonyAudioSessionCoordinator.handleSceneBecameActive()
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
        ["coin_collect", "jelly_pop_1", "jelly_pop_2", "storm_burst", "syrup_squish"].forEach(loadPlayer(named:))
    }

    func play(_ cue: GameFeedbackCue) {
        switch cue {
        case .tapSuccess:
            impactLight.impactOccurred(intensity: 0.5)
            playSound(named: "jelly_pop_1", volume: 0.18)

        case .tapDenied:
            notification.notificationOccurred(.warning)
            playSound(named: "syrup_squish", volume: 0.12)

        case .purchaseSuccess:
            selection.selectionChanged()
            playSound(named: "coin_collect", volume: 0.22)

        case .autopilotPurchased:
            impactMedium.impactOccurred(intensity: 0.62)
            playSound(named: "coin_collect", volume: 0.2)

        case .eventSafe:
            selection.selectionChanged()
            playSound(named: "jelly_pop_2", volume: 0.16)

        case .eventRiskySuccess:
            notification.notificationOccurred(.success)
            playSound(named: "coin_collect", volume: 0.24)

        case .eventRiskyFail:
            notification.notificationOccurred(.error)
            playSound(named: "storm_burst", volume: 0.14)

        case .hazardProgress:
            impactMedium.impactOccurred(intensity: 0.58)
            playSound(named: "jelly_pop_2", volume: 0.14)

        case .hazardResolved:
            impactHeavy.impactOccurred(intensity: 0.72)
            notification.notificationOccurred(.success)
            playSound(named: "storm_burst", volume: 0.18)
        }
    }

    private func loadPlayer(named name: String) {
        guard let url = soundURL(named: name) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[name] = player
        } catch {
            return
        }
    }

    private func playSound(named name: String, volume: Float) {
        guard let player = players[name] else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    func updateAmbient(
        currentTab: ColonyTab,
        sessionProgress: Double,
        harborLevel: Int,
        reactorLevel: Int,
        isSceneFocused: Bool
    ) {
        _ = currentTab
        _ = sessionProgress
        _ = harborLevel
        _ = reactorLevel
        _ = isSceneFocused
        stopAmbient()
    }

    func stopAmbient() {}

    private func soundURL(named name: String) -> URL? {
        if let nestedURL = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds") {
            return nestedURL
        }
        return Bundle.main.url(forResource: name, withExtension: "wav")
    }
}
