import Foundation

enum HazardResponseResult {
    case denied
    case progress
    case resolved
}

enum EventResolutionResult {
    case denied
    case safe
    case riskySuccess
    case riskyFail
}

enum ColonyTab: String, CaseIterable, Identifiable {
    case base
    case colony
    case tech
    case fleet
    case logs

    var id: String { rawValue }
}

enum ColonyHazardType: String, CaseIterable, Codable {
    case dustStorm
    case coolantLeak
    case solarFlare

    var title: String {
        switch self {
        case .dustStorm:
            return "Dust Storm Front"
        case .coolantLeak:
            return "Coolant Leak"
        case .solarFlare:
            return "Solar Flare"
        }
    }

    var detail: String {
        switch self {
        case .dustStorm:
            return "Static sand is burying exposed harvesters and clogging drone intakes."
        case .coolantLeak:
            return "A reactor cooling branch is venting pressure through the command spine."
        case .solarFlare:
            return "Radiation shear is disrupting orbital relays and shipyard uplinks."
        }
    }

    var icon: String {
        switch self {
        case .dustStorm:
            return "wind"
        case .coolantLeak:
            return "drop.triangle.fill"
        case .solarFlare:
            return "sun.max.trianglebadge.exclamationmark.fill"
        }
    }

    var tintHex: Int {
        switch self {
        case .dustStorm:
            return 0xF59E0B
        case .coolantLeak:
            return 0x60A5FA
        case .solarFlare:
            return 0xF97316
        }
    }

    var actionTitle: String {
        switch self {
        case .dustStorm:
            return "CLEAR INTAKES"
        case .coolantLeak:
            return "SEAL LOOP"
        case .solarFlare:
            return "REALIGN RELAYS"
        }
    }
}

struct ColonyHazard: Identifiable, Codable {
    var id = UUID()
    let type: ColonyHazardType
    let affectedSystem: String
    var remainingActions: Int
    let totalActions: Int
    let passivePenalty: Double
    let tapPenalty: Double
    let chargePenalty: Double
    let reward: Double

    var resolvedProgress: Double {
        guard totalActions > 0 else { return 1 }
        return Double(totalActions - remainingActions) / Double(totalActions)
    }
}

enum AutopilotOfferKind: CaseIterable, Identifiable {
    case scoutWindow
    case convoyWindow
    case capitalWindow

    var id: String {
        switch self {
        case .scoutWindow:
            return "scout_window"
        case .convoyWindow:
            return "convoy_window"
        case .capitalWindow:
            return "capital_window"
        }
    }

    var title: String {
        switch self {
        case .scoutWindow:
            return "Scout Window"
        case .convoyWindow:
            return "Convoy Window"
        case .capitalWindow:
            return "Capital Window"
        }
    }

    var subtitle: String {
        switch self {
        case .scoutWindow:
            return "Short premium autopilot burst for quick offline-style income."
        case .convoyWindow:
            return "Longer command contract that keeps cargo and reactors printing."
        case .capitalWindow:
            return "Late-session executive contract built for 5-10 minute runs."
        }
    }

    var duration: TimeInterval {
        switch self {
        case .scoutWindow:
            return 18
        case .convoyWindow:
            return 36
        case .capitalWindow:
            return 54
        }
    }

    var multiplier: Double {
        switch self {
        case .scoutWindow:
            return 1.0
        case .convoyWindow:
            return 1.45
        case .capitalWindow:
            return 1.95
        }
    }

    var flatBonus: Double {
        switch self {
        case .scoutWindow:
            return 1.6
        case .convoyWindow:
            return 4.5
        case .capitalWindow:
            return 8
        }
    }

    var baseCost: Double {
        switch self {
        case .scoutWindow:
            return 85
        case .convoyWindow:
            return 220
        case .capitalWindow:
            return 420
        }
    }

    var tintHex: Int {
        switch self {
        case .scoutWindow:
            return 0x2563EB
        case .convoyWindow:
            return 0xF97316
        case .capitalWindow:
            return 0x60A5FA
        }
    }
}

struct AutopilotOffer: Identifiable {
    let kind: AutopilotOfferKind
    let rate: Double
    let cost: Double

    var id: String { kind.id }
}

enum CommandEventType: String, CaseIterable, Codable {
    case salvageCache
    case blackMarketCell
    case relayGamble

    var title: String {
        switch self {
        case .salvageCache:
            return "Salvage Ping"
        case .blackMarketCell:
            return "Black Market Cell"
        case .relayGamble:
            return "Relay Cipher"
        }
    }

    var detail: String {
        switch self {
        case .salvageCache:
            return "A derelict cache drifted into scan range. Secure it or overclock the salvage run."
        case .blackMarketCell:
            return "A smugglers' cell offers unstable charge packs and temporary reactor automation."
        case .relayGamble:
            return "A shadow relay proposes a risky uplink rewrite for outsized colony output."
        }
    }

    var safeTitle: String {
        switch self {
        case .salvageCache:
            return "Secure haul"
        case .blackMarketCell:
            return "Pay for clean cells"
        case .relayGamble:
            return "Patch the relay"
        }
    }

    var safeDetail: String {
        switch self {
        case .salvageCache:
            return "Smaller reserve gain, no downside."
        case .blackMarketCell:
            return "Spend reserves for a full recharge and a short autopilot burst."
        case .relayGamble:
            return "Stable autopilot boost with no incident."
        }
    }

    var riskyTitle: String {
        switch self {
        case .salvageCache:
            return "Hot extract"
        case .blackMarketCell:
            return "Take contraband"
        case .relayGamble:
            return "Overclock rewrite"
        }
    }

    var riskyDetail: String {
        switch self {
        case .salvageCache:
            return "Big reward, but sand exposure can trigger a storm."
        case .blackMarketCell:
            return "Free power if it works, flare trouble if it does not."
        case .relayGamble:
            return "Massive output spike or a coolant incident."
        }
    }

    var lifetime: TimeInterval {
        14
    }
}

struct TimedCommandEvent: Identifiable, Codable {
    var id = UUID()
    let type: CommandEventType
    var timeRemaining: TimeInterval
    let totalLifetime: TimeInterval

    var progress: Double {
        guard totalLifetime > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalLifetime))
    }
}

