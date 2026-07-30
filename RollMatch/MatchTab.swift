//
//  MatchTab.swift
//  RollMatch
//
//  Match hub + screens 03 Pattern Setup, 04 Repeat Match Preview, 07 Pattern Centering,
//  08 Openings & Partial Drops, 09 Corner Strategy.
//

import SwiftUI

// MARK: - Match hub

struct MatchHubView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedWallID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Match", subtitle: "Pattern, preview & centering", icon: "square.grid.3x3.topleft.filled")
                            .padding(.horizontal, 16).padding(.top, 8)

                        if store.walls.isEmpty {
                            NoWallState()
                        } else {
                            WallSelectorBar(selectedWallID: $selectedWallID)
                            if let id = activeID {
                                preview(id)
                                links(id)
                            }
                        }
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var activeID: UUID? { selectedWallID ?? store.walls.first?.id }

    private func preview(_ id: UUID) -> some View {
        let wall = store.wall(by: id) ?? Wall()
        return StripLayoutView(wall: wall, height: 140)
            .modifier(CardWrap())
            .padding(.horizontal, 16)
    }

    private func links(_ id: UUID) -> some View {
        VStack(spacing: 10) {
            NavigationLink(destination: PatternSetupScreen(wallID: id)) {
                NavRow(number: "03", title: "Pattern Setup", subtitle: "Confirm the match type and repeat height", icon: "square.grid.3x3", accent: RM.primary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: RepeatMatchScreen(wallID: id)) {
                NavRow(number: "04", title: "Repeat Match Preview", subtitle: "Preview how strips align top to bottom", icon: "square.grid.3x3.topleft.filled", accent: RM.strip)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: PatternCenteringScreen(wallID: id)) {
                NavRow(number: "07", title: "Pattern Centering", subtitle: "Center the motif and balance side cuts", icon: "align.horizontal.center", accent: RM.secondary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: OpeningsScreen(wallID: id)) {
                NavRow(number: "08", title: "Openings & Partial Drops", subtitle: "Subtract openings, keep strips above/below", icon: "rectangle.split.2x2", accent: RM.warn)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: CornerStrategyScreen(wallID: id)) {
                NavRow(number: "09", title: "Corner Strategy", subtitle: "Handle internal and external corners", icon: "arrow.turn.down.right", accent: RM.ok)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 03 Pattern Setup

struct PatternSetupScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Pattern Setup",
                              caption: "Confirm the match type and the repeat height.") {
            StripLayoutView(wall: wall.wrappedValue, height: 130).modifier(CardWrap())

            RMCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("MATCH TYPE").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    ForEach(MatchType.allCases) { t in
                        Button(action: { var w = wall.wrappedValue; w.pattern.matchType = t; store.updateWall(w); settings.haptic(.light) }) {
                            HStack(spacing: 12) {
                                Image(systemName: t.icon).font(.system(size: 20)).foregroundColor(wall.wrappedValue.pattern.matchType == t ? RM.primary : RM.textMuted).frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.label).font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                                    Text(t.detail).font(.system(size: 12)).foregroundColor(RM.textSub)
                                }
                                Spacer()
                                Image(systemName: wall.wrappedValue.pattern.matchType == t ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(wall.wrappedValue.pattern.matchType == t ? RM.primary : RM.textMuted)
                            }
                            .padding(.vertical, 8)
                        }
                        if t != MatchType.allCases.last { Divider().background(RM.cardBorder) }
                    }
                }
            }

            RMCard {
                VStack(spacing: 12) {
                    RMNumberField(title: "Repeat Height", value: wall.pattern.repeatHeight, unit: "m", icon: "ruler")
                    if wall.wrappedValue.pattern.matchType == .drop {
                        RMNumberField(title: "Drop Offset", value: wall.pattern.dropOffset, unit: "m", icon: "arrow.down.right")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOTIF SCALE  •  \(String(format: "%.1f×", wall.wrappedValue.pattern.motifScale))").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: wall.pattern.motifScale, in: 0.5...2.0, step: 0.1).accentColor(RM.primary)
                    }
                }
            }

            PrimaryButton(title: "Apply Pattern", icon: "checkmark") {
                if wall.wrappedValue.pattern.matchType == .drop {
                    var w = wall.wrappedValue
                    if w.pattern.dropOffset <= 0 { w.pattern.dropOffset = w.pattern.repeatHeight / 2 }
                    store.updateWall(w)
                }
                flash("Pattern applied")
            }
            SecondaryButton(title: "Keep Pattern", icon: "tray.and.arrow.down") { flash("Pattern kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.pattern = PatternSpec(); store.updateWall(w); flash("Reset")
                }
                NavigationLink(destination: RepeatMatchScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "square.grid.3x3.topleft.filled"); Text("Repeat Match").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 04 Repeat Match Preview

struct RepeatMatchScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Repeat Match Preview",
                              caption: "Preview how strips align top to bottom.") {
            // big preview with ceiling/skirting lines
            ZStack(alignment: .top) {
                StripLayoutView(wall: wall.wrappedValue, height: 260)
            }
            .modifier(CardWrap())

            HStack(spacing: 14) {
                lineTag("Ceiling", RM.secondary)
                lineTag("Skirting", RM.secondary.opacity(0.7))
                lineTag("Seam", RM.seam)
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FIRST STRIP SHIFT  •  \(MatchEngine.shortLength(wall.wrappedValue.centering.firstStripShift, unit: settings.units))")
                            .font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: wall.centering.firstStripShift, in: -0.5...0.5, step: 0.01).accentColor(RM.primary)
                    }
                    HStack(spacing: 12) {
                        RMNumberField(title: "Ceiling Trim", value: wall.trimAllowance, unit: "m", icon: "arrow.up.to.line")
                        RMNumberField(title: "Repeat Offset", value: wall.repeatOffset, unit: "m", icon: "arrow.down.to.line")
                    }
                }
            }

            RMCard(light: false) {
                HStack {
                    Image(systemName: "eye").foregroundColor(RM.strip)
                    Text("Shift the first strip to choose where the motif lands at the ceiling and floor — before buying.")
                        .font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
            }

            PrimaryButton(title: "Recalc Match", icon: "arrow.triangle.2.circlepath") { flash("Preview updated") }
            HStack(spacing: 12) {
                SecondaryButton(title: "Keep Preview", icon: "tray.and.arrow.down") { flash("Preview kept") }
                Button(action: { var w = wall.wrappedValue; w.centering.firstStripShift = 0; store.updateWall(w); flash("Shift reset") }) {
                    HStack(spacing: 6) { Image(systemName: "arrow.counterclockwise"); Text("Adjust Shift").font(.system(size: 15, weight: .bold)) }
                        .foregroundColor(RM.strip).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).stroke(RM.strip.opacity(0.6), lineWidth: 1.4))
                }
            }
            NavigationLink(destination: RollCalculatorScreen(wallID: wallID)) {
                HStack(spacing: 6) { Image(systemName: "function"); Text("Open Roll Calculator").font(.system(size: 15, weight: .bold)) }
                    .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RM.strip).cornerRadius(14)
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func lineTag(_ t: String, _ c: Color) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(c).frame(width: 16, height: 3)
            Text(t).font(.system(size: 12, weight: .bold)).foregroundColor(RM.textMuted)
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 07 Pattern Centering

