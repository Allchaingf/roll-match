//
//  WallsTab.swift
//  RollMatch
//
//  Walls hub + screens 01 Wall Dimension Capture, 02 Wall Photo Markup,
//  17 Wall Detail, 18 Hang Progress, 19 Approval Signoff.
//

import SwiftUI

// MARK: - Walls hub

struct WallsHubView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @Binding var selectedWallID: UUID?
    var goToTab: (MainTabView.Tab) -> Void
    @State private var newWallID: UUID?
    @State private var pushNew = false

    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        summaryStrip
                        // hidden link to a freshly created wall
                        NavigationLink(destination: newDestination, isActive: $pushNew) { EmptyView() }.hidden()

                        if store.walls.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.walls) { wall in
                                NavigationLink(destination: WallDetailScreen(wallID: wall.id)) {
                                    WallCard(wall: wall)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 16)
                            }
                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder private var newDestination: some View {
        if let id = newWallID { WallDimensionScreen(wallID: id) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Walls").font(.system(size: 30, weight: .heavy)).foregroundColor(RM.textHead)
                Text("Your hanging plans").font(.system(size: 13)).foregroundColor(RM.textMuted)
            }
            Spacer()
            Button(action: createWall) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New").font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(RM.bg)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(settings.accentGradient)
                .cornerRadius(13)
                .shadow(color: RM.orangeGlow, radius: 8, y: 3)
            }
        }
        .padding(.horizontal, 16)
    }

    private var summaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                MetricTile(value: "\(store.walls.count)", label: "Walls", color: RM.strip, icon: "rectangle.split.3x1")
                MetricTile(value: "\(store.totalRollsPlanned)", label: "Rolls planned", color: RM.primary, icon: "shippingbox")
                MetricTile(value: "\(store.wallsApproved)", label: "Approved", color: RM.ok, icon: "checkmark.seal")
                MetricTile(value: "\(store.openDefects)", label: "Defects", color: RM.defect, icon: "exclamationmark.triangle")
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.grid.3x3.topleft.filled")
                .font(.system(size: 50)).foregroundColor(RM.strip.opacity(0.6))
            Text("No walls yet").font(.system(size: 18, weight: .bold)).foregroundColor(RM.textHead)
            Text("Tap New to capture your first wall, or load a sample.")
                .font(.system(size: 14)).foregroundColor(RM.textMuted).multilineTextAlignment(.center)
            SecondaryButton(title: "Load Sample Wall", icon: "doc.on.doc") {
                let w = AppStore.sampleWall()
                store.addWall(w); selectedWallID = w.id
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    private func createWall() {
        settings.haptic()
        var w = Wall()
        w.title = "Wall \(store.walls.count + 1)"
        store.addWall(w)
        selectedWallID = w.id
        newWallID = w.id
        pushNew = true
    }
}

// MARK: - Wall card

struct WallCard: View {
    let wall: Wall
    var body: some View {
        let r = MatchEngine.rollResult(for: wall)
        return RMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wall.title).font(.system(size: 17, weight: .bold)).foregroundColor(RM.textMain)
                        Text(wall.projectName).font(.system(size: 12.5)).foregroundColor(RM.textSub)
                    }
                    Spacer()
                    StatusBadge(text: wall.status.label, color: wall.status.color, icon: wall.status.icon)
                }
                StripLayoutView(wall: wall, height: 90)
                HStack(spacing: 14) {
                    miniStat("\(r.rollsTotal)", "rolls")
                    miniStat("\(r.stripsNeeded)", "strips")
                    miniStat(wall.pattern.matchType.shortLabel, "match")
                    Spacer()
                    Image(systemName: wall.priority == .high ? "flag.fill" : "flag")
                        .foregroundColor(wall.priority.color)
                }
            }
        }
    }
    private func miniStat(_ v: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(v).font(.system(size: 15, weight: .heavy)).foregroundColor(RM.primary)
            Text(l.uppercased()).font(.system(size: 9, weight: .heavy)).foregroundColor(RM.textMuted)
        }
    }
}

// MARK: - 01 Wall Dimension Capture