struct SaveState: Codable {
    let credits: Double
    let totalCredits: Double
    let charge: Double
    let facilityLevels: [String: Int]
    let techLevels: [String: Int]
    let shipCounts: [String: Int]
    let sessionDuration: TimeInterval
    let lastPurchaseMessage: String
    let unlockedAchievements: [String]
    let activeHazard: ColonyHazard?
    let hazardsCleared: Int
    let activeEvent: TimedCommandEvent?
    let eventsResolved: Int
    let autopilotTimeRemaining: TimeInterval
    let autopilotSnapshotRate: Double
    let nextHazardTime: TimeInterval
    let nextEventTime: TimeInterval
    let safeCombo: Int
    let riskyCombo: Int
    let lastActiveAt: Date
}

enum TechCategory: String, CaseIterable, Identifiable {
    case infrastructure
    case extraction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .infrastructure:
            return "Autopilot Systems"
        case .extraction:
            return "Tap Instruments"
        }
    }

    var subtitle: String {
        switch self {
        case .infrastructure:
            return "Scale temporary passive windows and total reactor charge"
        case .extraction:
            return "Boost manual tap yield and recharge resilience"
        }
    }
}

struct FacilityDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let tintHex: Int
    let baseCost: Double
    let costMultiplier: Double
    let passiveGain: Double
    let tapGain: Double
    let chargeGain: Double
    let regenGain: Double
}

struct TechDefinition: Identifiable {
    let id: String
    let category: TechCategory
    let title: String
    let subtitle: String
    let icon: String
    let tintHex: Int
    let baseCost: Double
    let costMultiplier: Double
    let passiveGain: Double
    let tapGain: Double
    let chargeGain: Double
    let regenGain: Double
}

struct ShipDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let tintHex: Int
    let baseCost: Double
    let costMultiplier: Double
    let output: Double
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
}

enum ShowcaseProfile: String {
    case base
    case colony
    case tech
    case fleet
    case logs
}

final class MarsColonyModel: ObservableObject {
    private static let saveKey = "MyColony.SaveState.v1"
    private static let releaseResetKey = "MyColony.ReleaseReset.v1"
    private static let legacySaveKeys = [
        "NineMars.SaveState",
        "NineMars.LocalMidgameSeed.v1",
        "MyColony.SaveState"
    ]

    @Published var currentTab: ColonyTab = .base
    @Published var credits: Double = 0
    @Published var totalCredits: Double = 0
    @Published var charge: Double = 22
    @Published var maxCharge: Double = 22
    @Published var baseChargeRegen: Double = 1.2
    @Published var chargeRegenRate: Double = 1.2
    @Published var basePassiveRate: Double = 0
    @Published var passiveRate: Double = 0
    @Published var autopilotTimeRemaining: TimeInterval = 0
    @Published var baseTapPower: Double = 1
    @Published var tapPower: Double = 1
    @Published var totalTaps: Int = 0
    @Published var facilityLevels: [String: Int] = [:]
    @Published var techLevels: [String: Int] = [:]
    @Published var shipCounts: [String: Int] = [:]
    @Published var sessionDuration: TimeInterval = 0
    @Published var lastTapGain: Double = 0
    @Published var lastPurchaseMessage: String = "Colony online. Command charge stable."
    @Published var reactorPulse: Int = 0
    @Published var lastCoreTapAt: Date = .distantPast
    @Published var unlockedAchievements: Set<String> = []
    @Published var activeHazard: ColonyHazard?
    @Published var hazardsCleared: Int = 0
    @Published var activeEvent: TimedCommandEvent?
    @Published var eventsResolved: Int = 0
    @Published var safeCombo: Int = 0
    @Published var riskyCombo: Int = 0
    @Published var colonySceneFocus: String = ""
    @Published var colonyScenePulse: Int = 0
    @Published var colonySceneEventDate: Date = .distantPast

    private let sessionStart = Date()
    private var timer: Timer?
    private var lastTick = Date()
    private var accumulatedSessionDuration: TimeInterval = 0
    private var nextHazardTime: TimeInterval = 34
    private var nextEventTime: TimeInterval = 18
    private var autopilotSnapshotRate: Double = 0
    private var lastSaveDate = Date.distantPast

    let facilities: [FacilityDefinition] = [
        FacilityDefinition(
            id: "extractor",
            title: "Helios Extractor",
            subtitle: "Surface drills turn regolith into reserve credits when command taps punch through.",
            icon: "sun.max.fill",
            tintHex: 0xF59E0B,
            baseCost: 110,
            costMultiplier: 1.5,
            passiveGain: 1.1,
            tapGain: 1.0,
            chargeGain: 0,
            regenGain: 0.05
        ),
        FacilityDefinition(
            id: "reactor",
            title: "Blue Reactor",
            subtitle: "Stabilized reactor drums expand usable charge and refill tempo.",
            icon: "bolt.fill",
            tintHex: 0x2563EB,
            baseCost: 360,
            costMultiplier: 1.56,
            passiveGain: 1.5,
            tapGain: 0.6,
            chargeGain: 4,
            regenGain: 0.18
        ),
        FacilityDefinition(
            id: "harbor",
            title: "Orbital Harbor",
            subtitle: "Dock routing improves convoy autopilot contracts and risky uplink odds.",
            icon: "antenna.radiowaves.left.and.right",
            tintHex: 0xF97316,
            baseCost: 1_350,
            costMultiplier: 1.63,
            passiveGain: 5.1,
            tapGain: 0,
            chargeGain: 2,
            regenGain: 0.08
        )
    ]

