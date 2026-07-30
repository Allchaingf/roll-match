//
//  OnboardingView.swift
//  RollMatch
//
//  Pattern-first onboarding (5 screens). Each screen has a unique illustrated scene and
//  a distinct interactive element: tap-burst, drag, gyro parallax, sequential reveal,
//  pulsing CTA. Selections seed the first wall. State persisted via hasCompletedOnboarding.
//

import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: AppStore

    @State private var page = 0

    // O1 — entry
    @State private var goal: MainGoal = .featureWall
    @State private var frequency = "Occasional"
    @State private var startMode = "Feature Wall"
    // O2 — match
    @State private var matchType: MatchType = .straight
    @State private var repeatDirection = "Vertical"
    @State private var motifScale: Double = 1.0
    // O3 — roll spec
    @State private var rollPreset = "Standard"
    @State private var rollWidth: Double = 0.53
    @State private var rollLength: Double = 10.05
    @State private var repeatHeight: Double = 0.32
    // O4 — context
    @State private var workspaceName = "My Room"
    @State private var locationLabel = ""
    @State private var surface: SurfaceType = .painted
    @State private var reminderStyle = "Quick Setup"
    // O5 — first record
    @State private var wallTitle = "Feature Wall"
    @State private var priority: WallPriority = .normal
    @State private var firstMode = "Create Now"

    private let lastPage = 4

    var body: some View {
        ZStack {
            RMBackground()
            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    O1Entry(goal: $goal, frequency: $frequency, startMode: $startMode).tag(0)
                    O2Match(matchType: $matchType, repeatDirection: $repeatDirection, motifScale: $motifScale).tag(1)
                    O3Ruler(preset: $rollPreset, rollWidth: $rollWidth, rollLength: $rollLength, repeatHeight: $repeatHeight).tag(2)
                    O4Context(workspaceName: $workspaceName, locationLabel: $locationLabel, surface: $surface, reminderStyle: $reminderStyle, goal: goal).tag(3)
                    O5First(wallTitle: $wallTitle, priority: $priority, firstMode: $firstMode).tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                dots
                primaryCTA
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                    .padding(.top, 10)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Step \(page + 1) of 5")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(RM.textMuted)
            Spacer()
            Button(action: finish) {
                Text("Skip")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RM.secondary)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0...lastPage, id: \.self) { i in
                Capsule()
                    .fill(i == page ? RM.primary : RM.textMuted.opacity(0.4))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
            }
        }
        .padding(.vertical, 6)
    }

    private var ctaTitle: String {
        switch page {
        case 0: return "Enter \(goal.label)"
        case 1: return "Use This Match"
        case 2: return "Lock Roll Spec"
        case 3: return "Set Wall Context"
        default: return "Create Wall Record"
        }
    }

    private var primaryCTA: some View {
        PrimaryButton(title: ctaTitle, icon: page == lastPage ? "checkmark" : "arrow.right") {
            settings.haptic()
            if page < lastPage {
                withAnimation { page += 1 }
            } else {
                finish()
            }
        }
    }

    private func finish() {
        // Persist units already chosen on O3; build the first wall based on O5 mode.
        switch firstMode {
        case "Use Sample":
            store.addWall(AppStore.sampleWall())
        case "Start Empty":
            break
        default: // Create Now
            var w = Wall()
            w.title = wallTitle.isEmpty ? "Feature Wall" : wallTitle
            w.projectName = workspaceName.isEmpty ? "My Room" : workspaceName
            w.goal = goal
            w.pattern = PatternSpec(matchType: matchType,
                                    repeatHeight: repeatHeight,
                                    dropOffset: repeatHeight / 2,
                                    motifScale: motifScale)
            w.roll = RollSpec(width: rollWidth, length: rollLength)
            w.notes = locationLabel.isEmpty ? "" : "Location: \(locationLabel)"
            w.priority = priority
            switch surface {
            case .painted: w.prep.notes = "Painted surface"
            case .lining: w.prep.liningPaper = true
            case .plaster: w.prep.sizingPrimer = true
            }
            store.addWall(w)
        }
        onDone()
    }
}

// MARK: - O1 Entry (tap-burst)

private struct O1Entry: View {
    @Binding var goal: MainGoal
    @Binding var frequency: String
    @Binding var startMode: String
    @State private var burst = false
    @State private var bgDrift = false

