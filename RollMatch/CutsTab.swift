//
//  CutsTab.swift
//  RollMatch
//
//  Cuts hub + screens 06 Drop Plan, 13 Layout Board, 14 Hang Sequence,
//  15 Adhesion & Defect Note.
//

import SwiftUI

// MARK: - Cuts hub

struct CutsHubView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedWallID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Cuts", subtitle: "Drop list, layout & sequence", icon: "scissors")
                            .padding(.horizontal, 16).padding(.top, 8)

                        if store.walls.isEmpty {
                            NoWallState()
                        } else {
                            WallSelectorBar(selectedWallID: $selectedWallID)
                            if let id = activeID {
                                cutSummary(id)
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

    private func cutSummary(_ id: UUID) -> some View {
        let wall = store.wall(by: id) ?? Wall()
        let plans = MatchEngine.stripPlans(for: wall)
        let totalCut = plans.reduce(0) { $0 + $1.cutLength }
        return HStack(spacing: 10) {
            MetricTile(value: "\(plans.count)", label: "Strips", color: RM.strip, icon: "rectangle.split.3x1")
            MetricTile(value: MatchEngine.lengthString(totalCut, unit: .metric), label: "Total cut", color: RM.primary, icon: "scissors")
            MetricTile(value: "\(wall.defects.count)", label: "Defects", color: RM.defect, icon: "exclamationmark.triangle")
        }
        .padding(.horizontal, 16)
    }

    private func links(_ id: UUID) -> some View {
        VStack(spacing: 10) {
            NavigationLink(destination: DropPlanScreen(wallID: id)) {
                NavRow(number: "06", title: "Drop Plan", subtitle: "Cut each strip with the right offset", icon: "list.number", accent: RM.primary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: LayoutBoardScreen(wallID: id)) {
                NavRow(number: "13", title: "Layout Board", subtitle: "Place strips and set seam positions", icon: "square.grid.2x2", accent: RM.strip)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: HangSequenceScreen(wallID: id)) {
                NavRow(number: "14", title: "Hang Sequence", subtitle: "Hang in order, hide the last seam", icon: "arrow.right.to.line", accent: RM.secondary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: DefectNoteScreen(wallID: id)) {
                NavRow(number: "15", title: "Adhesion & Defect Note", subtitle: "Log seam issues with photo & severity", icon: "exclamationmark.bubble", accent: RM.defect)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 06 Drop Plan

struct DropPlanScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var built = false
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let plans = MatchEngine.stripPlans(for: wall.wrappedValue)
        return DetailScaffold("Drop Plan",
                              caption: "Cut each strip with the right repeat offset.") {
            RMCard(light: false) {
                HStack {
                    Image(systemName: "scissors").foregroundColor(RM.secondary)
                    Text("\(plans.count) strips • \(wall.wrappedValue.pattern.matchType.label)")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(RM.textMain)
                    Spacer()
                    Text("first strip highlighted").font(.system(size: 11)).foregroundColor(RM.textMuted)
                }
            }

            ForEach(plans) { p in
                cutRow(p)
            }

            PrimaryButton(title: "Build Drop List", icon: "list.number") {
                withAnimation { built = true }; flash("Cut list built")
            }
            SecondaryButton(title: "Keep Plan", icon: "tray.and.arrow.down") { flash("Plan kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") { flash("Nothing to clear — list is live") }
                NavigationLink(destination: PatternCenteringScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "align.horizontal.center"); Text("Centering").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func cutRow(_ p: StripPlan) -> some View {
        RMCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(p.isFirst ? RM.primaryGradient : LinearGradient(colors: [RM.strip, RM.strip.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 60)
                    Text("\(p.index)").font(.system(size: 20, weight: .heavy)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cut \(MatchEngine.lengthString(p.cutLength, unit: settings.units))")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                    HStack(spacing: 10) {
                        tag("shift \(MatchEngine.shortLength(p.repeatShift, unit: settings.units))", RM.seam)
                        tag("trim \(MatchEngine.shortLength(p.trimTop, unit: settings.units))/\(MatchEngine.shortLength(p.trimBottom, unit: settings.units))", RM.strip)
                    }
                    if p.isFirst {
                        Text("Start here — aligns to the focal point")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(RM.primary)
                    }
                }
                Spacer()
            }
        }
    }
    private func tag(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 11, weight: .heavy)).foregroundColor(c)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(c.opacity(0.16)))
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 13 Layout Board

struct LayoutBoardScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var snap = true
    @State private var seamPos: Double = 0.5
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let strips = MatchEngine.stripsNeeded(wallWidth: wall.wrappedValue.width, rollWidth: wall.wrappedValue.roll.width)
        return DetailScaffold("Layout Board",
                              caption: "Place strips across walls and set seam positions.") {
            board(wall.wrappedValue, strips: strips)
                .modifier(CardWrap())

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Strips placed").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textSub)
                        Spacer()
                        Text("\(strips)").font(.system(size: 18, weight: .heavy)).foregroundColor(RM.primary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SEAM POSITION  •  \(Int(seamPos * 100))%").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: $seamPos, in: 0...1).accentColor(RM.primary)
                        Text("Drag seams toward shadowed / low-traffic spots.").font(.system(size: 12)).foregroundColor(RM.textMuted)
                    }
                    Toggle(isOn: $snap) {
                        Text("Snap strips to roll width").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                    HStack(spacing: 12) {
                        RMNumberField(title: "Canvas Width", value: wall.width, unit: "m")
                        RMNumberField(title: "Roll Width", value: wall.roll.width, unit: "m")
                    }
                }
            }

            PrimaryButton(title: "Place Strips", icon: "square.grid.2x2") { flash("\(strips) strips placed") }
            SecondaryButton(title: "Keep Layout", icon: "tray.and.arrow.down") { flash("Layout kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") { seamPos = 0.5; snap = true; flash("Reset") }
                NavigationLink(destination: HangSequenceScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "arrow.right.to.line"); Text("Sequence").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func board(_ wall: Wall, strips: Int) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let stripW = w / CGFloat(max(strips, 1))
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8).fill(RM.bgSoft)
                HStack(spacing: 0) {
                    ForEach(0..<max(strips, 1), id: \.self) { i in
                        ZStack {
                            Rectangle().fill(LinearGradient(colors: [RM.strip.opacity(0.9), RM.strip.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            Text("\(i+1)").font(.system(size: 12, weight: .heavy)).foregroundColor(.white)
                            HStack { Spacer(); Rectangle().fill(RM.seam).frame(width: snap ? 2 : 1) }
                        }
                        .frame(width: stripW)
                    }
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                // highlighted seam position
                Rectangle().fill(RM.secondary).frame(width: 3, height: h)
                    .offset(x: w * CGFloat(seamPos) - 1.5)
            }
        }
        .frame(height: 150)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 14 Hang Sequence

struct HangSequenceScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""
    private let starts = ["Left of focal point", "Centre out", "Left corner", "Right corner"]
    private let directions = ["Left → Right", "Right → Left", "Centre → Out"]
    private let finishes = ["Behind door", "Darkest corner", "Least visible wall"]

    var body: some View {
        let wall = store.wallBinding(wallID)
        let strips = MatchEngine.stripsNeeded(wallWidth: wall.wrappedValue.width, rollWidth: wall.wrappedValue.roll.width)
        return DetailScaffold("Hang Sequence",
                              caption: "Hang in the right order, hide the last seam.") {
            sequenceDiagram(strips: strips, direction: wall.wrappedValue.hangDirection)
                .modifier(CardWrap())

            RMCard {
                VStack(alignment: .leading, spacing: 14) {
                    pickerBlock("Start Wall", starts, wall.startWall)
                    pickerBlock("Direction", directions, wall.hangDirection)
                    pickerBlock("Finish Corner", finishes, wall.finishCorner)
                }
            }

            RMCard(light: false) {
                HStack {
                    Image(systemName: "eye.slash").foregroundColor(RM.secondary)
                    Text("The final mismatched seam should land at \(wall.wrappedValue.finishCorner.lowercased()).")
                        .font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
            }

            PrimaryButton(title: "Set Sequence", icon: "arrow.right.to.line") { flash("Sequence set") }
            SecondaryButton(title: "Keep Sequence", icon: "tray.and.arrow.down") { flash("Sequence kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue
                    w.startWall = starts[0]; w.hangDirection = directions[0]; w.finishCorner = finishes[0]
                    store.updateWall(w); flash("Reset")
                }
                NavigationLink(destination: CostEstimateScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "dollarsign.circle"); Text("Cost").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func pickerBlock(_ title: String, _ options: [String], _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
            FlowChips(items: options) { o in
                RMChip(label: o, selected: binding.wrappedValue == o) { binding.wrappedValue = o }
            }
        }
    }

    private func sequenceDiagram(strips: Int, direction: String) -> some View {
        let reversed = direction.contains("Right →")
        let order = Array(1...max(strips, 1))
        let display = reversed ? order.reversed().map { $0 } : order
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(display.enumerated()), id: \.offset) { idx, num in
                    HStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(idx == 0 ? RM.primaryGradient : LinearGradient(colors: [RM.strip, RM.strip.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 40, height: 64)
                            Text("\(num)").font(.system(size: 16, weight: .heavy)).foregroundColor(.white)
                        }
                        if idx < display.count - 1 {
                            Image(systemName: "arrow.right").foregroundColor(RM.secondary).font(.system(size: 12, weight: .bold))
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 90)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 15 Adhesion & Defect Note

struct DefectNoteScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var draft = Defect()
    @State private var draftPhoto: UIImage?
    @State private var showPicker = false
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Adhesion & Defect Note",
                              caption: "Log seam issues with a photo and severity.") {
            // existing defects
            if !wall.wrappedValue.defects.isEmpty {
                ForEach(wall.wrappedValue.defects) { d in
                    defectCard(d) {
                        var w = wall.wrappedValue; w.defects.removeAll { $0.id == d.id }; store.updateWall(w)
                    }
                }
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("NEW DEFECT").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    // photo
                    Button(action: { showPicker = true }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue).frame(height: 120)
                            if let img = draftPhoto {
                                Image(uiImage: img).resizable().scaledToFill().frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "camera").font(.system(size: 26)).foregroundColor(RM.textMuted)
                                    Text("Add Photo").font(.system(size: 13, weight: .bold)).foregroundColor(RM.textSub)
                                }
                            }
                        }
                    }
                    EnumChips(items: DefectType.allCases, selection: $draft.type, label: { $0.label }, icon: { $0.icon })
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SEVERITY  •  \(draft.severity)/5").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { s in
                                Button(action: { draft.severity = s }) {
                                    Image(systemName: s <= draft.severity ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                        .font(.system(size: 22))
                                        .foregroundColor(s <= draft.severity ? severityColor(draft.severity) : RM.textMuted)
                                }
                            }
                        }
                    }
                    RMTextField(title: "Fix Action", text: $draft.fixAction, placeholder: "Re-roll seam, inject adhesive")
                }
            }

            PrimaryButton(title: "Pin Defect", icon: "mappin") {
                var d = draft
                d.photo = draftPhoto?.rmData()
                d.date = Date()
                var w = wall.wrappedValue; w.defects.insert(d, at: 0); store.updateWall(w)
                draft = Defect(); draftPhoto = nil; flash("Defect pinned")
            }
            SecondaryButton(title: "Keep Note", icon: "tray.and.arrow.down") { flash("Note kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") { draft = Defect(); draftPhoto = nil; flash("Cleared") }
                NavigationLink(destination: WallDetailScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "rectangle.on.rectangle"); Text("Wall Detail").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(source: .library) { img in draftPhoto = img }
        }
        .toast($toast, message: toastMsg)
    }

    private func defectCard(_ d: Defect, onDelete: @escaping () -> Void) -> some View {
        RMCard {
            HStack(spacing: 12) {
                if let data = d.photo, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: d.type.icon).font(.system(size: 24)).foregroundColor(RM.strip).frame(width: 56, height: 56)
                        .background(RoundedRectangle(cornerRadius: 10).fill(RM.cardBlue))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(d.type.label).font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                    Text(d.fixAction.isEmpty ? "No action yet" : d.fixAction).font(.system(size: 12)).foregroundColor(RM.textSub).lineLimit(1)
                    StatusBadge(text: "Severity \(d.severity)", color: severityColor(d.severity))
                }
                Spacer()
                Button(action: onDelete) { Image(systemName: "trash").foregroundColor(RM.defect) }
            }
        }
    }
    private func severityColor(_ s: Int) -> Color {
        switch s { case 1, 2: return RM.ok; case 3: return RM.warn; default: return RM.defect }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}
