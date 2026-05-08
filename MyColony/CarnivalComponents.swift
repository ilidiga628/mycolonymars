import SwiftUI

extension Color {
    static func marsHex(_ value: Int) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

struct ColonyBackground: View {
    let activeHazard: ColonyHazardType?
    let intensity: Double

    var body: some View {
        TimelineView(.animation) { context in
            background(for: context.date.timeIntervalSinceReferenceDate)
        }
    }

    private func background(for time: TimeInterval) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    .marsHex(0x06152C),
                    .marsHex(0x0B2147),
                    .marsHex(0x091A37),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [.marsHex(0x1E3A8A).opacity(0.45), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            Canvas { context, size in
                drawStars(context: context, size: size, time: time)
                drawOrbits(context: context, size: size, time: time)
                drawHazardOverlay(context: context, size: size, time: time)
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .marsHex(0xF97316).opacity(0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280)
            }
            .ignoresSafeArea()
        }
    }

    private func drawStars(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<52 {
            let baseX = CGFloat((index * 47) % max(Int(size.width), 1))
            let yDrift = CGFloat((time * Double(6 + index % 5)).truncatingRemainder(dividingBy: Double(size.height + 120)))
            let y = (CGFloat(index * 91) + yDrift).truncatingRemainder(dividingBy: size.height + 120) - 60
            let radius: CGFloat = index.isMultiple(of: 5) ? 3.2 : 1.8
            let color: Color = index.isMultiple(of: 7) ? .marsHex(0xF97316).opacity(0.55) : .white.opacity(0.72)
            context.fill(Path(ellipseIn: CGRect(x: baseX, y: y, width: radius, height: radius)), with: .color(color))
        }
    }

    private func drawOrbits(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.5)
        for index in 0..<3 {
            let orbit = CGRect(
                x: center.x - CGFloat(150 + index * 70),
                y: center.y - CGFloat(170 + index * 85),
                width: CGFloat(300 + index * 140),
                height: CGFloat(340 + index * 170)
            )
            context.stroke(
                Path(ellipseIn: orbit),
                with: .color(.white.opacity(0.08)),
                lineWidth: 1
            )
        }

        let angle = time * 0.2
        let planet = CGPoint(
            x: center.x + cos(angle) * 126,
            y: center.y + sin(angle) * 92
        )
        context.fill(
            Path(ellipseIn: CGRect(x: planet.x, y: planet.y, width: 8, height: 8)),
            with: .color(.marsHex(0xF97316))
        )
    }

    private func drawHazardOverlay(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        guard let activeHazard else { return }

        switch activeHazard {
        case .dustStorm:
            for index in 0..<24 {
                let offset = CGFloat((index * 53) % 120)
                let y = CGFloat((time * 55 + Double(index * 32)).truncatingRemainder(dividingBy: Double(size.height + 120))) - 60
                var path = Path()
                path.move(to: CGPoint(x: -40 + offset, y: y))
                path.addLine(to: CGPoint(x: size.width + 60, y: y + 52))
                context.stroke(path, with: .color(Color.marsHex(0xF59E0B).opacity(0.08 + intensity * 0.12)), lineWidth: 5)
            }

        case .coolantLeak:
            for index in 0..<14 {
                let x = CGFloat((index * 31) % max(Int(size.width), 1))
                let dropY = CGFloat((time * Double(80 + index * 3)).truncatingRemainder(dividingBy: Double(size.height + 160))) - 80
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: dropY, width: 5, height: 22)),
                    with: .color(Color.marsHex(0x60A5FA).opacity(0.08 + intensity * 0.1))
                )
            }

        case .solarFlare:
            let flare = Gradient(colors: [
                Color.marsHex(0xF97316).opacity(0.14 + intensity * 0.1),
                Color.marsHex(0xF59E0B).opacity(0.08 + intensity * 0.08),
                .clear
            ])
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    flare,
                    center: CGPoint(x: size.width * 0.85, y: size.height * 0.12),
                    startRadius: 10,
                    endRadius: 280
                )
            )

            for index in 0..<10 {
                let x = size.width * 0.52 + CGFloat(index) * 18
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x - 80, y: size.height * 0.72))
                context.stroke(path, with: .color(Color.marsHex(0xFED7AA).opacity(0.08 + intensity * 0.08)), lineWidth: 2.5)
            }
        }
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: 16)
    }
}

struct ResourceHeroCard: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        GlassPanel {
            ViewThatFits(in: .horizontal) {
                heroMetricsHorizontal
                heroMetricsVertical
            }
        }
    }

    private var heroMetricsHorizontal: some View {
        HStack(alignment: .top, spacing: 16) {
            heroCreditBlock(alignment: .leading)
            Spacer(minLength: 12)
            heroChargeBlock(alignment: .trailing)
        }
    }

    private var heroMetricsVertical: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroCreditBlock(alignment: .leading)
            heroChargeBlock(alignment: .leading)
        }
    }

    private func heroCreditBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 10) {
            Text("RESERVES")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))

            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(Color.marsHex(0xF59E0B))
                Text(model.formatted(model.credits))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            if model.activeHazard != nil {
                Text("Hazard drag: -\(model.formatted(max(0, model.basePassiveRate - model.passiveRate)))/s")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.marsHex(0xFED7AA))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private func heroChargeBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 10) {
            Text("CHARGE")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))

            Text("\(Int(model.charge))/\(Int(model.maxCharge))")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text("+\(model.formatted(model.tapPower)) per tap  •  +\(model.formatted(model.chargeRegenRate))/s")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.marsHex(0xF97316))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

struct ColonyStatusDeck: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("COLONY STATUS")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Live command telemetry for the Martian grid")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    AlertChip(label: model.alertLevelLabel(), tint: model.activeHazard == nil ? .marsHex(0x1D4ED8) : .marsHex(0xF97316))
                }

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    StatusMeterCard(
                        title: "Stability",
                        valueText: "\(Int(model.colonyStability() * 100))%",
                        caption: model.activeHazard == nil ? "Systems aligned" : "Pressure under control",
                        progress: model.colonyStability(),
                        tint: .marsHex(0x60A5FA)
                    )

                    StatusMeterCard(
                        title: "Charge",
                        valueText: "\(Int(model.chargeFraction() * 100))%",
                        caption: "\(model.formatted(model.chargeRegenRate))/s regen",
                        progress: model.chargeFraction(),
                        tint: .marsHex(0xF59E0B)
                    )

                    StatusMeterCard(
                        title: "Autopilot",
                        valueText: model.autopilotTimeRemaining > 0 ? "\(Int(model.autopilotTimeRemaining))s" : "OFF",
                        caption: model.autopilotTimeRemaining > 0 ? "\(model.formatted(model.passiveRate))/s live" : "\(model.formatted(model.basePassiveRate))/s potential",
                        progress: model.autopilotTimeRemaining > 0 ? min(1, model.autopilotTimeRemaining / 36) : max(0.08, min(1, model.basePassiveRate / 40)),
                        tint: .marsHex(0xF97316)
                    )

                    StatusMeterCard(
                        title: model.sessionTierLabel(),
                        valueText: model.comboDescriptor(),
                        caption: "5-10 min pacing track",
                        progress: min(1, Double(model.sessionTier()) / 4),
                        tint: model.riskyCombo > 0 ? .marsHex(0xF97316) : .marsHex(0x60A5FA)
                    )
                }
            }
        }
    }
}