    private let frequencies = ["Occasional", "Regular", "Pro / Crew"]
    private let modes = ["Feature Wall", "Whole Room", "Ceiling"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Tappable hero icon that bursts particles
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        Circle()
                            .fill(RM.secondary)
                            .frame(width: 8, height: 8)
                            .offset(x: burst ? cos(Double(i)/8 * 2 * .pi) * 70 : 0,
                                    y: burst ? sin(Double(i)/8 * 2 * .pi) * 70 : 0)
                            .opacity(burst ? 0 : 1)
                    }
                    Circle()
                        .fill(RM.primaryGradient)
                        .frame(width: 90, height: 90)
                        .overlay(Image(systemName: "square.grid.3x3.topleft.filled")
                            .font(.system(size: 38, weight: .bold)).foregroundColor(RM.bg))
                        .scaleEffect(bgDrift ? 1.03 : 0.97)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .onTapGesture {
                    burst = false
                    withAnimation(.easeOut(duration: 0.6)) { burst = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { burst = false }
                }

                Text("Roll Match Entry")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(RM.textHead)
                Text("Turn a real wall into a clean hanging plan. Tap the tile to feel the snap — no sign-up, ever.")
                    .font(.system(size: 14)).foregroundColor(RM.textMuted)

                fieldLabel("Main Goal")
                EnumChips(items: MainGoal.allCases, selection: $goal, label: { $0.label }, icon: { $0.icon })

                fieldLabel("Use Frequency")
                FlowChips(items: frequencies) { f in
                    RMChip(label: f, selected: frequency == f) { frequency = f }
                }

                fieldLabel("Start Mode")
                FlowChips(items: modes) { m in
                    RMChip(label: m, selected: startMode == m) { startMode = m }
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bgDrift = true }
        }
        .onDisappear { bgDrift = false; burst = false }
    }
}

// MARK: - O2 Match (drag to slide strips)

private struct O2Match: View {
    @Binding var matchType: MatchType
    @Binding var repeatDirection: String
    @Binding var motifScale: Double
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pattern Repeat Preview")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(RM.textHead)
                Text("See how the pattern lines up before you buy. Drag the right strip to feel the drop.")
                    .font(.system(size: 14)).foregroundColor(RM.textMuted)

                previewTiles
                    .frame(height: 180)
                    .gesture(
                        DragGesture()
                            .onChanged { v in dragOffset = max(-60, min(60, v.translation.height)) }
                            .onEnded { _ in withAnimation(.spring()) { dragOffset = 0 } }
                    )

                fieldLabel("Match Type")
                EnumChips(items: MatchType.allCases, selection: $matchType, label: { $0.shortLabel }, icon: { $0.icon })
                Text(matchType.detail).font(.system(size: 12.5)).foregroundColor(RM.textMuted)

                fieldLabel("Repeat Direction")
                FlowChips(items: ["Vertical", "Horizontal", "Both"]) { d in
                    RMChip(label: d, selected: repeatDirection == d) { repeatDirection = d }
                }

                fieldLabel("Motif Scale  •  \(String(format: "%.1f×", motifScale))")
                Slider(value: $motifScale, in: 0.5...2.0, step: 0.1)
                    .accentColor(RM.primary)
            }
            .padding(20)
        }
        .onDisappear { dragOffset = 0 }
    }

    private var previewTiles: some View {
        let drop: CGFloat = matchType == .drop ? 30 : 0
        return HStack(spacing: 4) {
            tileColumn(offset: 0)
            tileColumn(offset: matchType == .free ? 14 : drop + dragOffset)
            tileColumn(offset: matchType == .free ? -10 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RM.cardBorder.opacity(0.4), lineWidth: 1))
    }

    private func tileColumn(offset: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(LinearGradient(colors: [RM.strip, RM.strip.opacity(0.55)], startPoint: .top, endPoint: .bottom))
            VStack(spacing: 14) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "seal.fill")
                        .font(.system(size: 16 * CGFloat(motifScale)))
                        .foregroundColor(RM.secondary)
                }
            }
            .offset(y: offset)
            HStack { Spacer(); Rectangle().fill(RM.seam).frame(width: 2) }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

// MARK: - O3 Ruler (gyro parallax)

private struct O3Ruler: View {
    @Binding var preset: String
    @Binding var rollWidth: Double
    @Binding var rollLength: Double
    @Binding var repeatHeight: Double
    @EnvironmentObject var settings: AppSettings
    @StateObject private var motion = MotionManager()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Repeat Ruler Setup")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(RM.textHead)
                Text("Set the roll size and the pattern repeat height. Tilt your phone — the ruler responds.")
                    .font(.system(size: 14)).foregroundColor(RM.textMuted)

                HStack {
                    RepeatRulerView(repeatHeight: repeatHeight, rollLength: rollLength)
                        .frame(width: 130, height: 200)
                        .offset(x: CGFloat(motion.roll) * 16, y: CGFloat(motion.pitch) * 10)
                    VStack(spacing: 12) {
                        RMNumberField(title: "Repeat Height", value: $repeatHeight, unit: "m", icon: "ruler")
                        RMNumberField(title: "Roll Width", value: $rollWidth, unit: "m", icon: "arrow.left.and.right")
                        RMNumberField(title: "Roll Length", value: $rollLength, unit: "m", icon: "arrow.up.and.down")
                    }
                }

                fieldLabel("Roll Preset")
                FlowChips(items: ["Standard", "Wide", "Custom"]) { p in
                    RMChip(label: p, selected: preset == p) {
                        preset = p
                        if p == "Standard" { rollWidth = 0.53; rollLength = 10.05 }
                        else if p == "Wide" { rollWidth = 1.06; rollLength = 25.0 }
                    }
                }

                fieldLabel("Units")
                FlowChips(items: MeasureUnit.allCases) { u in
                    RMChip(label: u.label, selected: settings.units == u) { settings.units = u }
                }
            }
            .padding(20)
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

