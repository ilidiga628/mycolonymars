import SwiftUI
import Combine

enum LaunchShowcaseMode: Equatable {
    case none
    case tab(ShowcaseProfile)
    case video
    case fastVideo

    static var current: LaunchShowcaseMode {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--showcase-video-fast") {
            return .fastVideo
        }
        if arguments.contains("--showcase-video") {
            return .video
        }

        guard let index = arguments.firstIndex(of: "--showcase-tab"),
              arguments.indices.contains(index + 1),
              let profile = ShowcaseProfile(rawValue: arguments[index + 1]) else {
            return .none
        }

        return .tab(profile)
    }
}

struct CarnivalRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = MarsColonyModel()
    @StateObject private var feedback = FeedbackController()
    @State private var showcaseTask: Task<Void, Never>?
    private let showcaseMode = LaunchShowcaseMode.current

    var body: some View {
        ZStack {
            ColonyBackground(
                activeHazard: model.activeHazard?.type,
                intensity: model.activeHazardOverlayStrength()
            )

            VStack(spacing: 18) {
                header

                Group {
                    switch model.currentTab {
                    case .base:
                        BaseOverviewScreen(model: model, feedback: feedback)
                    case .colony:
                        ColonyOperationsScreen(model: model)
                    case .tech:
                        TechTreeScreen(model: model, feedback: feedback)
                    case .fleet:
                        FleetMarketScreen(model: model, feedback: feedback)
                    case .logs:
                        MissionLogsScreen(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                MissionFooterBar(selected: model.currentTab) { tab in
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        model.currentTab = tab
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            applyShowcaseIfNeeded()
            syncAmbient()
        }
        .onDisappear {
            showcaseTask?.cancel()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                model.persistNow()
                feedback.stopAmbient()
            } else {
                syncAmbient()
            }
        }
        .onChange(of: model.currentTab) { _ in
            syncAmbient()
        }
        .onReceive(model.$sessionDuration) { _ in
            syncAmbient()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image("MyColonyLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .marsHex(0x60A5FA).opacity(0.18), radius: 12, x: 0, y: 6)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MY COLONY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .allowsTightening(true)
                        .layoutPriority(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text("Reserves")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))

                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.marsHex(0xF59E0B))
                    Text(model.formatted(model.credits))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private func syncAmbient() {
        feedback.updateAmbient(
            currentTab: model.currentTab,
            sessionProgress: min(1, model.sessionDuration / 600),
            harborLevel: model.districtLevel(id: "harbor"),
            reactorLevel: model.districtLevel(id: "reactor"),
            isSceneFocused: scenePhase == .active
        )
    }

    private func applyShowcaseIfNeeded() {
        switch showcaseMode {
        case .none:
            return

        case .tab(let profile):
            model.applyShowcase(profile: profile)

        case .video:
            showcaseTask?.cancel()
            model.applyShowcase(profile: .base)
            showcaseTask = Task {
                let sequence: [ShowcaseProfile] = [.base, .colony, .tech, .fleet, .logs, .base]
                for profile in sequence.dropFirst() {
                    try? await Task.sleep(nanoseconds: 3_200_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.spring(response: 0.48, dampingFraction: 0.9)) {
                            model.applyShowcase(profile: profile)
                        }
                    }
                }
            }

        case .fastVideo:
            showcaseTask?.cancel()
            model.applyShowcase(profile: .base)
            showcaseTask = Task {
                let sequence: [ShowcaseProfile] = [.base, .colony, .tech, .fleet, .logs, .base]
                for profile in sequence.dropFirst() {
                    try? await Task.sleep(nanoseconds: 1_700_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                            model.applyShowcase(profile: profile)
                        }
                    }
                }
            }
        }
    }
}

struct BaseOverviewScreen: View {
    @ObservedObject var model: MarsColonyModel
    @ObservedObject var feedback: FeedbackController
    @State private var dismissedEventID: UUID?
    private let showcaseMode = LaunchShowcaseMode.current

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ResourceHeroCard(model: model)
                        .padding(.horizontal, 18)

                    ReactorCoreView(
                        pulse: model.reactorPulse,
                        lastTapAt: model.lastCoreTapAt,
                        tapGainText: model.formatted(model.tapPower),
                        chargeFraction: model.chargeFraction(),
                        autopilotActive: model.autopilotTimeRemaining > 0,
                        activeHazard: model.activeHazard?.type
                    ) {
                        if model.mineCore() {
                            feedback.play(.tapSuccess)
                        } else {
                            feedback.play(.tapDenied)
                        }
                    }
                    .padding(.horizontal, 18)

                    QuickStatsBar(items: [
                        ("TAPS", "\(model.totalTaps)"),
                        ("CHARGE", "\(Int(model.charge))/\(Int(model.maxCharge))"),
                        ("AUTO", model.autopilotTimeRemaining > 0 ? "\(Int(model.autopilotTimeRemaining))s" : "OFF"),
                        ("HAZARDS", "\(model.hazardsCleared)")
                    ])
                    .padding(.horizontal, 18)

                    ColonyStatusDeck(model: model)
                        .padding(.horizontal, 18)

                    if !isShowcaseCapture {
                        ComboMomentumCard(model: model)
                            .padding(.horizontal, 18)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            model.currentTab = .colony
                        }
                    } label: {
                        ColonyPanoramaCard(model: model)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)

                    if let hazard = model.activeHazard {
                        HazardAlertCard(
                            hazard: hazard,
                            rewardText: model.formatted(hazard.reward),
                            passivePenaltyText: "\(Int((1 - model.passiveEfficiency()) * 100))%",
                            tapPenaltyText: "\(Int((1 - model.tapEfficiency()) * 100))%",
                            action: {
                                switch model.respondToHazard() {
                                case .denied:
                                    feedback.play(.tapDenied)
                                case .progress:
                                    feedback.play(.hazardProgress)
                                case .resolved:
                                    feedback.play(.hazardResolved)
                                }
                            }
                        )
                        .padding(.horizontal, 18)
                    }

                    AutopilotContractsCard(
                        offers: model.autopilotOffers(),
                        formatter: model.formatted(_:),
                        canAfford: { model.isAffordable($0.cost) },
                        action: { offer in
                            if model.purchaseAutopilot(offer) {
                                feedback.play(.autopilotPurchased)
                            } else {
                                feedback.play(.tapDenied)
                            }
                        }
                    )
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitleView(
                            title: "Main Base",
                            subtitle: "Upgrade surface infrastructure to grow tap yield, reactor charge and purchasable autopilot windows."
                        )

                        ForEach(model.facilities) { facility in
                            FacilityCard(
                                facility: facility,
                                level: model.facilityLevel(for: facility),
                                costText: model.formatted(model.facilityCost(for: facility)),
                                gainText: model.facilityBenefitText(for: facility),
                                enabled: model.isAffordable(model.facilityCost(for: facility))
                            ) {
                                if model.upgradeFacility(facility) {
                                    feedback.play(.purchaseSuccess)
                                } else {
                                    feedback.play(.tapDenied)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    CommandFeedCard(model: model)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
            }

            if let event = presentedEvent {
                ZStack(alignment: .top) {
                    Color.black.opacity(0.22)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.24)) {
                                dismissedEventID = event.id
                            }
                        }

                    TimedEventCard(
                        event: event,
                        onSafe: {
                            dismissedEventID = nil
                            switch model.resolveEvent(safeChoice: true) {
                            case .safe:
                                feedback.play(.eventSafe)
                            case .riskySuccess:
                                feedback.play(.eventRiskySuccess)
                            case .riskyFail:
                                feedback.play(.eventRiskyFail)
                            case .denied:
                                feedback.play(.tapDenied)
                            }
                        },
                        onRisky: {
                            dismissedEventID = nil
                            switch model.resolveEvent(safeChoice: false) {
                            case .safe:
                                feedback.play(.eventSafe)
                            case .riskySuccess:
                                feedback.play(.eventRiskySuccess)
                            case .riskyFail:
                                feedback.play(.eventRiskyFail)
                            case .denied:
                                feedback.play(.tapDenied)
                            }
                        }
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .shadow(color: .black.opacity(0.28), radius: 26, x: 0, y: 18)
                    .transition(.asymmetric(
                        insertion: .offset(y: -18).combined(with: .opacity),
                        removal: .scale(scale: 0.985).combined(with: .opacity)
                    ))
                }
                .zIndex(10)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: presentedEvent?.id)
        .onChange(of: model.activeEvent?.id) { newValue in
            guard newValue != dismissedEventID else { return }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                dismissedEventID = nil
            }
        }
    }

    private var presentedEvent: TimedCommandEvent? {
        guard let event = model.activeEvent else { return nil }
        return dismissedEventID == event.id ? nil : event
    }

    private var isShowcaseCapture: Bool {
        showcaseMode != .none
    }
}