struct HazardAlertCard: View {
    let hazard: ColonyHazard
    let rewardText: String
    let passivePenaltyText: String
    let tapPenaltyText: String
    let action: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.marsHex(hazard.type.tintHex).opacity(0.18))
                            .frame(width: 64, height: 64)

                        Image(systemName: hazard.type.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.marsHex(hazard.type.tintHex))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(hazard.type.title)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(hazard.affectedSystem.uppercased())
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.marsHex(hazard.type.tintHex))
                            .tracking(1.2)

                        Text(hazard.type.detail)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    AlertChip(label: "Passive -\(passivePenaltyText)", tint: .marsHex(0xF59E0B))
                    AlertChip(label: "Tap -\(tapPenaltyText)", tint: .marsHex(0xF97316))
                    AlertChip(label: "Reward \(rewardText)", tint: .marsHex(0x1D4ED8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Containment progress")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                        Spacer()
                        Text("\(hazard.totalActions - hazard.remainingActions)/\(hazard.totalActions)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.marsHex(hazard.type.tintHex), .white.opacity(0.92)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(18, proxy.size.width * hazard.resolvedProgress))
                        }
                    }
                    .frame(height: 10)
                }

                Button(action: action) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hazard.type.actionTitle)
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                            Text("\(hazard.remainingActions) stabilizing actions left")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.marsHex(hazard.type.tintHex), Color.marsHex(0xF97316)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TimedEventCard: View {
    let event: TimedCommandEvent
    let onSafe: () -> Void
    let onRisky: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TIMED EVENT")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))
                            .tracking(1.2)

                        Text(event.type.title)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(event.type.detail)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    AlertChip(label: "\(Int(event.timeRemaining))s left", tint: .marsHex(0xA63A14))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.marsHex(0xF97316), Color.marsHex(0xFED7AA)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(20, proxy.size.width * event.progress))
                    }
                }
                .frame(height: 10)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        EventChoiceButton(
                            title: event.type.safeTitle,
                            detail: event.type.safeDetail,
                            tint: .marsHex(0x2563EB),
                            action: onSafe
                        )

                        EventChoiceButton(
                            title: event.type.riskyTitle,
                            detail: event.type.riskyDetail,
                            tint: .marsHex(0xF97316),
                            action: onRisky
                        )
                    }

                    VStack(spacing: 12) {
                        EventChoiceButton(
                            title: event.type.safeTitle,
                            detail: event.type.safeDetail,
                            tint: .marsHex(0x2563EB),
                            action: onSafe
                        )

                        EventChoiceButton(
                            title: event.type.riskyTitle,
                            detail: event.type.riskyDetail,
                            tint: .marsHex(0xF97316),
                            action: onRisky
                        )
                    }
                }
            }
        }
    }
}

struct EventChoiceButton: View {
    let title: String
    let detail: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(tint.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct AutopilotContractsCard: View {
    let offers: [AutopilotOffer]
    let formatter: (Double) -> String
    let canAfford: (AutopilotOffer) -> Bool
    let action: (AutopilotOffer) -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("AUTOPILOT CONTRACTS")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Reserve income only runs during limited autopilot contracts.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(offers) { offer in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            FeatureIcon(symbol: "clock.arrow.circlepath", tint: .marsHex(offer.kind.tintHex))

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text(offer.kind.title)
                                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                    Spacer(minLength: 8)
                                    AlertChip(label: "\(Int(offer.kind.duration))s", tint: .marsHex(offer.kind.tintHex))
                                }

                                Text(offer.kind.subtitle)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(formatter(offer.rate))/s during contract")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.marsHex(0xF97316))
                            }
                        }

                        UpgradeActionButton(
                            title: "ACTIVATE",
                            costText: formatter(offer.cost),
                            accent: .marsHex(offer.kind.tintHex),
                            enabled: canAfford(offer),
                            action: {
                                action(offer)
                            }
                        )
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

struct AlertChip: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint.opacity(0.78))
            )
    }
}

struct StatusMeterCard: View {
    let title: String
    let valueText: String
    let caption: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))

            Text(valueText)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, proxy.size.width * max(0.04, min(progress, 1))))
                }
            }
            .frame(height: 8)

            Text(caption)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct ComboMomentumCard: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("COMBO MOMENTUM")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.marsHex(model.comboTintHex()))
                            .tracking(1.2)

                        Text(model.comboMomentumTitle())
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(model.comboMomentumDetail())
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    AlertChip(label: model.comboDescriptor(), tint: .marsHex(model.comboTintHex()))
                }

                StatusMeterCard(
                    title: model.sessionTierLabel(),
                    valueText: model.comboDescriptor(),
                    caption: model.nextTierDetail(),
                    progress: max(model.comboProgress(), model.nextTierProgress()),
                    tint: .marsHex(model.comboTintHex())
                )
            }
        }
    }
}