struct PatternCenteringScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let c = MatchEngine.centerResult(for: wall.wrappedValue)
        return DetailScaffold("Pattern Centering",
                              caption: "Center the motif and balance the side cuts.") {
            centeringDiagram(wall.wrappedValue, c)
                .modifier(CardWrap())

            HStack(spacing: 10) {
                MetricTile(value: "\(c.fullStrips)", label: "Full strips", color: RM.strip, icon: "rectangle.split.3x1")
                MetricTile(value: MatchEngine.shortLength(c.leftCut, unit: settings.units), label: "Left cut", color: RM.primary, icon: "arrow.left")
                MetricTile(value: MatchEngine.shortLength(c.rightCut, unit: settings.units), label: "Right cut", color: RM.primary, icon: "arrow.right")
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FOCAL POINT  •  \(Int(wall.wrappedValue.centering.focalPoint * 100))%").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: wall.centering.focalPoint, in: 0...1).accentColor(RM.primary)
                    }
                    Toggle(isOn: wall.centering.centerMotif) {
                        Text("Center motif on focal point").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                    Text(wall.wrappedValue.centering.centerMotif
                         ? "Side cuts are balanced so the motif sits dead-centre on your fireplace / TV."
                         : "Strips start from the left; the off-cut goes to the right corner.")
                        .font(.system(size: 12)).foregroundColor(RM.textMuted)
                }
            }

            PrimaryButton(title: "Center Pattern", icon: "align.horizontal.center") {
                var w = wall.wrappedValue; w.centering.centerMotif = true; store.updateWall(w); flash("Pattern centred")
            }
            SecondaryButton(title: "Keep Centering", icon: "tray.and.arrow.down") { flash("Centering kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.centering = Centering(); store.updateWall(w); flash("Reset")
                }
                NavigationLink(destination: OpeningsScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "rectangle.split.2x2"); Text("Openings").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func centeringDiagram(_ wall: Wall, _ c: MatchEngine.CenterResult) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .leading) {
                // strips
                HStack(spacing: 2) {
                    ForEach(0..<max(c.fullStrips + 2, 1), id: \.self) { i in
                        Rectangle()
                            .fill(LinearGradient(colors: [RM.strip, RM.strip.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                            .overlay(Image(systemName: "seal.fill").foregroundColor(RM.secondary).font(.system(size: 14)))
                            .opacity(i == 0 || i == c.fullStrips + 1 ? 0.5 : 1)
                    }
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                // focal axis
                Rectangle().fill(RM.primary).frame(width: 2, height: h)
                    .offset(x: w * CGFloat(wall.centering.focalPoint) - 1)
                Image(systemName: "scope").foregroundColor(RM.primary).font(.system(size: 22))
                    .position(x: w * CGFloat(wall.centering.focalPoint), y: 14)
            }
        }
        .frame(height: 150)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 08 Openings & Partial Drops

struct OpeningsScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var draft = Opening()
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let o = MatchEngine.openingResult(for: wall.wrappedValue)
        return DetailScaffold("Openings & Partial Drops",
                              caption: "Subtract openings but keep strips above and below.") {
            WallSchematicView(wall: wall.wrappedValue, height: 150).modifier(CardWrap())

            HStack(spacing: 10) {
                MetricTile(value: String(format: "%.1f", o.netArea), label: "Net m²", color: RM.ok, icon: "square.dashed")
                MetricTile(value: String(format: "%.1f", o.openingsArea), label: "Openings m²", color: RM.warn, icon: "rectangle.split.2x2")
                MetricTile(value: "\(o.partialStripsKept)", label: "Partials kept", color: RM.strip, icon: "rectangle.portrait.on.rectangle.portrait")
            }

            // existing openings
            if !wall.wrappedValue.openings.isEmpty {
                RMCard {
                    VStack(spacing: 8) {
                        ForEach(wall.wrappedValue.openings) { op in
                            HStack(spacing: 12) {
                                Image(systemName: op.type.icon).foregroundColor(RM.strip).frame(width: 26)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(op.type.label).font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
                                    Text("\(MatchEngine.lengthString(op.width, unit: settings.units)) × \(MatchEngine.lengthString(op.height, unit: settings.units))" + (op.keepPattern ? " • keep pattern" : ""))
                                        .font(.system(size: 11.5)).foregroundColor(RM.textSub)
                                }
                                Spacer()
                                Button(action: {
                                    var w = wall.wrappedValue; w.openings.removeAll { $0.id == op.id }; store.updateWall(w)
                                }) { Image(systemName: "trash").foregroundColor(RM.defect) }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            // add new
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ADD OPENING").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    EnumChips(items: OpeningType.allCases, selection: $draft.type, label: { $0.label }, icon: { $0.icon })
                    HStack(spacing: 12) {
                        RMNumberField(title: "Width", value: $draft.width, unit: "m")
                        RMNumberField(title: "Height", value: $draft.height, unit: "m")
                    }
                    Toggle(isOn: $draft.keepPattern) {
                        Text("Keep pattern above & below").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                }
            }

            PrimaryButton(title: "Add Opening", icon: "plus") {
                var w = wall.wrappedValue; w.openings.append(draft); store.updateWall(w)
                draft = Opening(); flash("Opening added")
            }
            SecondaryButton(title: "Keep Opening", icon: "tray.and.arrow.down") { flash("Kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear All", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.openings = []; store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: CornerStrategyScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "arrow.turn.down.right"); Text("Corners").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 09 Corner Strategy

struct CornerStrategyScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var draft = CornerPlan()
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Corner Strategy",
                              caption: "Handle internal and external corners cleanly.") {
            cornerDiagram(draft).modifier(CardWrap())

            if !wall.wrappedValue.corners.isEmpty {
                RMCard {
                    VStack(spacing: 8) {
                        ForEach(wall.wrappedValue.corners) { cp in
                            HStack(spacing: 12) {
                                Image(systemName: cp.type.icon).foregroundColor(RM.strip).frame(width: 26)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cp.type.label + " corner").font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
                                    Text("Overlap \(MatchEngine.shortLength(cp.wrapOverlap, unit: settings.units))" + (cp.newPlumbLine ? " • new plumb line" : ""))
                                        .font(.system(size: 11.5)).foregroundColor(RM.textSub)
                                }
                                Spacer()
                                Button(action: { var w = wall.wrappedValue; w.corners.removeAll { $0.id == cp.id }; store.updateWall(w) }) {
                                    Image(systemName: "trash").foregroundColor(RM.defect)
                                }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CORNER TYPE").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    EnumChips(items: CornerType.allCases, selection: $draft.type, label: { $0.label }, icon: { $0.icon })
                    RMNumberField(title: "Wrap Overlap", value: $draft.wrapOverlap, unit: "m", icon: "arrow.left.and.right")
                    Toggle(isOn: $draft.newPlumbLine) {
                        Text("Start a new plumb line on next wall").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                    Text("Never wrap a full strip around a corner — walls are rarely truly square, so the pattern would lean.")
                        .font(.system(size: 12)).foregroundColor(RM.textMuted)
                }
            }

            PrimaryButton(title: "Set Corner", icon: "plus") {
                var w = wall.wrappedValue; w.corners.append(draft); store.updateWall(w); draft = CornerPlan(); flash("Corner set")
            }
            SecondaryButton(title: "Keep Corner", icon: "tray.and.arrow.down") { flash("Kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear All", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.corners = []; store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: SurfacePrepScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "square.stack.3d.up"); Text("Surface Prep").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func cornerDiagram(_ cp: CornerPlan) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // two walls meeting (plan view)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.15, y: h * 0.3))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.3))
                    if cp.type == .internalCorner {
                        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.85))
                    } else {
                        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.85))
                    }
                }
                .stroke(RM.strip, lineWidth: 3)
                // wrap overlap strip
                Rectangle().fill(RM.seam).frame(width: 3, height: h * 0.2)
                    .position(x: w * 0.5, y: h * 0.4)
                Text(cp.type == .internalCorner ? "Internal — overlap 2–3 cm" : "External — wrap & re-plumb")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(RM.secondary)
                    .position(x: w * 0.5, y: h * 0.95)
            }
        }
        .frame(height: 140)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}