    let techTree: [TechDefinition] = [
        TechDefinition(
            id: "solar_array",
            category: .infrastructure,
            title: "Solar Array",
            subtitle: "Raises the baseline for purchasable autopilot windows.",
            icon: "sun.max.fill",
            tintHex: 0xF59E0B,
            baseCost: 160,
            costMultiplier: 1.45,
            passiveGain: 0.3,
            tapGain: 0,
            chargeGain: 1,
            regenGain: 0.05
        ),
        TechDefinition(
            id: "fusion_cell",
            category: .infrastructure,
            title: "Fusion Cell",
            subtitle: "Deep reserves increase max charge and reactor refill quality.",
            icon: "atom",
            tintHex: 0x60A5FA,
            baseCost: 820,
            costMultiplier: 1.55,
            passiveGain: 0.85,
            tapGain: 0,
            chargeGain: 3,
            regenGain: 0.16
        ),
        TechDefinition(
            id: "plasma_conduit",
            category: .infrastructure,
            title: "Plasma Conduit",
            subtitle: "Reduces autopilot loss and strengthens timed contracts.",
            icon: "dot.radiowaves.left.and.right",
            tintHex: 0xFB923C,
            baseCost: 3_800,
            costMultiplier: 1.62,
            passiveGain: 3.2,
            tapGain: 0,
            chargeGain: 2,
            regenGain: 0.08
        ),
        TechDefinition(
            id: "quantum_core",
            category: .infrastructure,
            title: "Quantum Core",
            subtitle: "Executive-grade field sync makes premium autopilot windows explosive.",
            icon: "sparkles.square.filled.on.square",
            tintHex: 0xFFFFFF,
            baseCost: 15_000,
            costMultiplier: 1.75,
            passiveGain: 14,
            tapGain: 0,
            chargeGain: 7,
            regenGain: 0.22
        ),
        TechDefinition(
            id: "hand_drill",
            category: .extraction,
            title: "Hand Drill",
            subtitle: "Starter drill assemblies increase reserve yield per tap.",
            icon: "hammer.fill",
            tintHex: 0xF97316,
            baseCost: 100,
            costMultiplier: 1.42,
            passiveGain: 0,
            tapGain: 1.2,
            chargeGain: 0,
            regenGain: 0
        ),
        TechDefinition(
            id: "servo_glove",
            category: .extraction,
            title: "Servo Glove",
            subtitle: "Operators recover charge faster between command bursts.",
            icon: "hand.raised.fill",
            tintHex: 0x2563EB,
            baseCost: 760,
            costMultiplier: 1.48,
            passiveGain: 0,
            tapGain: 4.2,
            chargeGain: 1,
            regenGain: 0.14
        ),
        TechDefinition(
            id: "pneumo_drill",
            category: .extraction,
            title: "Pneumo Drill",
            subtitle: "Industrial pulses turn each live tap into a premium payout.",
            icon: "wrench.and.screwdriver.fill",
            tintHex: 0xF59E0B,
            baseCost: 2_500,
            costMultiplier: 1.55,
            passiveGain: 0,
            tapGain: 11,
            chargeGain: 2,
            regenGain: 0.06
        )
    ]

    let ships: [ShipDefinition] = [
        ShipDefinition(
            id: "scout_pod",
            title: "Scout Pod",
            subtitle: "Recon craft improve event quality and short autopilot output.",
            icon: "paperplane.fill",
            tintHex: 0x60A5FA,
            baseCost: 175,
            costMultiplier: 1.34,
            output: 0.45
        ),
        ShipDefinition(
            id: "mining_drone",
            title: "Mining Drone",
            subtitle: "Drone swarms amplify salvage bursts and dust clear operations.",
            icon: "gearshape.2.fill",
            tintHex: 0xF59E0B,
            baseCost: 760,
            costMultiplier: 1.4,
            output: 1.7
        ),
        ShipDefinition(
            id: "ore_hauler",
            title: "Ore Hauler",
            subtitle: "Cargo hulls make long autopilot contracts materially stronger.",
            icon: "shippingbox.fill",
            tintHex: 0xF97316,
            baseCost: 4_500,
            costMultiplier: 1.48,
            output: 7.8
        ),
        ShipDefinition(
            id: "battle_cruiser",
            title: "Battle Cruiser",
            subtitle: "Escort-class carriers harden risky plays and hazard containment runs.",
            icon: "shield.lefthalf.filled",
            tintHex: 0xFFFFFF,
            baseCost: 25_000,
            costMultiplier: 1.6,
            output: 28
        ),
        ShipDefinition(
            id: "dreadnought",
            title: "Dreadnought",
            subtitle: "Flagship decks supercharge contract windows and crisis recovery.",
            icon: "sparkles.tv.fill",
            tintHex: 0x2563EB,
            baseCost: 200_000,
            costMultiplier: 1.75,
            output: 150
        )
    ]

    let achievements: [AchievementDefinition] = [
        AchievementDefinition(id: "first_tap", title: "First Contact", detail: "Tap the core once", icon: "hand.tap.fill"),
        AchievementDefinition(id: "five_facility", title: "Industrial Dawn", detail: "Reach 5 total facility levels", icon: "building.2.fill"),
        AchievementDefinition(id: "fleet_three", title: "Skyline Ready", detail: "Own 3 ships", icon: "airplane.departure"),
        AchievementDefinition(id: "tech_four", title: "Research Pulse", detail: "Buy 4 tech levels", icon: "point.3.connected.trianglepath.dotted"),
        AchievementDefinition(id: "credits_10k", title: "Ten-K Reserve", detail: "Accumulate 10K total credits", icon: "bolt.circle.fill"),
        AchievementDefinition(id: "hazard_clear", title: "Stormbreaker", detail: "Resolve 3 colony hazards", icon: "checkmark.shield.fill")
    ]

    init() {
        clearLegacyProgressIfNeeded()
        loadProgress()
        recalculateEconomy()
        if charge == 0 {
            charge = maxCharge
        }
        startClock()
    }

    deinit {
        timer?.invalidate()
        persistNow()
    }

    func mineCore() -> Bool {
        let cost = tapChargeCost()
        guard charge >= cost else {
            lastPurchaseMessage = "Reactor charge depleted. Wait for recharge or buy a clean cell window."
            return false
        }

        let gain = tapPower
        charge -= cost
        credits += gain
        totalCredits += gain
        totalTaps += 1
        lastTapGain = gain
        reactorPulse += 1
        lastCoreTapAt = Date()
        lastPurchaseMessage = "Manual extraction delivered +\(formatted(gain)) credits."
        evaluateAchievements()
        persistIfNeeded(force: true)
        return true
    }

    func respondToHazard() -> HazardResponseResult {
        guard var hazard = activeHazard else { return .denied }
        let cost = max(1.2, tapChargeCost() + 0.4)
        guard charge >= cost else {
            lastPurchaseMessage = "Containment needs more live charge before teams can respond."
            return .denied
        }

        charge -= cost
        hazard.remainingActions -= 1
        totalTaps += 1
        reactorPulse += 1
        lastCoreTapAt = Date()

        let stabilizationGain = max(1, baseTapPower * 0.35)
        credits += stabilizationGain
        totalCredits += stabilizationGain

        if hazard.remainingActions <= 0 {
            activeHazard = nil
            hazardsCleared += 1
            credits += hazard.reward
            totalCredits += hazard.reward
            lastPurchaseMessage = "\(hazard.type.title) contained around \(hazard.affectedSystem). +\(formatted(hazard.reward)) credits secured."
            recalculateEconomy()
            persistIfNeeded(force: true)
            return .resolved
        } else {
            activeHazard = hazard
            lastPurchaseMessage = "\(hazard.type.title) mitigation in progress around \(hazard.affectedSystem). \(hazard.remainingActions) actions left."
            recalculateEconomy()
            persistIfNeeded(force: true)
            return .progress
        }
    }