struct ColonyPanoramaCard: View {
    @ObservedObject var model: MarsColonyModel
    var detailed: Bool = false
    @State private var inspectedZone: ColonyInspectZone = .reactor

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("COLONY VISTA")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))
                            .tracking(1.2)

                        Text(colonyTitle)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Every facility, ship and research branch now changes the live skyline around the core.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    AlertChip(label: "Ships \(model.totalShips())", tint: .marsHex(0x2563EB))
                }

                TimelineView(.animation) { context in
                    Canvas { context2D, size in
                        let time = context.date.timeIntervalSinceReferenceDate
                        let groundY = size.height * 0.78
                        let sessionProgress = min(1, model.sessionDuration / 600)
                        let cycle = colonyCycleValue(time: time, sessionProgress: sessionProgress)
                        drawSkyGlow(context: context2D, size: size, cycle: cycle)
                        drawCelestialBody(context: context2D, size: size, cycle: cycle)
                        drawTerrain(context: context2D, size: size, groundY: groundY)
                        drawSolarField(context: context2D, size: size, groundY: groundY)
                        drawColonyDomes(context: context2D, size: size, groundY: groundY)
                        drawReactorSpines(context: context2D, size: size, groundY: groundY, time: time)
                        drawHarbor(context: context2D, size: size, groundY: groundY, time: time)
                        drawTechVFX(context: context2D, size: size, groundY: groundY, time: time)
                        drawDrones(context: context2D, size: size, groundY: groundY, time: time)
                        drawCrewAndRovers(context: context2D, size: size, groundY: groundY, time: time)
                        drawFleet(context: context2D, size: size, groundY: groundY, time: time)
                        drawScenePulse(context: context2D, size: size, groundY: groundY, time: time)
                        drawSceneHazard(context: context2D, size: size, groundY: groundY, time: time)
                    }
                }
                .frame(height: detailed ? 290 : 220)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.marsHex(0x0B2147).opacity(0.9),
                                    Color.marsHex(0x111827).opacity(0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .overlay {
                    GeometryReader { proxy in
                        let groundY = proxy.size.height * 0.78
                        ZStack {
                            inspectHotspot(zone: .extractor, size: proxy.size, groundY: groundY)
                            inspectHotspot(zone: .reactor, size: proxy.size, groundY: groundY)
                            inspectHotspot(zone: .harbor, size: proxy.size, groundY: groundY)
                            inspectHotspot(zone: .fleet, size: proxy.size, groundY: groundY)
                        }
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        progressChip("Extractor", value: extractorLevel, tint: .marsHex(0xF59E0B))
                        progressChip("Reactor", value: reactorLevel, tint: .marsHex(0x2563EB))
                        progressChip("Harbor", value: harborLevel, tint: .marsHex(0xF97316))
                    }

                    VStack(spacing: 10) {
                        progressChip("Extractor", value: extractorLevel, tint: .marsHex(0xF59E0B))
                        progressChip("Reactor", value: reactorLevel, tint: .marsHex(0x2563EB))
                        progressChip("Harbor", value: harborLevel, tint: .marsHex(0xF97316))
                    }
                }

                if detailed {
                    ColonyInspectCard(zone: inspectedZone, model: model)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            progressChip("Solar", value: solarLevel, tint: .marsHex(0xF59E0B))
                            progressChip("Fusion", value: fusionLevel, tint: .marsHex(0x60A5FA))
                            progressChip("Plasma", value: conduitLevel, tint: .marsHex(0xFB923C))
                            progressChip("Quantum", value: techLevel(id: "quantum_core"), tint: .white)
                        }

                        VStack(spacing: 10) {
                            progressChip("Solar", value: solarLevel, tint: .marsHex(0xF59E0B))
                            progressChip("Fusion", value: fusionLevel, tint: .marsHex(0x60A5FA))
                            progressChip("Plasma", value: conduitLevel, tint: .marsHex(0xFB923C))
                            progressChip("Quantum", value: techLevel(id: "quantum_core"), tint: .white)
                        }
                    }
                }
            }
        }
    }

    private var extractorLevel: Int { facilityLevel(id: "extractor") }
    private var reactorLevel: Int { facilityLevel(id: "reactor") }
    private var harborLevel: Int { facilityLevel(id: "harbor") }
    private var solarLevel: Int { techLevel(id: "solar_array") }
    private var fusionLevel: Int { techLevel(id: "fusion_cell") }
    private var conduitLevel: Int { techLevel(id: "plasma_conduit") }
    private var quantumLevel: Int { techLevel(id: "quantum_core") }
    private var handDrillLevel: Int { techLevel(id: "hand_drill") }
    private var servoLevel: Int { techLevel(id: "servo_glove") }
    private var pneumoLevel: Int { techLevel(id: "pneumo_drill") }
    private var scoutPods: Int { model.shipCount(with: "scout_pod") }
    private var miningDrones: Int { model.shipCount(with: "mining_drone") }
    private var oreHaulers: Int { model.shipCount(with: "ore_hauler") }
    private var cruisers: Int { model.shipCount(with: "battle_cruiser") }
    private var dreadnoughts: Int { model.shipCount(with: "dreadnought") }

    private var colonyTitle: String {
        if dreadnoughts > 0 { return "Flagship Citadel" }
        if harborLevel >= 3 { return "Orbital Trade Spine" }
        if reactorLevel >= 3 { return "Reactor District Rising" }
        if extractorLevel >= 2 { return "Surface Colony Expanding" }
        return "Landing Zone Alpha"
    }

    private func facilityLevel(id: String) -> Int {
        guard let facility = model.facilities.first(where: { $0.id == id }) else { return 0 }
        return model.facilityLevel(for: facility)
    }

    private func techLevel(id: String) -> Int {
        guard let tech = model.techTree.first(where: { $0.id == id }) else { return 0 }
        return model.techLevel(for: tech)
    }

    private func stagedBuildProgress(for keys: Set<String>, time: TimeInterval) -> Double {
        let elapsed = time - model.colonySceneEventDate.timeIntervalSinceReferenceDate
        guard elapsed >= 0, elapsed < 2.8, keys.contains(model.colonySceneFocus) else { return 1 }
        return max(0.16, min(1, elapsed / 2.2))
    }

    private func progressChip(_ title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
            Text("LVL \(value)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func inspectHotspot(zone: ColonyInspectZone, size: CGSize, groundY: CGFloat) -> some View {
        let frame = zone.frame(in: size, groundY: groundY)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                inspectedZone = zone
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(zone == inspectedZone ? zone.tint.opacity(0.18) : .clear)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(zone == inspectedZone ? zone.tint.opacity(0.44) : .white.opacity(0.08), style: StrokeStyle(lineWidth: 1.2, dash: [6, 5]))
                VStack(spacing: 4) {
                    Image(systemName: zone.icon)
                        .font(.system(size: 14, weight: .bold))
                    if zone == inspectedZone || detailed {
                        Text(zone.shortLabel)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.white)
                .padding(6)
            }
        }
        .buttonStyle(.plain)
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    private func colonyCycleValue(time: TimeInterval, sessionProgress: Double) -> Double {
        let movingCycle = (sin(time * 0.05 + sessionProgress * 4) + 1) * 0.5
        let lateSessionBias = max(0, sessionProgress - 0.35) * 0.55
        return max(0, min(1, movingCycle * 0.7 + lateSessionBias))
    }

    private func drawSkyGlow(context: GraphicsContext, size: CGSize, cycle: Double) {
        let warmOpacity = 0.08 + (1 - cycle) * 0.12
        let nightOpacity = 0.05 + cycle * 0.18
        context.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.55, y: 8, width: size.width * 0.38, height: 62)),
            with: .color(Color.marsHex(0x60A5FA).opacity(nightOpacity))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: size.width * 0.08, y: 24, width: size.width * 0.28, height: 48)),
            with: .color(Color.marsHex(0xF97316).opacity(warmOpacity))
        )
    }

    private func drawCelestialBody(context: GraphicsContext, size: CGSize, cycle: Double) {
        let isNightDominant = cycle > 0.56
        let bodyRect = CGRect(
            x: isNightDominant ? size.width * 0.75 : size.width * 0.1,
            y: 18,
            width: isNightDominant ? 26 : 34,
            height: isNightDominant ? 26 : 34
        )
        context.fill(
            Path(ellipseIn: bodyRect),
            with: .color(
                isNightDominant
                    ? Color.white.opacity(0.9)
                    : Color.marsHex(0xFED7AA).opacity(0.95)
            )
        )
    }

    private func drawTerrain(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        var terrain = Path()
        terrain.move(to: CGPoint(x: 0, y: groundY))
        terrain.addQuadCurve(
            to: CGPoint(x: size.width, y: groundY - 6),
            control: CGPoint(x: size.width * 0.5, y: groundY - 38)
        )
        terrain.addLine(to: CGPoint(x: size.width, y: size.height))
        terrain.addLine(to: CGPoint(x: 0, y: size.height))
        terrain.closeSubpath()

        context.fill(
            terrain,
            with: .linearGradient(
                Gradient(colors: [Color.marsHex(0x7C2D12), Color.black.opacity(0.95)]),
                startPoint: CGPoint(x: size.width * 0.5, y: groundY - 30),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height)
            )
        )
    }

    private func drawSolarField(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let panelCount = max(2, min(8, solarLevel + extractorLevel))
        let build = stagedBuildProgress(for: ["extractor", "solar_array", "hand_drill"], time: Date().timeIntervalSinceReferenceDate)
        for index in 0..<panelCount {
            let width: CGFloat = 22
            let height: CGFloat = 10
            let x = 18 + CGFloat(index) * 26
            let y = groundY - (22 + CGFloat(index % 2) * 5) * build
            let rect = CGRect(x: x, y: y, width: width, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color.marsHex(0x1D4ED8).opacity(0.28 + 0.6 * build)))
            context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.white.opacity(0.22)), lineWidth: 1)
        }
        drawScaffold(context: context, rect: CGRect(x: 18, y: groundY - 44, width: CGFloat(panelCount) * 26, height: 34), tint: .marsHex(0xF59E0B), progress: build)
    }

    private func drawColonyDomes(context: GraphicsContext, size: CGSize, groundY: CGFloat) {
        let domeCount = max(2, min(7, extractorLevel + solarLevel / 2 + 2))
        let build = stagedBuildProgress(for: ["extractor", "solar_array", "hand_drill"], time: Date().timeIntervalSinceReferenceDate)
        for index in 0..<domeCount {
            let diameter = CGFloat(30 + (index % 3) * 10)
            let x = 52 + CGFloat(index) * 38
            let scaledDiameter = diameter * build
            let rect = CGRect(x: x, y: groundY - scaledDiameter, width: scaledDiameter, height: scaledDiameter)
            context.fill(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.34), Color.marsHex(0x60A5FA).opacity(0.1)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)), lineWidth: 1)
        }
    }

    private func drawReactorSpines(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let spineCount = max(1, min(5, reactorLevel + fusionLevel / 2 + 1))
        let build = stagedBuildProgress(for: ["reactor", "fusion_cell", "plasma_conduit", "quantum_core", "servo_glove", "pneumo_drill"], time: time)
        for index in 0..<spineCount {
            let height = CGFloat(46 + index * 14) * build
            let width: CGFloat = 20
            let x = size.width * 0.42 + CGFloat(index) * 28
            let rect = CGRect(x: x, y: groundY - height, width: width, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(Color.marsHex(0x1E3A8A).opacity(0.88)))
            context.fill(
                Path(CGRect(x: x + 6, y: groundY - height + 8, width: 8, height: height - 20)),
                with: .color(Color.marsHex(0x60A5FA).opacity(0.7 + 0.15 * sin(time + Double(index))))
            )
            context.stroke(Path(roundedRect: rect, cornerRadius: 8), with: .color(.white.opacity(0.14)), lineWidth: 1)
        }
        drawCrane(context: context, base: CGPoint(x: size.width * 0.36, y: groundY), mastHeight: 86 * build, boomLength: 58, tint: .marsHex(0x60A5FA))
    }

    private func drawHarbor(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard harborLevel > 0 || oreHaulers > 0 || scoutPods > 0 else { return }

        let build = stagedBuildProgress(for: ["harbor", "scout_window", "convoy_window", "capital_window", "scout_pod", "ore_hauler"], time: time)
        let baseX = size.width * 0.78
        let dockRect = CGRect(x: baseX, y: groundY - 72 * build, width: 54, height: 72 * build)
        context.fill(Path(roundedRect: dockRect, cornerRadius: 12), with: .color(Color.marsHex(0x111827).opacity(0.92)))
        context.stroke(Path(roundedRect: dockRect, cornerRadius: 12), with: .color(.white.opacity(0.14)), lineWidth: 1)

        let ringRect = CGRect(x: baseX - 26, y: groundY - (104 * build), width: 110, height: 48 * build)
        context.stroke(Path(ellipseIn: ringRect), with: .color(Color.marsHex(0xF97316).opacity(0.42)), lineWidth: 3)

        if conduitLevel > 0 {
            let pulseWidth = 36 + CGFloat(8 * sin(time * 1.6))
            context.fill(
                Path(ellipseIn: CGRect(x: baseX + 10, y: groundY - 90, width: pulseWidth, height: 18)),
                with: .color(Color.marsHex(0xFB923C).opacity(0.14))
            )
        }
        drawCrane(context: context, base: CGPoint(x: baseX - 14, y: groundY), mastHeight: 76 * build, boomLength: 42, tint: .marsHex(0xF97316))
    }

    private func drawDrones(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let count = max(1, min(6, miningDrones))
        for index in 0..<count {
            let x = size.width * 0.24 + CGFloat(index) * 34
            let y = groundY - 76 - CGFloat(index % 2) * 14 + CGFloat(sin(time * 1.8 + Double(index)) * 9)
            let droneRect = CGRect(x: x, y: y, width: 12, height: 12)
            context.fill(Path(ellipseIn: droneRect), with: .color(Color.marsHex(0xF59E0B).opacity(0.9)))

            var beam = Path()
            beam.move(to: CGPoint(x: x + 6, y: y + 12))
            beam.addLine(to: CGPoint(x: x + 2, y: groundY - 4))
            beam.addLine(to: CGPoint(x: x + 10, y: groundY - 4))
            beam.closeSubpath()
            context.fill(beam, with: .color(Color.marsHex(0xF59E0B).opacity(0.12)))
        }
    }

    private func drawCrewAndRovers(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let crewCount = max(2, min(7, extractorLevel + handDrillLevel / 2 + harborLevel))
        for index in 0..<crewCount {
            let patrol = CGFloat((sin(time * (0.7 + Double(index) * 0.08)) + 1) * 0.5)
            let x = 26 + CGFloat(index) * (size.width - 60) / CGFloat(max(crewCount, 1)) + patrol * 14
            let y = groundY - 10 - CGFloat(index % 2) * 3
            context.fill(Path(ellipseIn: CGRect(x: x, y: y - 8, width: 5, height: 5)), with: .color(.white.opacity(0.8)))
            context.stroke(Path(CGRect(x: x + 2, y: y - 2, width: 1, height: 8)), with: .color(.white.opacity(0.72)), lineWidth: 1)
        }

        let roverCount = max(1, min(4, servoLevel / 2 + pneumoLevel / 2 + harborLevel / 2 + 1))
        for index in 0..<roverCount {
            let roll = CGFloat((cos(time * (0.5 + Double(index) * 0.07)) + 1) * 0.5)
            let x = 40 + CGFloat(index) * 70 + roll * 24
            let y = groundY - 16 - CGFloat(index % 2) * 5
            let body = CGRect(x: x, y: y, width: 16, height: 8)
            context.fill(Path(roundedRect: body, cornerRadius: 3), with: .color(Color.marsHex(0x9CA3AF).opacity(0.9)))
            context.fill(Path(ellipseIn: CGRect(x: x + 2, y: y + 7, width: 4, height: 4)), with: .color(.black.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: x + 10, y: y + 7, width: 4, height: 4)), with: .color(.black.opacity(0.85)))
            if servoLevel > 0 {
                context.fill(Path(ellipseIn: CGRect(x: x + 14, y: y + 1, width: 10, height: 4)), with: .color(Color.marsHex(0x60A5FA).opacity(0.18)))
            }
        }
    }

    private func drawScaffold(context: GraphicsContext, rect: CGRect, tint: Color, progress: Double) {
        guard progress < 0.98 else { return }
        var scaffold = Path()
        scaffold.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 6))
        for step in 1..<4 {
            let y = rect.minY + CGFloat(step) * rect.height / 4
            scaffold.move(to: CGPoint(x: rect.minX, y: y))
            scaffold.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        for step in 1..<6 {
            let x = rect.minX + CGFloat(step) * rect.width / 6
            scaffold.move(to: CGPoint(x: x, y: rect.minY))
            scaffold.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        context.stroke(scaffold, with: .color(tint.opacity(0.24)), lineWidth: 1)
    }

    private func drawCrane(context: GraphicsContext, base: CGPoint, mastHeight: CGFloat, boomLength: CGFloat, tint: Color) {
        guard mastHeight > 18 else { return }
        var crane = Path()
        crane.move(to: base)
        crane.addLine(to: CGPoint(x: base.x, y: base.y - mastHeight))
        crane.addLine(to: CGPoint(x: base.x + boomLength, y: base.y - mastHeight))
        crane.move(to: CGPoint(x: base.x + boomLength - 8, y: base.y - mastHeight))
        crane.addLine(to: CGPoint(x: base.x + boomLength - 8, y: base.y - mastHeight + 24))
        context.stroke(crane, with: .color(tint.opacity(0.28)), lineWidth: 2)
    }

    private func drawFleet(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        drawScoutPods(context: context, size: size, groundY: groundY, time: time)
        drawHaulers(context: context, size: size, groundY: groundY, time: time)
        drawCruisers(context: context, size: size, groundY: groundY, time: time)
        drawDreadnought(context: context, size: size, groundY: groundY, time: time)
    }

    private func drawScoutPods(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let count = min(4, max(0, scoutPods))
        for index in 0..<count {
            let phase = time * 0.3 + Double(index) * 0.8
            let x = CGFloat(phase.truncatingRemainder(dividingBy: Double(size.width + 60))) - 30
            let y = groundY - 136 - CGFloat(index * 10) + CGFloat(sin(phase * 2.2) * 6)
            drawScoutGlyph(context: context, origin: CGPoint(x: x, y: y), scale: 0.95)
        }
    }

    private func drawHaulers(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let count = min(2, max(0, oreHaulers))
        for index in 0..<count {
            let phase = time * 0.18 + Double(index) * 1.3
            let x = CGFloat(phase.truncatingRemainder(dividingBy: Double(size.width + 110))) - 60
            let y = groundY - 108 - CGFloat(index * 14) + CGFloat(cos(phase * 1.7) * 5)
            drawHaulerGlyph(context: context, origin: CGPoint(x: x, y: y), scale: 1.15)
        }
    }

    private func drawCruisers(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard cruisers > 0 else { return }
        let x = size.width * 0.56 + CGFloat(cos(time * 0.36) * 22)
        let y = groundY - 156 + CGFloat(sin(time * 0.72) * 5)
        drawCruiserGlyph(context: context, origin: CGPoint(x: x, y: y), scale: 1.3)
    }

    private func drawDreadnought(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard dreadnoughts > 0 else { return }
        let x = size.width * 0.18 + CGFloat(cos(time * 0.22) * 14)
        let y = groundY - 178 + CGFloat(sin(time * 0.45) * 4)
        drawDreadnoughtGlyph(context: context, origin: CGPoint(x: x, y: y), scale: 1.55)
    }

    private func drawScoutGlyph(context: GraphicsContext, origin: CGPoint, scale: CGFloat) {
        var hull = Path()
        hull.move(to: CGPoint(x: origin.x, y: origin.y + 4 * scale))
        hull.addLine(to: CGPoint(x: origin.x + 22 * scale, y: origin.y))
        hull.addLine(to: CGPoint(x: origin.x + 7 * scale, y: origin.y + 10 * scale))
        hull.closeSubpath()
        context.fill(hull, with: .color(Color.marsHex(0x60A5FA).opacity(0.94)))
        drawEngineTrail(context: context, origin: origin, scale: scale)
    }

    private func drawHaulerGlyph(context: GraphicsContext, origin: CGPoint, scale: CGFloat) {
        let body = CGRect(x: origin.x, y: origin.y, width: 28 * scale, height: 12 * scale)
        context.fill(Path(roundedRect: body, cornerRadius: 4 * scale), with: .color(Color.marsHex(0xF97316).opacity(0.92)))
        context.fill(Path(CGRect(x: origin.x + 8 * scale, y: origin.y - 4 * scale, width: 10 * scale, height: 4 * scale)), with: .color(.white.opacity(0.72)))
        drawEngineTrail(context: context, origin: origin, scale: scale)
    }

    private func drawCruiserGlyph(context: GraphicsContext, origin: CGPoint, scale: CGFloat) {
        var hull = Path()
        hull.move(to: CGPoint(x: origin.x, y: origin.y + 6 * scale))
        hull.addLine(to: CGPoint(x: origin.x + 30 * scale, y: origin.y))
        hull.addLine(to: CGPoint(x: origin.x + 38 * scale, y: origin.y + 6 * scale))
        hull.addLine(to: CGPoint(x: origin.x + 24 * scale, y: origin.y + 12 * scale))
        hull.closeSubpath()
        context.fill(hull, with: .color(.white.opacity(0.92)))
        context.stroke(hull, with: .color(Color.marsHex(0x60A5FA).opacity(0.5)), lineWidth: 1)
        drawEngineTrail(context: context, origin: origin, scale: scale)
    }

    private func drawDreadnoughtGlyph(context: GraphicsContext, origin: CGPoint, scale: CGFloat) {
        let body = CGRect(x: origin.x, y: origin.y, width: 42 * scale, height: 14 * scale)
        context.fill(Path(roundedRect: body, cornerRadius: 6 * scale), with: .color(Color.marsHex(0xDBEAFE).opacity(0.96)))
        context.fill(Path(CGRect(x: origin.x + 10 * scale, y: origin.y - 6 * scale, width: 18 * scale, height: 6 * scale)), with: .color(Color.marsHex(0x2563EB).opacity(0.82)))
        context.stroke(Path(roundedRect: body, cornerRadius: 6 * scale), with: .color(.white.opacity(0.3)), lineWidth: 1)
        drawEngineTrail(context: context, origin: origin, scale: scale * 1.15)
    }

    private func drawEngineTrail(context: GraphicsContext, origin: CGPoint, scale: CGFloat) {
        var trail = Path()
        trail.move(to: CGPoint(x: origin.x - 10 * scale, y: origin.y + 6 * scale))
        trail.addLine(to: CGPoint(x: origin.x, y: origin.y + 3 * scale))
        trail.addLine(to: CGPoint(x: origin.x, y: origin.y + 9 * scale))
        trail.closeSubpath()
        context.fill(trail, with: .color(Color.marsHex(0xFED7AA).opacity(0.34)))
    }

    private func drawTechVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        drawSolarArrayVFX(context: context, size: size, groundY: groundY, time: time)
        drawFusionCellVFX(context: context, size: size, groundY: groundY, time: time)
        drawPlasmaConduitVFX(context: context, size: size, groundY: groundY, time: time)
        drawQuantumCoreVFX(context: context, size: size, groundY: groundY, time: time)
        drawHandDrillVFX(context: context, size: size, groundY: groundY, time: time)
        drawServoGloveVFX(context: context, size: size, groundY: groundY, time: time)
        drawPneumoDrillVFX(context: context, size: size, groundY: groundY, time: time)
    }

    private func drawSolarArrayVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard solarLevel > 0 else { return }
        for index in 0..<min(4, solarLevel) {
            let pulse = CGFloat((sin(time * 2 + Double(index)) + 1) * 0.5)
            context.fill(
                Path(ellipseIn: CGRect(x: 28 + CGFloat(index) * 40, y: groundY - 52, width: 8 + pulse * 10, height: 4 + pulse * 5)),
                with: .color(Color.marsHex(0xFED7AA).opacity(0.16))
            )
        }
    }

    private func drawFusionCellVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard fusionLevel > 0 else { return }
        for index in 0..<min(3, fusionLevel) {
            var path = Path()
            let start = CGPoint(x: size.width * 0.48 + CGFloat(index) * 18, y: groundY - 112)
            path.move(to: start)
            path.addQuadCurve(
                to: CGPoint(x: start.x + 22, y: groundY - 76),
                control: CGPoint(x: start.x + CGFloat(sin(time * 2.2 + Double(index)) * 14), y: groundY - 132)
            )
            context.stroke(path, with: .color(Color.marsHex(0x60A5FA).opacity(0.24)), lineWidth: 2)
        }
    }

    private func drawPlasmaConduitVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard conduitLevel > 0 else { return }
        for index in 0..<2 {
            var conduit = Path()
            conduit.move(to: CGPoint(x: size.width * 0.58, y: groundY - 64 + CGFloat(index) * 8))
            conduit.addCurve(
                to: CGPoint(x: size.width * 0.8, y: groundY - 78 + CGFloat(index) * 8),
                control1: CGPoint(x: size.width * 0.64, y: groundY - 96),
                control2: CGPoint(x: size.width * 0.72, y: groundY - 56 + CGFloat(sin(time * 2) * 8))
            )
            context.stroke(conduit, with: .color(Color.marsHex(0xFB923C).opacity(0.2)), lineWidth: 3)
        }
    }

    private func drawQuantumCoreVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard quantumLevel > 0 else { return }
        let radius = 18 + CGFloat((sin(time * 1.5) + 1) * 0.5) * 10
        let rect = CGRect(x: size.width * 0.52 - radius, y: groundY - 108 - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.22)), lineWidth: 2)
    }

    private func drawHandDrillVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard handDrillLevel > 0 else { return }
        for index in 0..<min(3, handDrillLevel) {
            let x = size.width * 0.2 + CGFloat(index) * 36
            let y = groundY - 26
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y - CGFloat((sin(time * 5 + Double(index)) + 1) * 4), width: 3, height: 3)),
                with: .color(Color.marsHex(0xF97316).opacity(0.42))
            )
        }
    }

    private func drawServoGloveVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard servoLevel > 0 else { return }
        for index in 0..<min(3, servoLevel) {
            var trail = Path()
            let startX = 48 + CGFloat(index) * 92
            trail.move(to: CGPoint(x: startX, y: groundY - 18))
            trail.addLine(to: CGPoint(x: startX + 16 + CGFloat(cos(time * 2 + Double(index)) * 6), y: groundY - 24))
            context.stroke(trail, with: .color(Color.marsHex(0x60A5FA).opacity(0.18)), lineWidth: 2)
        }
    }

    private func drawPneumoDrillVFX(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard pneumoLevel > 0 else { return }
        let pulse = CGFloat((sin(time * 2.7) + 1) * 0.5)
        let width = 120 + pulse * 80
        let rect = CGRect(x: size.width * 0.22, y: groundY - 18, width: width, height: 10)
        context.stroke(Path(roundedRect: rect, cornerRadius: 5), with: .color(Color.marsHex(0xF59E0B).opacity(0.16)), lineWidth: 2)
    }

    private func drawScenePulse(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        let elapsed = time - model.colonySceneEventDate.timeIntervalSinceReferenceDate
        guard elapsed >= 0, elapsed < 2.2 else { return }

        let zone = focusZone(for: model.colonySceneFocus, size: size, groundY: groundY)
        let ringScale = 1 + elapsed * 0.9
        let opacity = max(0, 0.26 - elapsed * 0.1)
        let ringRect = CGRect(
            x: zone.x - 22 * ringScale,
            y: zone.y - 22 * ringScale,
            width: 44 * ringScale,
            height: 44 * ringScale
        )
        context.stroke(
            Path(ellipseIn: ringRect),
            with: .color(zone.tint.opacity(opacity)),
            lineWidth: 3
        )

        context.fill(
            Path(ellipseIn: CGRect(x: zone.x - 10, y: zone.y - 10, width: 20, height: 20)),
            with: .color(zone.tint.opacity(max(0.08, 0.22 - elapsed * 0.08)))
        )
    }

    private func focusZone(for focus: String, size: CGSize, groundY: CGFloat) -> (x: CGFloat, y: CGFloat, tint: Color) {
        switch focus {
        case "extractor", "solar_array", "hand_drill":
            return (size.width * 0.18, groundY - 28, .marsHex(0xF59E0B))
        case "reactor", "fusion_cell", "plasma_conduit", "quantum_core", "servo_glove", "pneumo_drill":
            return (size.width * 0.54, groundY - 66, .marsHex(0x60A5FA))
        case "harbor", "scout_window", "convoy_window", "capital_window":
            return (size.width * 0.84, groundY - 72, .marsHex(0xF97316))
        case "scout_pod":
            return (size.width * 0.42, groundY - 136, .marsHex(0x60A5FA))
        case "ore_hauler":
            return (size.width * 0.68, groundY - 112, .marsHex(0xF97316))
        case "battle_cruiser":
            return (size.width * 0.58, groundY - 156, .white)
        case "dreadnought":
            return (size.width * 0.24, groundY - 178, .marsHex(0xDBEAFE))
        case "mining_drone":
            return (size.width * 0.3, groundY - 84, .marsHex(0xF59E0B))
        default:
            return (size.width * 0.5, groundY - 58, .marsHex(0xF97316))
        }
    }

    private func drawSceneHazard(context: GraphicsContext, size: CGSize, groundY: CGFloat, time: TimeInterval) {
        guard let hazard = model.activeHazard?.type else { return }

        switch hazard {
        case .dustStorm:
            for index in 0..<8 {
                let y = groundY - 110 + CGFloat(index) * 14
                var path = Path()
                path.move(to: CGPoint(x: -30, y: y))
                path.addLine(to: CGPoint(x: size.width + 20, y: y + 10 + CGFloat(sin(time * 1.7 + Double(index)) * 4)))
                context.stroke(path, with: .color(Color.marsHex(0xF59E0B).opacity(0.16)), lineWidth: 3)
            }
        case .coolantLeak:
            for index in 0..<6 {
                let x = size.width * 0.45 + CGFloat(index) * 18
                let y = groundY - 120 + CGFloat((time * Double(20 + index)).truncatingRemainder(dividingBy: 80))
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 6, height: 16)),
                    with: .color(Color.marsHex(0x60A5FA).opacity(0.18))
                )
            }
        case .solarFlare:
            for index in 0..<5 {
                var ray = Path()
                ray.move(to: CGPoint(x: size.width * 0.94, y: 12))
                ray.addLine(to: CGPoint(x: size.width * 0.7 - CGFloat(index) * 18, y: groundY - 92 + CGFloat(index) * 12))
                context.stroke(ray, with: .color(Color.marsHex(0xFED7AA).opacity(0.18)), lineWidth: 2.5)
            }
        }
    }
}

