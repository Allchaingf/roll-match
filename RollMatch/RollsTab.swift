//
//  RollsTab.swift
//  RollMatch
//
//  Rolls hub + screens 05 Roll Calculator, 10 Surface Prep, 11 Paste & Soak,
//  12 Batch & Shade Check, 16 Cost Estimate.
//

import SwiftUI

// MARK: - Rolls hub

struct RollsHubView: View {
    @EnvironmentObject var store: AppStore
    @Binding var selectedWallID: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Rolls", subtitle: "Count, prep, paste & batch", icon: "function")
                            .padding(.horizontal, 16).padding(.top, 8)

                        if store.walls.isEmpty {
                            NoWallState()
                        } else {
                            WallSelectorBar(selectedWallID: $selectedWallID)
                            if let id = activeID {
                                liveSummary(id)
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

    private func liveSummary(_ id: UUID) -> some View {
        let wall = store.wall(by: id) ?? Wall()
        let r = MatchEngine.rollResult(for: wall)
        return HStack(spacing: 10) {
            MetricTile(value: "\(r.rollsTotal)", label: "Rolls total", color: RM.primary, icon: "shippingbox.fill")
            MetricTile(value: "\(r.stripsPerRoll)", label: "Strips / roll", color: RM.strip, icon: "rectangle.split.3x1")
            MetricTile(value: String(format: "%.0f%%", r.patternWastePercent), label: "Pattern waste", color: RM.warn, icon: "scissors")
        }
        .padding(.horizontal, 16)
    }

    private func links(_ id: UUID) -> some View {
        VStack(spacing: 10) {
            NavigationLink(destination: RollCalculatorScreen(wallID: id)) {
                NavRow(number: "05", title: "Roll Calculator", subtitle: "Count rolls including pattern waste", icon: "function", accent: RM.primary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: SurfacePrepScreen(wallID: id)) {
                NavRow(number: "10", title: "Surface Prep", subtitle: "Prepare the wall before the first strip", icon: "square.stack.3d.up", accent: RM.strip)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: PasteSoakScreen(wallID: id)) {
                NavRow(number: "11", title: "Paste & Soak", subtitle: "Pick paste and respect the soak time", icon: "timer", accent: RM.secondary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: BatchShadeScreen(wallID: id)) {
                NavRow(number: "12", title: "Batch & Shade Check", subtitle: "Check the batch number and shade match", icon: "shippingbox", accent: RM.warn)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: CostEstimateScreen(wallID: id)) {
                NavRow(number: "16", title: "Cost Estimate", subtitle: "Add up rolls, paste and prep materials", icon: "dollarsign.circle", accent: RM.ok)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 05 Roll Calculator

struct RollCalculatorScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let r = MatchEngine.rollResult(for: wall.wrappedValue)
        return DetailScaffold("Roll Calculator",
                              caption: "Count rolls including pattern waste.") {
            // Result hero
            RMCard {
                VStack(spacing: 14) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(r.rollsTotal)").font(.system(size: 52, weight: .heavy)).foregroundColor(RM.primary)
                        Text("rolls").font(.system(size: 18, weight: .bold)).foregroundColor(RM.textSub)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(r.rollsForPattern) for pattern").font(.system(size: 12, weight: .bold)).foregroundColor(RM.textSub)
                            Text("+\(Int(r.extraPercent))% safety").font(.system(size: 12, weight: .bold)).foregroundColor(RM.textMuted)
                        }
                    }
                    HStack(spacing: 10) {
                        miniResult("\(r.stripsNeeded)", "Strips needed")
                        miniResult("\(r.stripsPerRoll)", "Strips / roll")
                        miniResult(MatchEngine.lengthString(r.effectiveCutLength, unit: settings.units), "Cut length")
                    }
                }
            }

            // Separate waste gauges
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WASTE BREAKDOWN").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    wasteRow("Pattern fitting waste", r.patternWastePercent, RM.warn)
                    wasteRow("Generic safety extra", r.extraPercent, RM.primary)
                    Text("Pattern waste comes from matching the repeat — it is tracked apart from your safety stock.")
                        .font(.system(size: 12)).foregroundColor(RM.textMuted)
                }
            }

            // Inputs
            RMCard {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        RMNumberField(title: "Wall Height", value: wall.height, unit: "m", icon: "arrow.up.and.down")
                        RMNumberField(title: "Repeat Height", value: wall.pattern.repeatHeight, unit: "m", icon: "ruler")
                    }
                    HStack(spacing: 12) {
                        RMNumberField(title: "Roll Length", value: wall.roll.length, unit: "m", icon: "scroll")
                        RMNumberField(title: "Roll Width", value: wall.roll.width, unit: "m", icon: "arrow.left.and.right")
                    }
                    RMNumberField(title: "Trim Allowance", value: wall.trimAllowance, unit: "m", icon: "scissors")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EXTRA SAFETY  •  \(Int(wall.wrappedValue.extraPercent))%")
                            .font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: wall.extraPercent, in: 0...30, step: 1).accentColor(RM.primary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MATCH TYPE").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        EnumChips(items: MatchType.allCases, selection: wall.pattern.matchType, label: { $0.shortLabel }, icon: { $0.icon })
                    }
                }
            }