    func upgradeFacility(_ facility: FacilityDefinition) -> Bool {
        let cost = facilityCost(for: facility)
        guard spend(cost) else { return false }
        facilityLevels[facility.id, default: 0] += 1
        recalculateEconomy()
        registerSceneEvent(focus: facility.id)
        lastPurchaseMessage = "\(facility.title) upgraded to level \(facilityLevel(for: facility))."
        persistIfNeeded(force: true)
        return true
    }

    func purchaseTech(_ tech: TechDefinition) -> Bool {
        let cost = techCost(for: tech)
        guard spend(cost) else { return false }
        techLevels[tech.id, default: 0] += 1
        recalculateEconomy()
        registerSceneEvent(focus: tech.id)
        lastPurchaseMessage = "\(tech.title) research advanced to level \(techLevel(for: tech))."
        persistIfNeeded(force: true)
        return true
    }

    func purchaseShip(_ ship: ShipDefinition) -> Bool {
        let cost = shipCost(for: ship)
        guard spend(cost) else { return false }
        shipCounts[ship.id, default: 0] += 1
        recalculateEconomy()
        registerSceneEvent(focus: ship.id)
        lastPurchaseMessage = "\(ship.title) deployed to the Martian network."
        persistIfNeeded(force: true)
        return true
    }

    func purchaseAutopilot(_ offer: AutopilotOffer) -> Bool {
        guard spend(offer.cost) else { return false }

        let effectiveRate = offer.rate * passiveEfficiency()
        autopilotSnapshotRate = max(autopilotSnapshotRate, effectiveRate)
        autopilotTimeRemaining += offer.kind.duration
        if charge < maxCharge * 0.4 {
            charge = min(maxCharge, charge + maxCharge * 0.18)
        }
        recalculateEconomy()
        registerSceneEvent(focus: "harbor")
        lastPurchaseMessage = "\(offer.kind.title) contracted for \(Int(offer.kind.duration))s at \(formatted(effectiveRate))/s."
        persistIfNeeded(force: true)
        return true
    }

    func applyShowcase(profile: ShowcaseProfile) {
        facilityLevels = [
            "extractor": 5,
            "reactor": 4,
            "harbor": 3
        ]

        techLevels = [
            "solar_array": 4,
            "fusion_cell": 3,
            "plasma_conduit": 2,
            "quantum_core": 1,
            "hand_drill": 4,
            "servo_glove": 3,
            "pneumo_drill": 2
        ]

        shipCounts = [
            "scout_pod": 6,
            "mining_drone": 4,
            "ore_hauler": 3,
            "battle_cruiser": 2,
            "dreadnought": 1
        ]

        credits = 186_400
        totalCredits = max(totalCredits, 742_000)
        totalTaps = max(totalTaps, 3_240)
        hazardsCleared = max(hazardsCleared, 7)
        eventsResolved = max(eventsResolved, 11)
        safeCombo = 4
        riskyCombo = 2
        accumulatedSessionDuration = 548
        sessionDuration = accumulatedSessionDuration
        unlockedAchievements = Set(achievements.map(\.id))
        activeHazard = nil
        activeEvent = nil
        autopilotTimeRemaining = 42
        autopilotSnapshotRate = 26.8
        nextHazardTime = sessionDuration + 28
        nextEventTime = sessionDuration + 18
        lastPurchaseMessage = "Showcase mode active. My Colony command sectors are synced for capture."

        recalculateEconomy()
        charge = maxCharge
        lastTapGain = tapPower
        lastCoreTapAt = Date()

        switch profile {
        case .base:
            currentTab = .base
            colonySceneFocus = "reactor"

        case .colony:
            currentTab = .colony
            colonySceneFocus = "harbor"

        case .tech:
            currentTab = .tech
            colonySceneFocus = "solar_array"

        case .fleet:
            currentTab = .fleet
            colonySceneFocus = "dreadnought"

        case .logs:
            currentTab = .logs
            colonySceneFocus = "fleet"
        }

        colonyScenePulse += 1
        colonySceneEventDate = Date()
    }