struct ReactorCoreView: View {
    let pulse: Int
    let lastTapAt: Date
    let tapGainText: String
    let chargeFraction: Double
    let autopilotActive: Bool
    let activeHazard: ColonyHazardType?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.animation) { context in
                let impact = tapImpact(at: context.date)
                ZStack {
                    ReactorHaloView(
                        time: context.date.timeIntervalSinceReferenceDate,
                        chargeFraction: chargeFraction,
                        autopilotActive: autopilotActive,
                        activeHazard: activeHazard
                    )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.marsHex(0xF97316).opacity(0.82), .marsHex(0x0B2147)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 290, height: 290)
                        .overlay(
                            Circle()
                                .stroke(Color.marsHex(0xF97316).opacity(0.45), lineWidth: 2)
                        )
                        .shadow(color: .marsHex(0xF97316).opacity(0.38), radius: 36, x: 0, y: 20)
                        .scaleEffect(1 + impact * 0.014)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.18 * impact), lineWidth: 3)
                                .blur(radius: 1.6)
                                .padding(-10)
                        )

                    Circle()
                        .trim(from: 0, to: max(0.08, min(chargeFraction, 1)))
                        .stroke(
                            LinearGradient(
                                colors: [Color.marsHex(0x60A5FA), .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 318, height: 318)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                        .frame(width: 330, height: 330)

                    VStack(spacing: 12) {
                        Image(systemName: activeHazard == .solarFlare ? "sun.max.fill" : "globe.americas.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(.white)

                        Text("MARS CORE")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("TAP FOR +\(tapGainText)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xFED7AA))

                        Text(autopilotActive ? "AUTOPILOT WINDOW LIVE" : "MANUAL EXTRACTION ONLINE")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .tracking(1.1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 408)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .clipped()
    }

    private func tapImpact(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(lastTapAt)
        guard elapsed >= 0, elapsed < 0.42 else { return 0 }
        let normalized = 1 - (elapsed / 0.42)
        return sin(normalized * .pi) * 0.92
    }
}

struct ReactorHaloView: View {
    let time: TimeInterval
    let chargeFraction: Double
    let autopilotActive: Bool
    let activeHazard: ColonyHazardType?

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) * 0.34
            drawOrbits(context: context, center: center, baseRadius: baseRadius)
            drawSatellites(context: context, center: center, baseRadius: baseRadius)
            drawAutopilotLines(context: context, center: center, baseRadius: baseRadius)
            drawHazard(context: context, center: center)
            drawCoreGlow(context: context, center: center)
        }
    }

    private func drawOrbits(context: GraphicsContext, center: CGPoint, baseRadius: CGFloat) {
        for index in 0..<3 {
            let orbitRadius = baseRadius + CGFloat(index * 18)
            let orbitRect = CGRect(
                x: center.x - orbitRadius,
                y: center.y - orbitRadius,
                width: orbitRadius * 2,
                height: orbitRadius * 2
            )
            context.stroke(
                Path(ellipseIn: orbitRect),
                with: .color(.white.opacity(0.08 + Double(index) * 0.03)),
                lineWidth: 1
            )
        }
    }

    private func drawSatellites(context: GraphicsContext, center: CGPoint, baseRadius: CGFloat) {
        for index in 0..<4 {
            let angle = time * (0.45 + Double(index) * 0.12) + Double(index) * 1.4
            let radius = baseRadius + CGFloat((index % 2) * 18)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius * 0.82
            )
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)),
                with: .color(autopilotActive ? Color.marsHex(0x60A5FA).opacity(0.9) : .white.opacity(0.72))
            )
        }
    }

    private func drawAutopilotLines(context: GraphicsContext, center: CGPoint, baseRadius: CGFloat) {
        guard autopilotActive else { return }

        for index in 0..<10 {
            let angle = CGFloat(time * 1.2 + Double(index) * 0.62)
            let start = CGPoint(
                x: center.x + cos(angle) * (baseRadius - 24),
                y: center.y + sin(angle) * (baseRadius - 24)
            )
            let end = CGPoint(
                x: center.x + cos(angle) * (baseRadius + 18),
                y: center.y + sin(angle) * (baseRadius + 18)
            )
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path, with: .color(Color.marsHex(0x60A5FA).opacity(0.12)), lineWidth: 2)
        }
    }

    private func drawHazard(context: GraphicsContext, center: CGPoint) {
        guard let activeHazard else { return }

        switch activeHazard {
        case .dustStorm:
            for index in 0..<12 {
                let y = center.y - 120 + CGFloat(index) * 20 + CGFloat(sin(time * 1.8 + Double(index)) * 8)
                var path = Path()
                path.move(to: CGPoint(x: center.x - 170, y: y))
                path.addLine(to: CGPoint(x: center.x + 170, y: y + 18))
                context.stroke(path, with: .color(Color.marsHex(0xF59E0B).opacity(0.12)), lineWidth: 3)
            }

        case .coolantLeak:
            for index in 0..<8 {
                let x = center.x - 80 + CGFloat(index) * 22
                let y = center.y - 150 + CGFloat((time * Double(24 + index * 2)).truncatingRemainder(dividingBy: 160))
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 6, height: 18)),
                    with: .color(Color.marsHex(0x60A5FA).opacity(0.14))
                )
            }

        case .solarFlare:
            for index in 0..<7 {
                let angle = CGFloat(-0.9 + Double(index) * 0.18)
                let start = CGPoint(x: center.x + 150, y: center.y - 150)
                let end = CGPoint(
                    x: center.x + cos(angle + CGFloat(time * 0.18)) * 180,
                    y: center.y + sin(angle + CGFloat(time * 0.18)) * 180
                )
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(Color.marsHex(0xFED7AA).opacity(0.16)), lineWidth: 2.5)
            }
        }
    }

    private func drawCoreGlow(context: GraphicsContext, center: CGPoint) {
        let coreGlow = CGRect(
            x: center.x - 110,
            y: center.y - 110,
            width: 220,
            height: 220
        )
        context.fill(
            Path(ellipseIn: coreGlow),
            with: .color(Color.marsHex(0xF97316).opacity(0.06 + chargeFraction * 0.12))
        )
    }
}