struct WallDimensionScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        DetailScaffold("Wall Dimension Capture",
                       caption: "Enter real wall size and verify the measuring point.") {
            WallSchematicView(wall: wall.wrappedValue, height: 150)
                .modifier(CardWrap())

            RMCard {
                VStack(spacing: 12) {
                    RMTextField(title: "Project", text: wall.projectName, placeholder: "Room", icon: "square.split.2x2")
                    RMTextField(title: "Wall Title", text: wall.title, placeholder: "Feature wall", icon: "rectangle.portrait")
                    HStack(spacing: 12) {
                        RMNumberField(title: "Width", value: wall.width, unit: "m", icon: "arrow.left.and.right")
                        RMNumberField(title: "Height", value: wall.height, unit: "m", icon: "arrow.up.and.down")
                    }
                    HStack(spacing: 12) {
                        RMNumberField(title: "Repeat Offset", value: wall.repeatOffset, unit: "m", icon: "arrow.up.to.line")
                        RMNumberField(title: "Tolerance", value: wall.tolerance, unit: "m", icon: "plusminus")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("UNITS").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        FlowChips(items: MeasureUnit.allCases) { u in
                            RMChip(label: u.label, selected: settings.units == u) { settings.units = u }
                        }
                    }
                    RMTextField(title: "Measuring Point", text: wall.measurePoint, placeholder: "Floor → ceiling, left edge", icon: "mappin")
                }
            }

            RMCard(light: false) {
                HStack {
                    Image(systemName: "checkmark.shield").foregroundColor(RM.ok)
                    Text("Saved size feeds the layout, roll count and warnings.")
                        .font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
            }

            PrimaryButton(title: "Lock Wall Size", icon: "lock.fill") {
                flash("Wall size locked")
            }
            SecondaryButton(title: "Keep Wall Measure", icon: "tray.and.arrow.down") {
                flash("Measure kept")
            }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue
                    w.width = 0; w.height = 0; w.repeatOffset = 0; w.tolerance = 0
                    store.updateWall(w)
                    flash("Fields cleared")
                }
                NavigationLink(destination: PatternSetupScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "square.grid.3x3"); Text("Pattern Setup").font(.system(size: 15, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func flash(_ m: String) {
        settings.haptic()
        toastMsg = m
        withAnimation { toast = true }
    }
}

/// Small modifier to wrap a visual in a card-like background.
struct CardWrap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18).fill(RM.cardWhite))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(RM.cardBorder, lineWidth: 1))
    }
}

// MARK: - 02 Wall Photo Markup

struct WallPhotoMarkupScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var showPicker = false
    @State private var pickerSource: ImagePicker.Source = .library
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        DetailScaffold("Wall Photo Markup",
                       caption: "Photo the wall, circle key spots, add a note.") {
            photoArea(wall)

            HStack(spacing: 12) {
                SecondaryButton(title: "Camera", icon: "camera") {
                    pickerSource = .camera; showPicker = true
                }
                SecondaryButton(title: "Library", icon: "photo") {
                    pickerSource = .library; showPicker = true
                }
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FOCAL POINT  •  \(Int(wall.wrappedValue.centering.focalPoint * 100))% across")
                        .font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    Slider(value: wall.centering.focalPoint, in: 0...1).accentColor(RM.primary)
                    Text("Where the motif should be centred (fireplace / TV).")
                        .font(.system(size: 12)).foregroundColor(RM.textMuted)
                    RMTextField(title: "Caption", text: wall.photoCaption, placeholder: "Socket on the left, slight bow", icon: "text.bubble")
                }
            }

            RMCard(light: false) {
                HStack {
                    Image(systemName: "hand.tap").foregroundColor(RM.secondary)
                    Text("Tap the photo to drop area markers (\(wall.wrappedValue.markPoints.count) placed).")
                        .font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
            }

            PrimaryButton(title: "Pin Markup", icon: "mappin.and.ellipse") { flash("Markup pinned") }
            SecondaryButton(title: "Keep Markup", icon: "tray.and.arrow.down") { flash("Markup kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue
                    w.markPoints = []; w.photoCaption = ""
                    store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: RepeatMatchScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "square.grid.3x3.topleft.filled"); Text("Match Preview").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(source: pickerSource) { img in
                var w = wall.wrappedValue
                w.photo = img.rmData()
                store.updateWall(w)
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func photoArea(_ wall: Binding<Wall>) -> some View {
        GeometryReader { geo in
            ZStack {
                if let data = wall.wrappedValue.photo, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(RM.cardBlue)
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled").font(.system(size: 40)).foregroundColor(RM.textMuted)
                        Text("No photo yet").font(.system(size: 13, weight: .bold)).foregroundColor(RM.textSub)
                    }
                }
                // markers
                ForEach(Array(wall.wrappedValue.markPoints.enumerated()), id: \.offset) { _, p in
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(RM.seam)
                        .position(x: CGFloat(p.x) * geo.size.width, y: CGFloat(p.y) * geo.size.height)
                }
                // focal crosshair
                Image(systemName: "scope")
                    .font(.system(size: 30, weight: .bold)).foregroundColor(RM.secondary)
                    .position(x: CGFloat(wall.wrappedValue.centering.focalPoint) * geo.size.width,
                              y: geo.size.height * 0.4)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RM.cardBorder, lineWidth: 1))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { v in
                    let nx = max(0, min(1, Double(v.location.x / geo.size.width)))
                    let ny = max(0, min(1, Double(v.location.y / geo.size.height)))
                    var w = wall.wrappedValue
                    w.markPoints.append(CGPointCodable(x: nx, y: ny))
                    store.updateWall(w); settings.haptic(.light)
                }
            )
        }
        .frame(height: 240)
    }

    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 17 Wall Detail