    func resolveEvent(safeChoice: Bool) -> EventResolutionResult {
        guard let event = activeEvent else { return .denied }
        defer { evaluateAchievements() }
        activeEvent = nil
        eventsResolved += 1

        switch event.type {
        case .salvageCache:
            if safeChoice {
                safeCombo += 1
                riskyCombo = 0
                let reward = 42 + Double(totalShips()) * 8
                credits += reward
                totalCredits += reward
                applyComboBonusesIfNeeded()
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Salvage secured. +\(formatted(reward)) credits added to reserves."
                return .safe
            } else if riskyRollSucceeded() {
                riskyCombo += 1
                safeCombo = 0
                let reward = (120 + Double(shipCount(with: "mining_drone")) * 12) * (1 + Double(riskyCombo - 1) * 0.18)
                credits += reward
                totalCredits += reward
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Hot extract landed clean. +\(formatted(reward)) credits captured."
                return .riskySuccess
            } else {
                riskyCombo = 0
                safeCombo = max(0, safeCombo - 1)
                forceHazard(.dustStorm)
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Hot extract failed. Dust shear hit the harvest corridor."
                return .riskyFail
            }

        case .blackMarketCell:
            if safeChoice {
                safeCombo += 1
                riskyCombo = 0
                let cost = 45.0
                guard spend(cost) else {
                    lastPurchaseMessage = "The clean cell dealer wants more reserves."
                    return .denied
                }
                charge = maxCharge
                autopilotSnapshotRate = max(autopilotSnapshotRate, max(2, basePassiveRate + 1.8))
                autopilotTimeRemaining += 12
                applyComboBonusesIfNeeded()
                recalculateEconomy()
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Clean cells installed. Full recharge and a short autopilot pulse online."
                return .safe
            } else if riskyRollSucceeded() {
                riskyCombo += 1
                safeCombo = 0
                charge = maxCharge
                autopilotSnapshotRate = max(autopilotSnapshotRate, max(3, basePassiveRate * (1.25 + Double(riskyCombo - 1) * 0.08) + 3))
                autopilotTimeRemaining += 18
                recalculateEconomy()
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Contraband cells held. Full recharge and an aggressive autopilot burst activated."
                return .riskySuccess
            } else {
                riskyCombo = 0
                safeCombo = max(0, safeCombo - 1)
                forceHazard(.solarFlare)
                charge = max(0, charge - 3)
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Counterfeit cells backfired and attracted a flare cascade."
                return .riskyFail
            }

        case .relayGamble:
            if safeChoice {
                safeCombo += 1
                riskyCombo = 0
                autopilotSnapshotRate = max(autopilotSnapshotRate, max(2.2, basePassiveRate * 1.1 + 1.8))
                autopilotTimeRemaining += 12
                applyComboBonusesIfNeeded()
                recalculateEconomy()
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Relay patch stabilized. Output window extended without incident."
                return .safe
            } else if riskyRollSucceeded() {
                riskyCombo += 1
                safeCombo = 0
                autopilotSnapshotRate = max(autopilotSnapshotRate, max(3.8, basePassiveRate * 1.65 + 5))
                autopilotTimeRemaining += 22
                let bonus = 50 * (1 + Double(riskyCombo - 1) * 0.15)
                credits += bonus
                totalCredits += bonus
                recalculateEconomy()
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Relay rewrite hit. Massive contract output unlocked and bonus reserves captured."
                return .riskySuccess
            } else {
                riskyCombo = 0
                safeCombo = max(0, safeCombo - 1)
                forceHazard(.coolantLeak)
                persistIfNeeded(force: true)
                lastPurchaseMessage = "Relay overclock destabilized the cooling spine."
                return .riskyFail
            }
        }
    }

    func facilityLevel(for facility: FacilityDefinition) -> Int {
        facilityLevels[facility.id, default: 0]
    }

    func techLevel(for tech: TechDefinition) -> Int {
        techLevels[tech.id, default: 0]
    }

    func shipCount(for ship: ShipDefinition) -> Int {
        shipCounts[ship.id, default: 0]
    }

    func shipCount(with id: String) -> Int {
        shipCounts[id, default: 0]
    }

    func districtLevel(id: String) -> Int {
        facilityLevels[id, default: 0]
    }

    func researchLevel(id: String) -> Int {
        techLevels[id, default: 0]
    }

    func facilityCost(for facility: FacilityDefinition) -> Double {
        scaledCost(base: facility.baseCost, multiplier: facility.costMultiplier, level: facilityLevel(for: facility))
    }

    func techCost(for tech: TechDefinition) -> Double {
        scaledCost(base: tech.baseCost, multiplier: tech.costMultiplier, level: techLevel(for: tech))
    }

    func shipCost(for ship: ShipDefinition) -> Double {
        scaledCost(base: ship.baseCost, multiplier: ship.costMultiplier, level: shipCount(for: ship))
    }

    func isAffordable(_ cost: Double) -> Bool {
        credits >= cost
    }

    func totalFacilityLevels() -> Int {
        facilityLevels.values.reduce(0, +)
    }

    func totalTechLevels() -> Int {
        techLevels.values.reduce(0, +)
    }

    func totalShips() -> Int {
        shipCounts.values.reduce(0, +)
    }

    func fleetOutput() -> Double {
        ships.reduce(0) { partialResult, ship in
            partialResult + Double(shipCount(for: ship)) * ship.output
        }
    }

    func unlockedShipTypes() -> Int {
        ships.filter { shipCount(for: $0) > 0 }.count
    }

    func passiveEfficiency() -> Double {
        max(0.2, 1 - (activeHazard?.passivePenalty ?? 0))
    }

    func tapEfficiency() -> Double {
        max(0.35, 1 - (activeHazard?.tapPenalty ?? 0))
    }

    func chargeEfficiency() -> Double {
        max(0.35, 1 - (activeHazard?.chargePenalty ?? 0))
    }

    func colonyStability() -> Double {
        let penaltyWeight = (activeHazard?.passivePenalty ?? 0) + (activeHazard?.tapPenalty ?? 0) + (activeHazard?.chargePenalty ?? 0)
        let progressionBonus = min(0.24, Double(totalFacilityLevels() + totalTechLevels() + totalShips()) * 0.009)
        return min(1, max(0.2, 0.72 - penaltyWeight * 0.65 + progressionBonus))
    }

    func alertLevelLabel() -> String {
        guard let activeHazard else { return activeEvent == nil ? "Nominal" : "Opportunity" }
        let penalty = activeHazard.passivePenalty + activeHazard.tapPenalty + activeHazard.chargePenalty
        switch penalty {
        case 0.55...:
            return "Critical"
        case 0.3...:
            return "Elevated"
        default:
            return "Watch"
        }
    }

    func tapsPerMinute() -> Double {
        guard sessionDuration > 0 else { return Double(totalTaps) }
        return Double(totalTaps) / max(sessionDuration / 60, 1)
    }

    func achievementUnlocked(_ achievement: AchievementDefinition) -> Bool {
        unlockedAchievements.contains(achievement.id)
    }

    func categoryItems(for category: TechCategory) -> [TechDefinition] {
        techTree.filter { $0.category == category }
    }

    func sessionTier() -> Int {
        let progression = totalFacilityLevels() + totalTechLevels() + totalShips()
        if accumulatedSessionDuration >= 480 || progression >= 18 { return 4 }
        if accumulatedSessionDuration >= 300 || progression >= 12 { return 3 }
        if accumulatedSessionDuration >= 120 || progression >= 6 { return 2 }
        return 1
    }

    func sessionTierLabel() -> String {
        switch sessionTier() {
        case 4:
            return "Tier IV"
        case 3:
            return "Tier III"
        case 2:
            return "Tier II"
        default:
            return "Tier I"
        }
    }

    func comboDescriptor() -> String {
        if riskyCombo > 0 { return "Risk x\(riskyCombo)" }
        if safeCombo > 0 { return "Safe x\(safeCombo)" }
        return "No combo"
    }

    func comboMomentumTitle() -> String {
        if riskyCombo >= 4 { return "Risk Chain Surging" }
        if riskyCombo > 0 { return "Risk Chain Online" }
        if safeCombo >= 3 { return "Safe Chain Stable" }
        if safeCombo > 0 { return "Safe Chain Building" }
        return "Momentum Idle"
    }