struct QuickStatsBar: View {
    let items: [(String, String)]

    var body: some View {
        GlassPanel {
            HStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 6) {
                        Text(item.0)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.66))

                        Text(item.1)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    if index < items.count - 1 {
                        Divider()
                            .overlay(.white.opacity(0.12))
                    }
                }
            }
        }
    }
}

struct CommandFeedCard: View {
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(feedTint.opacity(0.16))
                            .frame(width: 54, height: 54)

                        Image(systemName: feedIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(feedTint)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("COMMAND FEED")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(feedTint)
                            .tracking(1.2)
                        Text(feedTitle)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(model.lastPurchaseMessage)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        feedMetric("Facilities", "\(model.totalFacilityLevels())")
                        feedMetric("Research", "\(model.totalTechLevels())")
                        feedMetric("Fleet", "\(model.totalShips())")
                    }

                    VStack(spacing: 10) {
                        feedMetric("Facilities", "\(model.totalFacilityLevels())")
                        feedMetric("Research", "\(model.totalTechLevels())")
                        feedMetric("Fleet", "\(model.totalShips())")
                    }
                }
            }
            .frame(minHeight: 132, alignment: .top)
        }
    }

    private var feedIcon: String {
        let text = model.lastPurchaseMessage.lowercased()
        if text.contains("deployed") || text.contains("autopilot") { return "airplane.circle.fill" }
        if text.contains("research") || text.contains("relay") || text.contains("cells") { return "cpu.fill" }
        if text.contains("hazard") || text.contains("storm") || text.contains("flare") || text.contains("contain") { return "exclamationmark.shield.fill" }
        if text.contains("upgraded") { return "building.2.crop.circle.fill" }
        return "waveform.path.ecg.rectangle.fill"
    }

    private var feedTint: Color {
        let text = model.lastPurchaseMessage.lowercased()
        if text.contains("deployed") || text.contains("autopilot") { return .marsHex(0x60A5FA) }
        if text.contains("research") || text.contains("relay") { return .marsHex(0xF97316) }
        if text.contains("hazard") || text.contains("storm") || text.contains("flare") || text.contains("contain") { return .marsHex(0xF59E0B) }
        return .marsHex(0xF97316)
    }

    private var feedTitle: String {
        let text = model.lastPurchaseMessage.lowercased()
        if text.contains("deployed") { return "Fleet Change Registered" }
        if text.contains("research") { return "Research Delta Applied" }
        if text.contains("upgraded") { return "Colony Structure Expanded" }
        if text.contains("autopilot") { return "Command Window Shifted" }
        if text.contains("hazard") || text.contains("storm") || text.contains("flare") || text.contains("contain") { return "Operational Pressure Update" }
        return "Live Colony Update"
    }

    private func feedMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

