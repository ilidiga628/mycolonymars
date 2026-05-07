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
    private var ambientPlayers: [String: AVAudioPlayer] = [:]
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    init() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
        ["coin_collect", "jelly_pop_1", "jelly_pop_2", "storm_burst", "syrup_squish"].forEach(loadPlayer(named:))
        loadAmbientPlayer(named: "jelly_pop_2", key: "day")
        loadAmbientPlayer(named: "storm_burst", key: "night")
        loadAmbientPlayer(named: "coin_collect", key: "harbor")
        loadAmbientPlayer(named: "syrup_squish", key: "reactor")
    }

    func play(_ cue: GameFeedbackCue) {
        switch cue {
        case .tapSuccess:
            impactLight.impactOccurred(intensity: 0.72)
            playSound(named: "jelly_pop_1")

        case .tapDenied:
            notification.notificationOccurred(.warning)
            playSound(named: "syrup_squish")

        case .purchaseSuccess:
            selection.selectionChanged()
            playSound(named: "coin_collect")

        case .autopilotPurchased:
            impactMedium.impactOccurred(intensity: 0.8)
            playSound(named: "coin_collect")

        case .eventSafe:
            selection.selectionChanged()
            playSound(named: "jelly_pop_2")

        case .eventRiskySuccess:
            notification.notificationOccurred(.success)
            playSound(named: "coin_collect")

        case .eventRiskyFail:
            notification.notificationOccurred(.error)
            playSound(named: "storm_burst")

        case .hazardProgress:
            impactMedium.impactOccurred(intensity: 0.95)
            playSound(named: "jelly_pop_2")

        case .hazardResolved:
            impactHeavy.impactOccurred(intensity: 1.0)
            notification.notificationOccurred(.success)
            playSound(named: "storm_burst")
        }
    }

    private func loadPlayer(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[name] = player
        } catch {
            return
        }
    }

    private func playSound(named name: String) {
        guard let player = players[name] else { return }
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
        let colonyActive = (currentTab == .base || currentTab == .colony) && isSceneFocused
        let dayMix = colonyActive ? Float(max(0, 0.18 - sessionProgress * 0.12)) : 0
        let nightMix = colonyActive ? Float(max(0, min(0.18, sessionProgress * 0.16))) : 0
        let harborMix = colonyActive ? Float(min(0.14, Double(harborLevel) * 0.032)) : 0
        let reactorMix = colonyActive ? Float(min(0.16, Double(reactorLevel) * 0.036)) : 0

        setAmbientVolume(key: "day", volume: dayMix, rate: 0.78)
        setAmbientVolume(key: "night", volume: nightMix, rate: 0.52)
        setAmbientVolume(key: "harbor", volume: harborMix, rate: 0.9)
        setAmbientVolume(key: "reactor", volume: reactorMix, rate: 0.68)
    }

    func stopAmbient() {
        ambientPlayers.values.forEach { player in
            player.stop()
            player.currentTime = 0
        }
    }

    private func loadAmbientPlayer(named resource: String, key: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Sounds") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.enableRate = true
            player.prepareToPlay()
            ambientPlayers[key] = player
        } catch {
            return
        }
    }

    private func setAmbientVolume(key: String, volume: Float, rate: Float) {
        guard let player = ambientPlayers[key] else { return }
        player.rate = rate
        player.volume = volume
        if volume > 0.001 {
            if !player.isPlaying {
                player.currentTime = 0
                player.play()
            }
        } else if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
    }
}