    func comboMomentumDetail() -> String {
        if riskyCombo > 0 {
            return "Risk streaks amplify event payouts and keep late-session spikes exciting."
        }
        if safeCombo > 0 {
            return "Safe streaks feed bonus credits and recharge bursts every third decision."
        }
        return "Timed decisions build streaks that shape your 5-10 minute command run."
    }

    func comboProgress() -> Double {
        if riskyCombo > 0 {
            return min(1, Double(riskyCombo) / 4)
        }
        if safeCombo > 0 {
            return min(1, Double(safeCombo % 3 == 0 ? 3 : safeCombo % 3) / 3)
        }
        return 0.08
    }

    func comboTintHex() -> Int {
        riskyCombo > 0 ? 0xF97316 : 0x60A5FA
    }

    func nextTierProgress() -> Double {
        let checkpoints = [120.0, 300.0, 480.0]
        let current = accumulatedSessionDuration

        switch sessionTier() {
        case 1:
            return min(1, current / checkpoints[0])
        case 2:
            return min(1, max(0, (current - checkpoints[0]) / (checkpoints[1] - checkpoints[0])))
        case 3:
            return min(1, max(0, (current - checkpoints[1]) / (checkpoints[2] - checkpoints[1])))
        default:
            return 1
        }
    }

    func nextTierDetail() -> String {
        let current = accumulatedSessionDuration
        switch sessionTier() {
        case 1:
            return "Tier II in ~\(max(0, Int(ceil((120 - current) / 60))))m: faster events and denser upgrades."
        case 2:
            return "Tier III unlocks Capital Window and harder spikes after ~\(max(0, Int(ceil((300 - current) / 60))))m."
        case 3:
            return "Tier IV pushes hazard pressure and premium contract tempo in ~\(max(0, Int(ceil((480 - current) / 60))))m."
        default:
            return "Tier IV active: full session pressure and top-end contract cadence online."
        }
    }

    func autopilotOffers() -> [AutopilotOffer] {
        AutopilotOfferKind.allCases.filter { kind in
            kind != .capitalWindow || sessionTier() >= 3
        }.map { kind in
            let scaledRate = max(1.5, basePassiveRate * kind.multiplier + kind.flatBonus + Double(shipCount(with: "ore_hauler")) * 0.35)
            let scaledCost = kind.baseCost + Double(totalFacilityLevels() + totalTechLevels()) * 18
            return AutopilotOffer(kind: kind, rate: scaledRate, cost: ceil(scaledCost))
        }
    }

    func tapChargeCost() -> Double {
        max(0.74, 1 - Double(techLevel(with: "servo_glove")) * 0.025)
    }

    func chargeFraction() -> Double {
        guard maxCharge > 0 else { return 0 }
        return max(0, min(1, charge / maxCharge))
    }

    func formatted(_ value: Double) -> String {
        switch value {
        case 100_000...:
            return String(format: "%.0fK", value / 1_000)
        case 10_000...:
            return String(format: "%.1fK", value / 1_000)
        case 1_000...:
            return String(format: "%.1fK", value / 1_000)
        case 100...:
            return String(format: "%.0f", value)
        case 10...:
            return String(format: "%.1f", value)
        default:
            return String(format: "%.2f", value)
        }
    }