// MARK: - O4 Context (sequential reveal + long-press confirm)

private struct O4Context: View {
    @Binding var workspaceName: String
    @Binding var locationLabel: String
    @Binding var surface: SurfaceType
    @Binding var reminderStyle: String
    let goal: MainGoal
    @State private var revealed = 0
    @State private var stamped = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Wall Workspace Context")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(RM.textHead)
                Text(hint).font(.system(size: 14)).foregroundColor(RM.textMuted)

                // surface icon reflects choice
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(RM.cardBlue).frame(height: 90)
                    HStack(spacing: 22) {
                        Image(systemName: surface.icon).font(.system(size: 34, weight: .bold)).foregroundColor(RM.primary)
                        Image(systemName: "scribble.variable").font(.system(size: 24)).foregroundColor(RM.strip)
                            .scaleEffect(stamped ? 1.2 : 1)
                            .opacity(stamped ? 1 : 0.4)
                    }
                }

                if revealed >= 1 { RMTextField(title: "Workspace Name", text: $workspaceName, placeholder: "My Room", icon: "square.split.2x2").transition(.move(edge: .bottom).combined(with: .opacity)) }
                if revealed >= 2 { RMTextField(title: "Location Label", text: $locationLabel, placeholder: "Apartment, north wall", icon: "mappin.and.ellipse").transition(.move(edge: .bottom).combined(with: .opacity)) }
                if revealed >= 3 {
                    fieldLabel("Surface Type")
                    EnumChips(items: SurfaceType.allCases, selection: $surface, label: { $0.label }, icon: { $0.icon })
                }
                if revealed >= 4 {
                    fieldLabel("Reminder Style")
                    FlowChips(items: ["Quick Setup", "Detailed Setup", "Photo First"]) { s in
                        RMChip(label: s, selected: reminderStyle == s) { reminderStyle = s }
                    }
                }

                // distinct gesture: long-press to "stamp" context complete
                Text(stamped ? "Context stamped ✓" : "Long-press to stamp context")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(stamped ? RM.ok : RM.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(RM.secondary.opacity(0.5), lineWidth: 1.4))
                    .onLongPressGesture(minimumDuration: 0.4) {
                        withAnimation(.spring()) { stamped = true }
                    }
            }
            .padding(20)
        }
        .onAppear { revealSequentially() }
        .onDisappear { revealed = 0; stamped = false }
    }

    private var hint: String {
        switch goal {
        case .featureWall: return "Describe the feature wall before creating records."
        case .wholeRoom: return "Describe the room before creating records."
        case .ceiling: return "Describe the ceiling area before creating records."
        }
    }

    private func revealSequentially() {
        revealed = 0
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { revealed = i }
            }
        }
    }
}

// MARK: - O5 First record (pulsing CTA)

private struct O5First: View {
    @Binding var wallTitle: String
    @Binding var priority: WallPriority
    @Binding var firstMode: String
    @State private var pulse = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("First Wall Record")
                    .font(.system(size: 26, weight: .heavy)).foregroundColor(RM.textHead)
                Text("Create one useful wall now or start empty.")
                    .font(.system(size: 14)).foregroundColor(RM.textMuted)

                // mode cards
                VStack(spacing: 10) {
                    modeCard("Create Now", "Build a wall from your choices", "plus.rectangle.on.rectangle", RM.primary, pulses: true)
                    modeCard("Use Sample", "Load a demo wall with a ready layout", "doc.on.doc", RM.strip, pulses: false)
                    modeCard("Start Empty", "Skip and add walls later", "tray", RM.textMuted, pulses: false)
                }

                if firstMode == "Create Now" {
                    RMTextField(title: "Wall Title", text: $wallTitle, placeholder: "Feature Wall", icon: "rectangle.portrait")
                    fieldLabel("Priority")
                    EnumChips(items: WallPriority.allCases, selection: $priority, label: { $0.label })
                    HStack {
                        Image(systemName: "calendar").foregroundColor(RM.textMuted)
                        Text(DateFormatter.rmMedium.string(from: Date())).foregroundColor(RM.textSub).font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue))
                }
            }
            .padding(20)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true } }
        .onDisappear { pulse = false }
    }

    private func modeCard(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, pulses: Bool) -> some View {
        Button(action: { withAnimation(.spring()) { firstMode = title } }) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundColor(color).frame(width: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(RM.textMain)
                    Text(subtitle).font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
                Spacer()
                Image(systemName: firstMode == title ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(firstMode == title ? color : RM.textMuted)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(RM.cardWhite))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(firstMode == title ? color : RM.cardBorder, lineWidth: firstMode == title ? 2 : 1))
            .shadow(color: pulses && firstMode == title ? RM.orangeGlow : .clear,
                    radius: pulses && pulse ? 14 : 0)
            .scaleEffect(pulses && firstMode == title && pulse ? 1.015 : 1)
        }
    }
}

// MARK: - Shared label

private func fieldLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 12, weight: .heavy))
        .foregroundColor(RM.secondary)
}