struct TechTreeScreen: View {
    @ObservedObject var model: MarsColonyModel
    @ObservedObject var feedback: FeedbackController

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(TechCategory.allCases) { category in
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitleView(
                            title: category.title,
                            subtitle: category.subtitle
                        )

                        ForEach(model.categoryItems(for: category)) { tech in
                            let level = model.techLevel(for: tech)
                            TechCard(
                                tech: tech,
                                level: level,
                                costText: model.formatted(model.techCost(for: tech)),
                                gainText: model.techBenefitText(for: tech),
                                enabled: model.isAffordable(model.techCost(for: tech))
                            ) {
                                if model.purchaseTech(tech) {
                                    feedback.play(.purchaseSuccess)
                                } else {
                                    feedback.play(.tapDenied)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }
}

struct ColonyOperationsScreen: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ColonyPanoramaCard(model: model, detailed: true)

                QuickStatsBar(items: [
                    ("STABILITY", "\(Int(model.colonyStability() * 100))%"),
                    ("POTENTIAL", "\(model.formatted(model.basePassiveRate))/s"),
                    ("TAP", "+\(model.formatted(model.tapPower))"),
                    ("FLEET", "\(model.totalShips())")
                ])

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitleView(
                        title: "Districts",
                        subtitle: "See exactly how each colony structure is shaping charge, contracts and manual extraction."
                    )

                    ForEach(model.facilities) { facility in
                        ColonyEffectCard(
                            title: facility.title,
                            subtitle: facility.subtitle,
                            icon: facility.icon,
                            tint: .marsHex(facility.tintHex),
                            levelText: "LVL \(model.facilityLevel(for: facility))",
                            primary: model.facilityBenefitText(for: facility),
                            secondary: model.facilityCurrentImpactText(for: facility)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitleView(
                        title: "Research VFX",
                        subtitle: "Every tech branch now has a visible footprint in the colony scene and a readable gameplay effect."
                    )

                    ForEach(model.techTree) { tech in
                        ColonyEffectCard(
                            title: tech.title,
                            subtitle: tech.subtitle,
                            icon: tech.icon,
                            tint: .marsHex(tech.tintHex),
                            levelText: "LVL \(model.techLevel(for: tech))",
                            primary: model.techBenefitText(for: tech),
                            secondary: model.techCurrentImpactText(for: tech)
                        )
                    }
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 18)
        }
    }
}

struct FleetMarketScreen: View {
    @ObservedObject var model: MarsColonyModel
    @ObservedObject var feedback: FeedbackController

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                QuickStatsBar(items: [
                    ("TOTAL SHIPS", "\(model.totalShips())"),
                    ("CONTRACT EPS", "\(model.formatted(model.fleetOutput()))/s"),
                    ("SHIP TYPES", "\(model.unlockedShipTypes()) / \(model.ships.count)")
                ])

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitleView(
                        title: "Shipyard",
                        subtitle: "Deploy specialized ships to strengthen autopilot contracts, event odds and hazard response."
                    )