    func durationText() -> String {
        let totalSeconds = Int(sessionDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    func activeHazardOverlayStrength() -> Double {
        guard let activeHazard else { return 0 }
        return max(0.25, min(1, (activeHazard.passivePenalty + activeHazard.tapPenalty + activeHazard.chargePenalty) * 1.25))
    }

    func facilityBenefitText(for facility: FacilityDefinition) -> String {
        switch facility.id {
        case "extractor":
            return "+\(formatted(facility.passiveGain))/s contract power, +\(formatted(facility.tapGain)) tap"
        case "reactor":
            return "+\(Int(facility.chargeGain)) max charge, +\(formatted(facility.regenGain))/s regen"
        case "harbor":
            return "+\(formatted(facility.passiveGain))/s contract strength and safer risky plays"
        default:
            return "+\(formatted(facility.passiveGain))/s potential"
        }
    }

    func facilityCurrentImpactText(for facility: FacilityDefinition) -> String {
        let level = facilityLevel(for: facility)
        guard level > 0 else { return "No live output yet. Upgrade to activate this district." }

        let passive = Double(level) * facility.passiveGain
        let tap = Double(level) * facility.tapGain
        let chargeCap = Double(level) * facility.chargeGain
        let regen = Double(level) * facility.regenGain

        var chunks: [String] = []
        if passive > 0 { chunks.append("\(formatted(passive))/s contract potential") }
        if tap > 0 { chunks.append("+\(formatted(tap)) tap power") }
        if chargeCap > 0 { chunks.append("+\(Int(chargeCap)) charge cap") }
        if regen > 0 { chunks.append("+\(formatted(regen))/s charge regen") }
        return chunks.joined(separator: "  •  ")
    }

    func techBenefitText(for tech: TechDefinition) -> String {
        if tech.passiveGain > 0 && tech.chargeGain > 0 {
            return "+\(formatted(tech.passiveGain))/s potential • +\(Int(tech.chargeGain)) cap"
        }
        if tech.tapGain > 0 && tech.regenGain > 0 {
            return "+\(formatted(tech.tapGain)) tap and +\(formatted(tech.regenGain))/s regen"
        }
        if tech.tapGain > 0 {
            return "+\(formatted(tech.tapGain)) tap per level"
        }
        return "+\(formatted(tech.passiveGain))/s autopilot potential"
    }

    func techCurrentImpactText(for tech: TechDefinition) -> String {
        let level = techLevel(for: tech)
        guard level > 0 else { return "Research not deployed yet." }

        let passive = Double(level) * tech.passiveGain
        let tap = Double(level) * tech.tapGain
        let chargeCap = Double(level) * tech.chargeGain
        let regen = Double(level) * tech.regenGain

        var chunks: [String] = []
        if passive > 0 { chunks.append("\(formatted(passive))/s autopilot baseline") }
        if tap > 0 { chunks.append("+\(formatted(tap)) live tap") }
        if chargeCap > 0 { chunks.append("+\(Int(chargeCap)) charge cap") }
        if regen > 0 { chunks.append("+\(formatted(regen))/s regen") }
        return chunks.joined(separator: "  •  ")
    }

    func shipBenefitText(for ship: ShipDefinition) -> String {
        "\(formatted(ship.output))/s contract power  ·  Total: \(formatted(Double(shipCount(with: ship.id)) * ship.output))/s"
    }

    private func techLevel(with id: String) -> Int {
        techLevels[id, default: 0]
    }

    private func scaledCost(base: Double, multiplier: Double, level: Int) -> Double {
        ceil(base * pow(multiplier, Double(level)))
    }

    private func spend(_ cost: Double) -> Bool {
        guard credits >= cost else {
            lastPurchaseMessage = "Insufficient reserves. Push more taps or resolve an event first."
            return false
        }
        credits -= cost
        return true
    }

    func persistNow() {
        let state = SaveState(
            credits: credits,
            totalCredits: totalCredits,
            charge: charge,
            facilityLevels: facilityLevels,
            techLevels: techLevels,
            shipCounts: shipCounts,
            sessionDuration: accumulatedSessionDuration,
            lastPurchaseMessage: lastPurchaseMessage,
            unlockedAchievements: Array(unlockedAchievements),
            activeHazard: activeHazard,
            hazardsCleared: hazardsCleared,
            activeEvent: activeEvent,
            eventsResolved: eventsResolved,
            autopilotTimeRemaining: autopilotTimeRemaining,
            autopilotSnapshotRate: autopilotSnapshotRate,
            nextHazardTime: nextHazardTime,
            nextEventTime: nextEventTime,
            safeCombo: safeCombo,
            riskyCombo: riskyCombo,
            lastActiveAt: Date()
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
        lastSaveDate = Date()
    }

    private func persistIfNeeded(force: Bool = false) {
        if force || Date().timeIntervalSince(lastSaveDate) > 2.5 {
            persistNow()
        }
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let state = try? JSONDecoder().decode(SaveState.self, from: data) else { return }

        credits = state.credits
        totalCredits = state.totalCredits
        charge = state.charge
        facilityLevels = state.facilityLevels
        techLevels = state.techLevels
        shipCounts = state.shipCounts
        accumulatedSessionDuration = state.sessionDuration
        sessionDuration = state.sessionDuration
        lastPurchaseMessage = state.lastPurchaseMessage
        unlockedAchievements = Set(state.unlockedAchievements)
        activeHazard = state.activeHazard
        hazardsCleared = state.hazardsCleared
        activeEvent = state.activeEvent
        eventsResolved = state.eventsResolved
        autopilotTimeRemaining = state.autopilotTimeRemaining
        autopilotSnapshotRate = state.autopilotSnapshotRate
        nextHazardTime = state.nextHazardTime
        nextEventTime = state.nextEventTime
        safeCombo = state.safeCombo
        riskyCombo = state.riskyCombo

        recalculateEconomy()
        applyOfflineProgress(since: state.lastActiveAt)
    }

    private func clearLegacyProgressIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Self.releaseResetKey) == false else { return }
        Self.legacySaveKeys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.set(true, forKey: Self.releaseResetKey)
    }

    private func applyOfflineProgress(since lastActiveAt: Date) {
        let elapsed = max(0, Date().timeIntervalSince(lastActiveAt))
        guard elapsed > 0 else { return }

        let previousAutopilotTime = autopilotTimeRemaining
        let autopilotDelta = min(previousAutopilotTime, elapsed)
        if autopilotDelta > 0 {
            let income = autopilotSnapshotRate * passiveEfficiency() * autopilotDelta
            credits += income
            totalCredits += income
        }

        charge = min(maxCharge, charge + chargeRegenRate * elapsed)

        if var event = activeEvent {
            event.timeRemaining = max(0, event.timeRemaining - elapsed)
            if event.timeRemaining > 0 {
                activeEvent = event
            } else {
                activeEvent = nil
                nextEventTime = max(6, sessionDuration + 10)
            }
        }

        autopilotTimeRemaining = max(0, autopilotTimeRemaining - elapsed)
        nextHazardTime = max(6, nextHazardTime - elapsed)
        nextEventTime = max(6, nextEventTime - elapsed)

        if previousAutopilotTime > 0 && autopilotTimeRemaining == 0 {
            lastPurchaseMessage = "Autopilot contract closed while command was away. Manual extraction resumed on return."
        } else if elapsed >= 15 {
            lastPurchaseMessage = "Command resumed after \(Int(elapsed))s offline. Charge, timers and contracts were advanced."
        }

        recalculateEconomy()
    }

    private func applyComboBonusesIfNeeded() {
        if safeCombo > 0 && safeCombo.isMultiple(of: 3) {
            credits += 32
            totalCredits += 32
            charge = min(maxCharge, charge + 4)
            lastPurchaseMessage = "Safe combo bonus online. Discipline granted bonus reserves and a recharge burst."
        }
    }

    private func recalculateEconomy() {
        let facilityPassive = facilities.reduce(0) { $0 + Double(facilityLevel(for: $1)) * $1.passiveGain }
        let facilityTap = facilities.reduce(0) { $0 + Double(facilityLevel(for: $1)) * $1.tapGain }
        let facilityCharge = facilities.reduce(0) { $0 + Double(facilityLevel(for: $1)) * $1.chargeGain }
        let facilityRegen = facilities.reduce(0) { $0 + Double(facilityLevel(for: $1)) * $1.regenGain }

        let techPassive = techTree.reduce(0) { $0 + Double(techLevel(for: $1)) * $1.passiveGain }
        let techTap = techTree.reduce(0) { $0 + Double(techLevel(for: $1)) * $1.tapGain }
        let techCharge = techTree.reduce(0) { $0 + Double(techLevel(for: $1)) * $1.chargeGain }
        let techRegen = techTree.reduce(0) { $0 + Double(techLevel(for: $1)) * $1.regenGain }

        basePassiveRate = facilityPassive + techPassive + fleetOutput()
        baseTapPower = 1 + facilityTap + techTap
        maxCharge = 22 + facilityCharge + techCharge
        baseChargeRegen = 1.2 + facilityRegen + techRegen + Double(shipCount(with: "scout_pod")) * 0.025
        chargeRegenRate = baseChargeRegen * chargeEfficiency()
        tapPower = baseTapPower * tapEfficiency()

        if autopilotTimeRemaining > 0 {
            passiveRate = autopilotSnapshotRate * passiveEfficiency()
        } else {
            passiveRate = 0
            autopilotSnapshotRate = 0
        }

        charge = min(charge, maxCharge)
        evaluateAchievements()
    }

    private func evaluateAchievements() {
        if totalTaps >= 1 { unlockedAchievements.insert("first_tap") }
        if totalFacilityLevels() >= 5 { unlockedAchievements.insert("five_facility") }
        if totalShips() >= 3 { unlockedAchievements.insert("fleet_three") }
        if totalTechLevels() >= 4 { unlockedAchievements.insert("tech_four") }
        if totalCredits >= 10_000 { unlockedAchievements.insert("credits_10k") }
        if hazardsCleared >= 3 { unlockedAchievements.insert("hazard_clear") }
    }

    private func startClock() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let now = Date()
        let delta = now.timeIntervalSince(lastTick)
        lastTick = now
        accumulatedSessionDuration += delta

        charge = min(maxCharge, charge + chargeRegenRate * delta)

        if autopilotTimeRemaining > 0 {
            autopilotTimeRemaining = max(0, autopilotTimeRemaining - delta)
            let income = passiveRate * delta
            if income > 0 {
                credits += income
                totalCredits += income
            }
            if autopilotTimeRemaining == 0 {
                recalculateEconomy()
                lastPurchaseMessage = "Autopilot contract completed. Manual command is back in focus."
            }
        }

        if var activeEvent {
            activeEvent.timeRemaining = max(0, activeEvent.timeRemaining - delta)
            self.activeEvent = activeEvent.timeRemaining > 0 ? activeEvent : nil
            if activeEvent.timeRemaining == 0 {
                lastPurchaseMessage = "\(activeEvent.type.title) window expired before command acted."
                nextEventTime = sessionDuration + Double.random(in: 18...30)
            }
        }

        sessionDuration = accumulatedSessionDuration
        maybeSpawnEvent()
        maybeSpawnHazard()
        evaluateAchievements()
        persistIfNeeded()
    }