enum ColonyInspectZone: String, CaseIterable {
    case extractor
    case reactor
    case harbor
    case fleet

    var shortLabel: String {
        switch self {
        case .extractor: return "Extract"
        case .reactor: return "Reactor"
        case .harbor: return "Harbor"
        case .fleet: return "Fleet"
        }
    }

    var icon: String {
        switch self {
        case .extractor: return "sun.max.fill"
        case .reactor: return "bolt.fill"
        case .harbor: return "antenna.radiowaves.left.and.right"
        case .fleet: return "paperplane.fill"
        }
    }

    var tint: Color {
        switch self {
        case .extractor: return .marsHex(0xF59E0B)
        case .reactor: return .marsHex(0x60A5FA)
        case .harbor: return .marsHex(0xF97316)
        case .fleet: return .white
        }
    }

    func frame(in size: CGSize, groundY: CGFloat) -> CGRect {
        switch self {
        case .extractor:
            return CGRect(x: size.width * 0.04, y: groundY - 70, width: size.width * 0.28, height: 90)
        case .reactor:
            return CGRect(x: size.width * 0.36, y: groundY - 120, width: size.width * 0.24, height: 140)
        case .harbor:
            return CGRect(x: size.width * 0.72, y: groundY - 116, width: size.width * 0.2, height: 130)
        case .fleet:
            return CGRect(x: size.width * 0.16, y: groundY - 190, width: size.width * 0.68, height: 94)
        }
    }
}