                    ForEach(model.ships) { ship in
                        let count = model.shipCount(for: ship)
                        ShipCard(
                            ship: ship,
                            count: count,
                            costText: model.formatted(model.shipCost(for: ship)),
                            outputText: "\(model.formatted(ship.output))/s",
                            totalText: model.shipBenefitText(for: ship),
                            enabled: model.isAffordable(model.shipCost(for: ship))
                        ) {
                            if model.purchaseShip(ship) {
                                feedback.play(.purchaseSuccess)
                            } else {
                                feedback.play(.tapDenied)
                            }
                        }
                    }
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 18)
        }
    }
}

struct MissionLogsScreen: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                StatListCard(title: "Energy Core", rows: [
                    ("Total Credits Earned", "¤ \(model.formatted(model.totalCredits))"),
                    ("Current Reserves", "¤ \(model.formatted(model.credits))"),
                    ("Autopilot Output", "\(model.formatted(model.passiveRate))/s"),
                    ("Manual Tap Power", "+\(model.formatted(model.tapPower))"),
                    ("Total Reactor Taps", "\(model.totalTaps)")
                ])

                StatListCard(title: "Mission Time", rows: [
                    ("Session Duration", model.durationText()),
                    ("Taps per Minute", "\(model.formatted(model.tapsPerMinute()))"),
                    ("Facility Levels", "\(model.totalFacilityLevels())"),
                    ("Research Levels", "\(model.totalTechLevels())"),
                    ("Events Resolved", "\(model.eventsResolved)"),
                    ("Hazards Cleared", "\(model.hazardsCleared)")
                ])

                StatListCard(title: "Colony Stability", rows: [
                    ("Charge", "\(Int(model.charge))/\(Int(model.maxCharge))"),
                    ("Charge Regen", "\(model.formatted(model.chargeRegenRate))/s"),
                    ("Autopilot Potential", "\(model.formatted(model.basePassiveRate))/s"),
                    ("Live Autopilot", "\(model.formatted(model.passiveRate))/s"),
                    ("Base Tap Power", "+\(model.formatted(model.baseTapPower))"),
                    ("Live Tap Power", "+\(model.formatted(model.tapPower))"),
                    ("Stability", "\(Int(model.colonyStability() * 100))%"),
                    ("Alert Level", model.alertLevelLabel())
                ])

                StatListCard(title: "Fleet Manifest", rows: model.ships.map { ship in
                    let count = model.shipCount(for: ship)
                    let totalOutput = Double(count) * ship.output
                    return (ship.title, count == 0 ? "0" : "x\(count)  (\(model.formatted(totalOutput))/s contract)")
                })

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ACHIEVEMENTS")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))

                        ForEach(model.achievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                unlocked: model.achievementUnlocked(achievement)
                            )
                        }
                    }
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 18)
        }
    }
}