struct WallDetailScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let r = MatchEngine.rollResult(for: wall.wrappedValue)
        return DetailScaffold(wall.wrappedValue.title,
                              caption: "Everything about this wall in one card.") {
            StripLayoutView(wall: wall.wrappedValue, height: 150).modifier(CardWrap())

            // metrics
            HStack(spacing: 10) {
                MetricTile(value: "\(r.rollsTotal)", label: "Rolls", color: RM.primary, icon: "shippingbox")
                MetricTile(value: "\(r.stripsNeeded)", label: "Strips", color: RM.strip, icon: "rectangle.split.3x1")
                MetricTile(value: String(format: "%.0f%%", r.patternWastePercent), label: "Pattern waste", color: RM.warn, icon: "scissors")
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    detailRow("Project", wall.wrappedValue.projectName)
                    detailRow("Match type", wall.wrappedValue.pattern.matchType.label)
                    detailRow("Repeat", MatchEngine.shortLength(wall.wrappedValue.pattern.repeatHeight, unit: settings.units))
                    detailRow("Size", "\(MatchEngine.lengthString(wall.wrappedValue.width, unit: settings.units)) × \(MatchEngine.lengthString(wall.wrappedValue.height, unit: settings.units))")
                    Divider().background(RM.cardBorder)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STATUS").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        FlowChips(items: WallStatus.allCases) { s in
                            RMChip(label: s.label, icon: s.icon, selected: wall.wrappedValue.status == s) {
                                var w = wall.wrappedValue; w.status = s; store.updateWall(w)
                            }
                        }
                    }
                    RMNumberField(title: "Rolls planned (override)", value: Binding(
                        get: { Double(wall.wrappedValue.extraPercent) },
                        set: { var w = wall.wrappedValue; w.extraPercent = $0; store.updateWall(w) }), unit: "% extra")
                    RMTextField(title: "Notes", text: wall.notes, placeholder: "Centre the motif on the TV unit")
                }
            }

            if let data = wall.wrappedValue.photo, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill().frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RM.cardBorder, lineWidth: 1))
            }

            PrimaryButton(title: "Update Wall", icon: "checkmark") { flash("Wall updated") }
            HStack(spacing: 12) {
                SecondaryButton(title: "Duplicate", icon: "doc.on.doc") {
                    _ = store.duplicateWall(wall.wrappedValue); flash("Duplicated")
                }
                NavigationLink(destination: WallPhotoMarkupScreen(wallID: wallID)) {
                    linkLabel("Markup", "photo")
                }
            }
            HStack(spacing: 12) {
                NavigationLink(destination: HangProgressScreen(wallID: wallID)) { linkLabel("Progress", "chart.bar") }
                NavigationLink(destination: ApprovalScreen(wallID: wallID)) { linkLabel("Approval", "signature") }
            }
            HStack(spacing: 12) {
                NavigationLink(destination: RollCalculatorScreen(wallID: wallID)) { linkLabel("Rolls", "function") }
                NavigationLink(destination: DropPlanScreen(wallID: wallID)) { linkLabel("Cut Plan", "scissors") }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func detailRow(_ l: String, _ v: String) -> some View {
        HStack {
            Text(l).font(.system(size: 13)).foregroundColor(RM.textSub)
            Spacer()
            Text(v).font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
        }
    }
    private func linkLabel(_ t: String, _ icon: String) -> some View {
        HStack(spacing: 6) { Image(systemName: icon); Text(t).font(.system(size: 14, weight: .bold)) }
            .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(RM.strip).cornerRadius(14)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 18 Hang Progress

struct HangProgressScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let total = MatchEngine.stripsNeeded(wallWidth: wall.wrappedValue.width, rollWidth: wall.wrappedValue.roll.width)
        let done = wall.wrappedValue.progress.stripsDone
        let pct = total > 0 ? Double(min(done, total)) / Double(total) : 0
        return DetailScaffold("Hang Progress",
                              caption: "Track strips hung against the plan.") {
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(done) / \(total) strips")
                            .font(.system(size: 20, weight: .heavy)).foregroundColor(RM.textMain)
                        Spacer()
                        Text("\(Int(pct * 100))%").font(.system(size: 20, weight: .heavy)).foregroundColor(RM.ok)
                    }
                    ProgressBar(value: pct)
                    Text("\(max(total - done, 0)) strips left")
                        .font(.system(size: 13)).foregroundColor(RM.textSub)
                }
            }

            RMCard {
                VStack(spacing: 14) {
                    RMIntStepper(title: "Strips Done", value: Binding(
                        get: { wall.wrappedValue.progress.stripsDone },
                        set: { var w = wall.wrappedValue; w.progress.stripsDone = min($0, total); store.updateWall(w) }),
                        range: 0...max(total, 0))
                    RMIntStepper(title: "Time Spent (min)", value: Binding(
                        get: { wall.wrappedValue.progress.timeSpentMinutes },
                        set: { var w = wall.wrappedValue; w.progress.timeSpentMinutes = $0; store.updateWall(w) }),
                        range: 0...600)
                    RMTextField(title: "Issues", text: wall.progress.issues, placeholder: "Strip 3 bubbled at top")
                }
            }

            PrimaryButton(title: "Save Progress", icon: "square.and.arrow.down") {
                var w = wall.wrappedValue
                if w.progress.stripsDone >= total && total > 0 { w.status = .hung }
                else if w.progress.stripsDone > 0 { w.status = .inWork }
                store.updateWall(w); flash("Progress saved")
            }
            SecondaryButton(title: "Keep Progress", icon: "tray.and.arrow.down") { flash("Kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.progress = HangProgress(); store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: ApprovalScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "signature"); Text("Approval").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

struct ProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(RM.cardBorder).frame(height: 12)
                Capsule().fill(LinearGradient(colors: [RM.ok, RM.strip], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, value)) * geo.size.width, height: 12)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - 19 Approval Signoff

struct ApprovalScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Approval Signoff",
                              caption: "Review the evidence and record a clear decision.") {
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    RMTextField(title: "Reviewer", text: wall.approval.reviewer, placeholder: "Your name", icon: "person")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DECISION").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        FlowChips(items: ApprovalDecision.allCases) { d in
                            RMChip(label: d.label, selected: wall.wrappedValue.approval.decision == d) {
                                var w = wall.wrappedValue; w.approval.decision = d; store.updateWall(w)
                            }
                        }
                    }
                    RMTextField(title: "Comment", text: wall.approval.comment, placeholder: "Seams tight, pattern aligned")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SIGNATURE").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.secondary)
                SignaturePad(strokes: wall.approval.signature)
                    .frame(height: 160)
                Button(action: {
                    var w = wall.wrappedValue; w.approval.signature = []; store.updateWall(w)
                }) {
                    Text("Clear signature").font(.system(size: 13, weight: .bold)).foregroundColor(RM.strip)
                }
            }

            HStack {
                Image(systemName: "calendar").foregroundColor(RM.textMuted)
                Text(DateFormatter.rmShortDateTime.string(from: wall.wrappedValue.approval.date))
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(RM.textSub)
                Spacer()
                StatusBadge(text: wall.wrappedValue.approval.decision.label, color: wall.wrappedValue.approval.decision.color)
            }
            .padding(.horizontal, 4)

            PrimaryButton(title: "Approve Wall", icon: "checkmark.seal.fill") {
                var w = wall.wrappedValue
                w.approval.decision = .approved
                w.approval.date = Date()
                w.status = .approved
                store.updateWall(w); flash("Wall approved")
            }
            SecondaryButton(title: "Keep Signoff", icon: "tray.and.arrow.down") {
                var w = wall.wrappedValue; w.approval.date = Date(); store.updateWall(w); flash("Signoff kept")
            }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.approval = Approval(); store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: ReportsExportScreen(initialWallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "doc.text"); Text("Reports").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - Signature pad (finger draw)

struct SignaturePad: View {
    @Binding var strokes: [SignatureStroke]
    @State private var current: [CGPointCodable] = []

    var body: some View {
        GeometryReader { _ in
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(RM.cardWhite)
                RoundedRectangle(cornerRadius: 14).stroke(RM.cardBorder, lineWidth: 1)
                // committed strokes
                ForEach(Array(strokes.enumerated()), id: \.offset) { _, stroke in
                    StrokeShape(points: stroke.points).stroke(RM.textMain, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
                // live stroke
                StrokeShape(points: current).stroke(RM.primary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                if strokes.isEmpty && current.isEmpty {
                    Text("Sign here").font(.system(size: 14)).foregroundColor(RM.textMuted)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in current.append(CGPointCodable(v.location)) }
                    .onEnded { _ in
                        if !current.isEmpty { strokes.append(SignatureStroke(points: current)); current = [] }
                    }
            )
        }
    }
}

struct StrokeShape: Shape {
    let points: [CGPointCodable]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first.cg)
        for p in points.dropFirst() { path.addLine(to: p.cg) }
        return path
    }
}