struct ColonyInspectCard: View {
    let zone: ColonyInspectZone
    @ObservedObject var model: MarsColonyModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(zone.shortLabel.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(zone.tint)
                    .tracking(1.2)
                Spacer()
                Image(systemName: zone.icon)
                    .foregroundStyle(zone.tint)
            }

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(zone.tint.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var title: String {
        switch zone {
        case .extractor: return "Surface Extraction District"
        case .reactor: return "Blue Reactor Spine"
        case .harbor: return "Orbital Harbor Link"
        case .fleet: return "Commanded Flight Paths"
        }
    }

    private var detail: String {
        switch zone {
        case .extractor:
            let extractor = model.districtLevel(id: "extractor")
            let solar = model.researchLevel(id: "solar_array")
            return "Extractor LVL \(extractor) and Solar LVL \(solar) are shaping dome count, panel fields and early reserve tempo."
        case .reactor:
            let reactor = model.districtLevel(id: "reactor")
            let fusion = model.researchLevel(id: "fusion_cell")
            let quantum = model.researchLevel(id: "quantum_core")
            return "Reactor LVL \(reactor), Fusion LVL \(fusion) and Quantum LVL \(quantum) are feeding charge cap, regen and core VFX intensity."
        case .harbor:
            let harbor = model.districtLevel(id: "harbor")
            let plasma = model.researchLevel(id: "plasma_conduit")
            return "Harbor LVL \(harbor) and Plasma LVL \(plasma) are powering contracts, uplinks and shipyard activity."
        case .fleet:
            return "\(model.totalShips()) total ships are visible in orbit. Fleet output is \(model.formatted(model.fleetOutput()))/s contract potential."
        }
    }
}

struct LionCrestBadge: View {
    let size: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Circle()
                        .stroke(tint.opacity(0.2), lineWidth: 1)
                )