            PrimaryButton(title: "Calculate Rolls", icon: "function") { flash("\(r.rollsTotal) rolls needed") }
            SecondaryButton(title: "Keep Calc", icon: "tray.and.arrow.down") { flash("Calc saved") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.extraPercent = 10; w.trimAllowance = 0.10; store.updateWall(w); flash("Reset")
                }
                NavigationLink(destination: DropPlanScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "list.number"); Text("Drop Plan").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func miniResult(_ v: String, _ l: String) -> some View {
        VStack(spacing: 3) {
            Text(v).font(.system(size: 16, weight: .heavy)).foregroundColor(RM.textMain).minimumScaleFactor(0.6).lineLimit(1)
            Text(l.uppercased()).font(.system(size: 9, weight: .heavy)).foregroundColor(RM.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue))
    }
    private func wasteRow(_ l: String, _ pct: Double, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(l).font(.system(size: 13, weight: .semibold)).foregroundColor(RM.textSub)
                Spacer()
                Text(String(format: "%.1f%%", pct)).font(.system(size: 14, weight: .heavy)).foregroundColor(c)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(RM.cardBorder).frame(height: 8)
                    Capsule().fill(c).frame(width: min(1, pct / 40) * geo.size.width, height: 8)
                }
            }.frame(height: 8)
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 10 Surface Prep