    private func maybeSpawnEvent() {
        guard activeEvent == nil else { return }
        guard sessionDuration >= nextEventTime else { return }

        let type = CommandEventType.allCases.randomElement() ?? .salvageCache
        activeEvent = TimedCommandEvent(type: type, timeRemaining: type.lifetime, totalLifetime: type.lifetime)
        let tier = sessionTier()
        let lower = max(12, 24 - tier * 2)
        let upper = max(lower + 4, 34 - tier * 2)
        nextEventTime = sessionDuration + Double.random(in: Double(lower)...Double(upper))
        lastPurchaseMessage = "\(type.title) available. Choose a safe line or push a risky play."
    }

    private func maybeSpawnHazard() {
        guard activeHazard == nil else { return }
        guard sessionDuration >= nextHazardTime else { return }
        guard totalFacilityLevels() + totalTechLevels() + totalShips() >= 2 else {
            nextHazardTime += 8
            return
        }

        let hazardType = eligibleHazardTypes().randomElement() ?? .dustStorm
        spawnHazard(hazardType)
        let tier = sessionTier()
        let lower = max(18, 30 - tier * 2)
        let upper = max(lower + 6, 42 - tier * 2)
        nextHazardTime = sessionDuration + Double.random(in: Double(lower)...Double(upper))
    }

    private func eligibleHazardTypes() -> [ColonyHazardType] {
        var types: [ColonyHazardType] = [.dustStorm]
        if facilityLevel(with: "reactor") > 0 || techLevel(with: "fusion_cell") > 0 {
            types.append(.coolantLeak)
        }
        if facilityLevel(with: "harbor") > 0 || shipCount(with: "scout_pod") > 0 || shipCount(with: "ore_hauler") > 0 {
            types.append(.solarFlare)
        }
        return types
    }

    private func forceHazard(_ type: ColonyHazardType) {
        activeHazard = nil
        spawnHazard(type)
        nextHazardTime = max(nextHazardTime, sessionDuration + 18)
    }

    private func registerSceneEvent(focus: String) {
        colonySceneFocus = focus
        colonyScenePulse += 1
        colonySceneEventDate = Date()
    }

    private func spawnHazard(_ type: ColonyHazardType) {
        let systemInfo = systemForHazard(type)
        let level = systemInfo.level
        let severity = max(1, min(5, 1 + level / 2))
        let basePenalty = 0.11 + Double(severity) * 0.04

        let hazard = ColonyHazard(
            type: type,
            affectedSystem: systemInfo.name,
            remainingActions: 2 + severity,
            totalActions: 2 + severity,
            passivePenalty: type == .coolantLeak ? basePenalty * 0.8 : basePenalty,
            tapPenalty: type == .dustStorm ? 0.08 + Double(severity) * 0.02 : basePenalty * 0.45,
            chargePenalty: type == .solarFlare ? basePenalty * 0.65 : basePenalty * 0.5,
            reward: 55 + Double(severity) * 35
        )

        activeHazard = hazard
        recalculateEconomy()
        lastPurchaseMessage = "\(hazard.type.title) detected around \(hazard.affectedSystem). Immediate action recommended."
    }

    private func systemForHazard(_ type: ColonyHazardType) -> (name: String, level: Int) {
        switch type {
        case .dustStorm:
            let level = facilityLevel(with: "extractor") + shipCount(with: "mining_drone")
            return ("Helios Extractor Array", max(1, level))
        case .coolantLeak:
            let level = facilityLevel(with: "reactor") + techLevel(with: "fusion_cell") + techLevel(with: "plasma_conduit")
            return ("Blue Reactor Spine", max(1, level))
        case .solarFlare:
            let level = facilityLevel(with: "harbor") + shipCount(with: "scout_pod") + shipCount(with: "ore_hauler")
            return ("Orbital Harbor Uplink", max(1, level))
        }
    }

    private func riskyRollSucceeded() -> Bool {
        let harborBonus = Double(facilityLevel(with: "harbor")) * 0.035
        let scoutBonus = Double(shipCount(with: "scout_pod")) * 0.02
        let cruiserBonus = Double(shipCount(with: "battle_cruiser")) * 0.015
        let chance = min(0.86, 0.55 + harborBonus + scoutBonus + cruiserBonus)
        return Double.random(in: 0...1) <= chance
    }

    private func facilityLevel(with id: String) -> Int {
        facilityLevels[id, default: 0]
    }
}