            Canvas { context, canvasSize in
                var mane = Path()
                mane.move(to: CGPoint(x: canvasSize.width * 0.2, y: canvasSize.height * 0.32))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.34, y: canvasSize.height * 0.18), control: CGPoint(x: canvasSize.width * 0.2, y: canvasSize.height * 0.2))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.54, y: canvasSize.height * 0.2), control: CGPoint(x: canvasSize.width * 0.44, y: canvasSize.height * 0.12))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.34, y: canvasSize.height * 0.46), control: CGPoint(x: canvasSize.width * 0.46, y: canvasSize.height * 0.36))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.28, y: canvasSize.height * 0.74), control: CGPoint(x: canvasSize.width * 0.22, y: canvasSize.height * 0.58))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.56, y: canvasSize.height * 0.84), control: CGPoint(x: canvasSize.width * 0.34, y: canvasSize.height * 0.9))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.8, y: canvasSize.height * 0.58), control: CGPoint(x: canvasSize.width * 0.8, y: canvasSize.height * 0.84))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.66, y: canvasSize.height * 0.24), control: CGPoint(x: canvasSize.width * 0.84, y: canvasSize.height * 0.32))
                mane.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.44, y: canvasSize.height * 0.18), control: CGPoint(x: canvasSize.width * 0.58, y: canvasSize.height * 0.16))

                var face = Path()
                face.move(to: CGPoint(x: canvasSize.width * 0.38, y: canvasSize.height * 0.3))
                face.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.66, y: canvasSize.height * 0.34), control: CGPoint(x: canvasSize.width * 0.54, y: canvasSize.height * 0.2))
                face.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.74, y: canvasSize.height * 0.44), control: CGPoint(x: canvasSize.width * 0.78, y: canvasSize.height * 0.36))
                face.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.63, y: canvasSize.height * 0.54), control: CGPoint(x: canvasSize.width * 0.74, y: canvasSize.height * 0.58))
                face.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.52, y: canvasSize.height * 0.52), control: CGPoint(x: canvasSize.width * 0.58, y: canvasSize.height * 0.58))

                var eye = Path()
                eye.move(to: CGPoint(x: canvasSize.width * 0.54, y: canvasSize.height * 0.34))
                eye.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.6, y: canvasSize.height * 0.35), control: CGPoint(x: canvasSize.width * 0.57, y: canvasSize.height * 0.32))

                var mouth = Path()
                mouth.move(to: CGPoint(x: canvasSize.width * 0.64, y: canvasSize.height * 0.48))
                mouth.addQuadCurve(to: CGPoint(x: canvasSize.width * 0.54, y: canvasSize.height * 0.52), control: CGPoint(x: canvasSize.width * 0.59, y: canvasSize.height * 0.57))

                context.stroke(mane, with: .color(tint), style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))
                context.stroke(face, with: .color(tint), style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))
                context.stroke(eye, with: .color(tint), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                context.stroke(mouth, with: .color(tint), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

struct ColonyEffectCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let levelText: String
    let primary: String
    let secondary: String

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    FeatureIcon(symbol: icon, tint: tint)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            Text(title)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 8)

                            CapsuleLabel(text: levelText)
                        }

                        Text(subtitle)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Per level")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(tint)
                        .tracking(1.1)
                    Text(primary)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Live colony result")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.marsHex(0xF97316))
                        .tracking(1.1)
                    Text(secondary)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(tint.opacity(0.18), lineWidth: 1)
                        )
                )
            }
        }
    }
}

struct SectionTitleView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.marsHex(0xF97316))
                .tracking(1.2)

            Text(subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UpgradeActionButton: View {
    let title: String
    let costText: String
    let accent: Color
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                primaryButtonLayout
                compactButtonLayout
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(enabled ? accent : .white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(enabled ? 0.12 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.56)
    }

    private var primaryButtonLayout: some View {
        HStack(spacing: 14) {
            labelBlock(alignment: .leading)
            Spacer(minLength: 12)
            costBlock
        }
    }

    private var compactButtonLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            labelBlock(alignment: .leading)
            HStack {
                Spacer()
                costBlock
            }
        }
    }

    private func labelBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
            Text(enabled ? "Ready to deploy" : "More reserves required")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var costBlock: some View {
        HStack(spacing: 6) {
            Image(systemName: "creditcard.fill")
            Text(costText)
        }
        .font(.system(size: 16, weight: .black, design: .rounded))
        .foregroundStyle(enabled ? .white : .white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.white.opacity(enabled ? 0.16 : 0.08))
        )
    }
}

struct FacilityCard: View {
    let facility: FacilityDefinition
    let level: Int
    let costText: String
    let gainText: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    FeatureIcon(symbol: facility.icon, tint: .marsHex(facility.tintHex))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Text(facility.title)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 8)

                            CapsuleLabel(text: "LVL \(level)")
                        }

                        Text(facility.subtitle)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(gainText)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                UpgradeActionButton(
                    title: "UPGRADE",
                    costText: costText,
                    accent: .marsHex(facility.tintHex),
                    enabled: enabled,
                    action: action
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct TechCard: View {
    let tech: TechDefinition
    let level: Int
    let costText: String
    let gainText: String
    let enabled: Bool
    let action: () -> Void

    private var actionAccent: Color {
        tech.tintHex >= 0xF0F0F0 ? .marsHex(0x2563EB) : .marsHex(tech.tintHex)
    }

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    FeatureIcon(symbol: tech.icon, tint: .marsHex(tech.tintHex))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Text(tech.title)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 8)

                            CapsuleLabel(text: "LVL \(level)")
                        }

                        Text(tech.subtitle)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(gainText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))
                            .lineLimit(3)
                            .minimumScaleFactor(0.88)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                UpgradeActionButton(
                    title: "RESEARCH",
                    costText: costText,
                    accent: actionAccent,
                    enabled: enabled,
                    action: action
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct ShipCard: View {
    let ship: ShipDefinition
    let count: Int
    let costText: String
    let outputText: String
    let totalText: String
    let enabled: Bool
    let action: () -> Void

    private var actionAccent: Color {
        ship.tintHex >= 0xF0F0F0 ? .marsHex(0x1D4ED8) : .marsHex(ship.tintHex)
    }

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    FeatureIcon(symbol: ship.icon, tint: .marsHex(ship.tintHex))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Text(ship.title)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Spacer(minLength: 8)

                            if count > 0 {
                                CapsuleLabel(text: "x\(count)")
                            }
                        }

                        Text(ship.subtitle)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(outputText) each  ·  \(totalText)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.marsHex(0xF97316))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                UpgradeActionButton(
                    title: "BUY",
                    costText: costText,
                    accent: actionAccent,
                    enabled: enabled,
                    action: action
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct CapsuleLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.marsHex(0xA63A14).opacity(0.65), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FeatureIcon: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(tint.opacity(0.18))
                .frame(width: 88, height: 88)

            Image(systemName: symbol)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(tint)
        }
    }
}

struct StatListCard: View {
    let title: String
    let rows: [(String, String)]

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 18) {
                Text(title.uppercased())
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.marsHex(0xF97316))

                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    VStack(spacing: 0) {
                        HStack {
                            Text(row.0)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.72))
                            Spacer()
                            Text(row.1)
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        if index < rows.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.08))
                                .padding(.top, 14)
                        }
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementDefinition
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((unlocked ? Color.marsHex(0xF97316) : Color.white.opacity(0.08)))
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(unlocked ? .white : .white.opacity(0.55))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(achievement.detail)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            if unlocked {
                Text("DONE")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.marsHex(0xFED7AA))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(unlocked ? 0.1 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(unlocked ? Color.marsHex(0xF97316).opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct MissionFooterBar: View {
    let selected: ColonyTab
    let action: (ColonyTab) -> Void

    var body: some View {
        HStack(spacing: 8) {
            footerButton(.base, title: "BASE", icon: "bolt.fill")
            footerButton(.colony, title: "COLONY", icon: "building.2.fill")
            footerButton(.tech, title: "TECH", icon: "point.3.filled.connected.trianglepath.dotted")
            footerButton(.fleet, title: "FLEET", icon: "paperplane.fill")
            footerButton(.logs, title: "LOGS", icon: "chart.bar.xaxis")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.26), radius: 16, x: 0, y: 12)
    }

    private func footerButton(_ tab: ColonyTab, title: String, icon: String) -> some View {
        let isSelected = selected == tab
        return Button {
            action(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.marsHex(0xA63A14), Color.marsHex(0xF97316)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .white.opacity(0.16) : .clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.marsHex(0xF97316).opacity(0.26) : .clear, radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}