struct SurfacePrepScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let prep = wall.wrappedValue.prep
        let ready = prep.peelTestOK && (prep.sizingPrimer || prep.liningPaper)
        return DetailScaffold("Surface Prep",
                              caption: "Prepare the wall before the first strip.") {
            // gate banner
            RMCard(light: false) {
                HStack(spacing: 12) {
                    Image(systemName: ready ? "checkmark.shield.fill" : "exclamationmark.shield")
                        .font(.system(size: 26)).foregroundColor(ready ? RM.ok : RM.warn)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ready ? "Base looks ready" : "Prep not complete")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                        Text(ready ? "Peel test passed and a base coat is set." : "Pass the peel test and prime/line first.")
                            .font(.system(size: 12)).foregroundColor(RM.textSub)
                    }
                    Spacer()
                }
            }

            RMCard {
                VStack(spacing: 4) {
                    checkToggle("Lining Paper", "doc.plaintext", wall.prep.liningPaper)
                    checkToggle("Sizing / Primer", "paintbrush", wall.prep.sizingPrimer)
                    checkToggle("Peel Test OK", "hand.draw", wall.prep.peelTestOK)
                    checkToggle("Repairs Done", "bandage", wall.prep.repairsDone)
                }
            }
            RMCard {
                RMTextField(title: "Prep Notes", text: wall.prep.notes, placeholder: "Filled two nail holes, sanded edge")
            }

            PrimaryButton(title: "Mark Prepped", icon: "checkmark.seal") {
                var w = wall.wrappedValue; w.prep.isPrepped = true; store.updateWall(w); flash("Marked prepped")
            }
            SecondaryButton(title: "Keep Prep", icon: "tray.and.arrow.down") { flash("Prep kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.prep = SurfacePrep(); store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: PasteSoakScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "timer"); Text("Paste & Soak").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func checkToggle(_ label: String, _ icon: String, _ binding: Binding<Bool>) -> some View {
        Button(action: { binding.wrappedValue.toggle(); settings.haptic(.light) }) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(RM.strip).frame(width: 26)
                Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(RM.textMain)
                Spacer()
                Image(systemName: binding.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundColor(binding.wrappedValue ? RM.ok : RM.textMuted)
            }
            .padding(.vertical, 9)
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 11 Paste & Soak

struct PasteSoakScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notifier: NotificationManager
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""
    private let pasteTypes = ["Ready-mixed", "Powder (all-purpose)", "Heavy-duty", "Border / overlap"]

    var body: some View {
        let wall = store.wallBinding(wallID)
        return DetailScaffold("Paste & Soak",
                              caption: "Pick paste and respect the soak time.") {
            RMCard {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASTE TYPE").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        FlowChips(items: pasteTypes) { t in
                            RMChip(label: t, selected: wall.wrappedValue.paste.pasteType == t) {
                                var w = wall.wrappedValue; w.paste.pasteType = t; store.updateWall(w)
                            }
                        }
                    }
                    RMIntStepper(title: "Soak Time (min)", value: wall.paste.soakMinutes, range: 0...30)
                    Toggle(isOn: wall.paste.pasteTheWall) {
                        Text("Paste the wall (not the paper)").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                    Toggle(isOn: wall.paste.booking) {
                        Text("Booking (fold paste-to-paste)").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                }
            }

            RMCard(light: false) {
                HStack {
                    Image(systemName: "info.circle").foregroundColor(RM.strip)
                    Text("Equal soak per strip avoids shrinkage and seam gaps. The timer fires a real reminder.")
                        .font(.system(size: 12.5)).foregroundColor(RM.textSub)
                }
            }

            PrimaryButton(title: "Start Soak Timer", icon: "timer") { startTimer(wall.wrappedValue) }
            SecondaryButton(title: "Keep Paste", icon: "tray.and.arrow.down") { flash("Paste kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.paste = PasteSoak(); store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: BatchShadeScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "shippingbox"); Text("Batch").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func startTimer(_ wall: Wall) {
        let mins = wall.paste.soakMinutes
        notifier.requestAuthorization { granted in
            if granted {
                let id = notifier.scheduleSoak(minutes: mins, wall: wall.title)
                var r = ReminderItem(kind: .soak,
                                     title: "Soak complete — \(wall.title)",
                                     fireDate: Date().addingTimeInterval(TimeInterval(max(mins,1)*60)),
                                     wallTitle: wall.title, repeats: false)
                r.notifID = id
                store.addReminder(r)
                flash("Soak timer set for \(mins) min")
            } else {
                flash("Enable notifications in Settings")
            }
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 12 Batch & Shade Check

struct BatchShadeScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notifier: NotificationManager
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let needed = MatchEngine.rollResult(for: wall.wrappedValue).rollsTotal
        let short = wall.wrappedValue.batch.rollsInBatch < needed
        return DetailScaffold("Batch & Shade Check",
                              caption: "Check the batch number and shade match.") {
            // two rolls schematic
            HStack(spacing: 16) {
                rollMock(wall.wrappedValue.batch.batchNo.isEmpty ? "—" : wall.wrappedValue.batch.batchNo)
                rollMock(wall.wrappedValue.batch.batchNo.isEmpty ? "—" : wall.wrappedValue.batch.batchNo)
            }
            .frame(maxWidth: .infinity)

            if short {
                RMCard(light: false) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 24)).foregroundColor(RM.warn)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Order extra from the same batch")
                                .font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                            Text("You plan \(needed) rolls but only \(wall.wrappedValue.batch.rollsInBatch) in this batch. Different batches can differ in shade.")
                                .font(.system(size: 12)).foregroundColor(RM.textSub)
                        }
                    }
                }
            }

            RMCard {
                VStack(spacing: 12) {
                    RMTextField(title: "Batch No.", text: wall.batch.batchNo, placeholder: "A-2291", icon: "number")
                    RMTextField(title: "Shade Note", text: wall.batch.shadeNote, placeholder: "Warm grey, consistent", icon: "eyedropper")
                    RMIntStepper(title: "Rolls in Batch", value: wall.batch.rollsInBatch, range: 0...99)
                    Toggle(isOn: wall.batch.orderExtra) {
                        Text("Order extra now").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                }
            }

            PrimaryButton(title: "Verify Batch", icon: "checkmark.circle") {
                flash(short ? "Short — order more!" : "Batch covers the wall")
            }
            SecondaryButton(title: "Set Restock Reminder", icon: "bell") { restockReminder(wall.wrappedValue) }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.batch = BatchCheck(); store.updateWall(w); flash("Cleared")
                }
                NavigationLink(destination: LayoutBoardScreen(wallID: wallID)) {
                    HStack(spacing: 6) { Image(systemName: "square.grid.2x2"); Text("Layout").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }

    private func rollMock(_ batch: String) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [RM.strip, RM.strip.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 70, height: 90)
                .overlay(Image(systemName: "scroll").foregroundColor(.white).font(.system(size: 26)))
            Text("Batch \(batch)").font(.system(size: 11, weight: .bold)).foregroundColor(RM.textMuted)
        }
    }

    private func restockReminder(_ wall: Wall) {
        notifier.requestAuthorization { granted in
            if granted {
                let fire = Date().addingTimeInterval(3600)
                let id = notifier.schedule(title: "Restock same batch",
                                           body: "Order extra of batch \(wall.batch.batchNo) for \(wall.title).",
                                           at: fire)
                var r = ReminderItem(kind: .batch, title: "Restock batch \(wall.batch.batchNo)",
                                     fireDate: fire, wallTitle: wall.title, repeats: false)
                r.notifID = id
                store.addReminder(r)
                flash("Restock reminder set (1h)")
            } else { flash("Enable notifications first") }
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 16 Cost Estimate

struct CostEstimateScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    let wallID: UUID
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        let wall = store.wallBinding(wallID)
        let r = MatchEngine.rollResult(for: wall.wrappedValue)
        let total = MatchEngine.totalCost(for: wall.wrappedValue)
        let rollsCost = Double(r.rollsTotal) * wall.wrappedValue.cost.rollUnitPrice
        return DetailScaffold("Cost Estimate",
                              caption: "Add up rolls, paste and prep materials.") {
            RMCard {
                VStack(spacing: 10) {
                    HStack {
                        Text("Estimated total").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textSub)
                        Spacer()
                        Text("\(settings.currency)\(String(format: "%.2f", total))")
                            .font(.system(size: 28, weight: .heavy)).foregroundColor(RM.ok)
                    }
                    Divider().background(RM.cardBorder)
                    costRow("Rolls (\(r.rollsTotal) × \(settings.currency)\(fmt(wall.wrappedValue.cost.rollUnitPrice)))", rollsCost)
                    costRow("Paste", wall.wrappedValue.cost.pastePrice)
                    costRow("Lining / Primer", wall.wrappedValue.cost.liningPrice)
                    costRow("Tools", wall.wrappedValue.cost.toolsPrice)
                    costRow("Reserve \(Int(wall.wrappedValue.cost.reservePercent))%",
                            (rollsCost + wall.wrappedValue.cost.pastePrice + wall.wrappedValue.cost.liningPrice + wall.wrappedValue.cost.toolsPrice) * wall.wrappedValue.cost.reservePercent / 100)
                }
            }

            RMCard {
                VStack(spacing: 12) {
                    RMNumberField(title: "Roll Unit Price", value: wall.cost.rollUnitPrice, unit: settings.currency, icon: "scroll")
                    RMNumberField(title: "Paste", value: wall.cost.pastePrice, unit: settings.currency, icon: "drop")
                    RMNumberField(title: "Lining / Primer", value: wall.cost.liningPrice, unit: settings.currency, icon: "doc.plaintext")
                    RMNumberField(title: "Tools", value: wall.cost.toolsPrice, unit: settings.currency, icon: "wrench.and.screwdriver")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RESERVE  •  \(Int(wall.wrappedValue.cost.reservePercent))%").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                        Slider(value: wall.cost.reservePercent, in: 0...25, step: 1).accentColor(RM.primary)
                    }
                }
            }

            PrimaryButton(title: "Calculate Cost", icon: "dollarsign.circle") { flash("Total \(settings.currency)\(String(format: "%.2f", total))") }
            SecondaryButton(title: "Keep Estimate", icon: "tray.and.arrow.down") { flash("Estimate kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") {
                    var w = wall.wrappedValue; w.cost = CostEstimate(); store.updateWall(w); flash("Cleared")
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

    private func costRow(_ l: String, _ v: Double) -> some View {
        HStack {
            Text(l).font(.system(size: 13)).foregroundColor(RM.textSub)
            Spacer()
            Text("\(settings.currency)\(String(format: "%.2f", v))").font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
        }
    }
    private func fmt(_ d: Double) -> String { String(format: "%.0f", d) }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}
