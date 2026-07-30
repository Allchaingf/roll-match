//
//  ReportsTab.swift
//  RollMatch
//
//  Reports hub + screen 21 Reports & Export, 20 Reminders Center, and Settings.
//

import SwiftUI

// MARK: - Reports hub

struct ReportsHubView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationView {
            ZStack {
                RMBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Reports", subtitle: "Analytics, export & reminders", icon: "doc.text")
                            .padding(.horizontal, 16).padding(.top, 8)

                        analytics
                        links
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var analytics: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricTile(value: "\(store.walls.count)", label: "Walls", color: RM.strip, icon: "rectangle.split.3x1")
                MetricTile(value: "\(store.totalRollsPlanned)", label: "Rolls planned", color: RM.primary, icon: "shippingbox")
            }
            HStack(spacing: 10) {
                MetricTile(value: String(format: "%.0f%%", store.avgPatternWaste), label: "Avg pattern waste", color: RM.warn, icon: "scissors")
                MetricTile(value: String(format: "%.0f%%", store.readinessPercent), label: "Walls ready", color: RM.ok, icon: "checkmark.seal")
            }
            RMCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("READINESS").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    ProgressBar(value: store.readinessPercent / 100)
                    Text("\(store.wallsApproved) approved • \(store.wallsInWork) in work • \(store.openDefects) defects")
                        .font(.system(size: 12)).foregroundColor(RM.textMuted)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 16)
    }

    private var links: some View {
        VStack(spacing: 10) {
            NavigationLink(destination: ReportsExportScreen(initialWallID: store.walls.first?.id)) {
                NavRow(number: "21", title: "Reports & Export", subtitle: "Build a clean local report or PDF", icon: "doc.richtext", accent: RM.primary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: RemindersScreen()) {
                NavRow(number: "20", title: "Reminders Center", subtitle: "Local nudges so nothing slips", icon: "bell.badge", accent: RM.secondary)
            }.buttonStyle(PlainButtonStyle())
            NavigationLink(destination: SettingsScreen()) {
                NavRow(number: "⚙︎", title: "Settings", subtitle: "Theme, units, currency, data", icon: "gearshape", accent: RM.strip)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 21 Reports & Export

struct ReportsExportScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    var initialWallID: UUID?

    @State private var wallID: UUID?
    @State private var sections: Set<String> = ["Layout", "Rolls", "Cut List", "Cost", "Approval"]
    @State private var format = "PDF"
    @State private var notes = ""
    @State private var showShare = false
    @State private var pdfURL: URL?
    @State private var toast = false
    @State private var toastMsg = ""

    private let allSections = ["Layout", "Rolls", "Cut List", "Defects", "Cost", "Approval"]

    var body: some View {
        DetailScaffold("Reports & Export",
                       caption: "Build a clean local report or PDF.") {
            // wall picker
            RMCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PROJECT / WALL").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    if store.walls.isEmpty {
                        Text("No walls to report yet.").font(.system(size: 13)).foregroundColor(RM.textMuted)
                    } else {
                        FlowChips(items: store.walls.map { $0.id }) { id in
                            RMChip(label: store.wall(by: id)?.title ?? "Wall",
                                   selected: activeID == id) { wallID = id }
                        }
                    }
                }
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("INCLUDE SECTIONS").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    ForEach(allSections, id: \.self) { s in
                        Button(action: { toggle(s); settings.haptic(.light) }) {
                            HStack {
                                Image(systemName: sections.contains(s) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(sections.contains(s) ? RM.ok : RM.textMuted)
                                Text(s).font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }

            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FORMAT").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    FlowChips(items: ["PDF", "Summary"]) { f in
                        RMChip(label: f, selected: format == f) { format = f }
                    }
                    RMTextField(title: "Notes", text: $notes, placeholder: "For the client / shopping list")
                }
            }

            // live preview
            if let id = activeID, let wall = store.wall(by: id) {
                reportPreview(wall)
            }

            PrimaryButton(title: "Generate Report", icon: "doc.text.magnifyingglass") {
                flash("Report generated below")
            }
            SecondaryButton(title: "Export PDF", icon: "square.and.arrow.up") { exportPDF() }
            HStack(spacing: 12) {
                GhostButton(title: "Share Locally", icon: "square.and.arrow.up.on.square") { exportPDF() }
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 6) { Image(systemName: "house"); Text("Back to Atlas").font(.system(size: 15, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .onAppear { if wallID == nil { wallID = initialWallID ?? store.walls.first?.id } }
        .sheet(isPresented: $showShare) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
        .toast($toast, message: toastMsg)
    }

    private var activeID: UUID? { wallID ?? store.walls.first?.id }

    private func reportPreview(_ wall: Wall) -> some View {
        let r = MatchEngine.rollResult(for: wall)
        return RMCard(light: false) {
            VStack(alignment: .leading, spacing: 8) {
                Text(wall.title).font(.system(size: 16, weight: .bold)).foregroundColor(RM.textMain)
                if sections.contains("Layout") {
                    previewLine("Layout", "\(MatchEngine.lengthString(wall.width, unit: settings.units)) × \(MatchEngine.lengthString(wall.height, unit: settings.units)) • \(wall.pattern.matchType.label)")
                }
                if sections.contains("Rolls") {
                    previewLine("Rolls", "\(r.rollsTotal) total • \(r.stripsNeeded) strips • \(String(format: "%.0f%%", r.patternWastePercent)) pattern waste")
                }
                if sections.contains("Cut List") {
                    previewLine("Cut list", "\(MatchEngine.stripPlans(for: wall).count) strips listed")
                }
                if sections.contains("Defects") {
                    previewLine("Defects", "\(wall.defects.count) logged")
                }
                if sections.contains("Cost") {
                    previewLine("Cost", "\(settings.currency)\(String(format: "%.2f", MatchEngine.totalCost(for: wall)))")
                }
                if sections.contains("Approval") {
                    previewLine("Approval", wall.approval.decision.label)
                }
            }
        }
    }
    private func previewLine(_ l: String, _ v: String) -> some View {
        HStack(alignment: .top) {
            Text(l).font(.system(size: 12, weight: .heavy)).foregroundColor(RM.primary).frame(width: 70, alignment: .leading)
            Text(v).font(.system(size: 12.5)).foregroundColor(RM.textSub)
            Spacer()
        }
    }

    private func toggle(_ s: String) {
        if sections.contains(s) { sections.remove(s) } else { sections.insert(s) }
    }
    private func exportPDF() {
        guard let id = activeID, let wall = store.wall(by: id) else { flash("Pick a wall first"); return }
        if let url = PDFReport.build(for: wall, units: settings.units, currency: settings.currency, sections: sections) {
            pdfURL = url
            showShare = true
        } else { flash("Could not build PDF") }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - 20 Reminders Center

struct RemindersScreen: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var notifier: NotificationManager

    @State private var kind: ReminderKind = .soak
    @State private var when = Date().addingTimeInterval(3600)
    @State private var wallTitle = ""
    @State private var repeats = false
    @State private var toast = false
    @State private var toastMsg = ""

    var body: some View {
        DetailScaffold("Reminders Center",
                       caption: "Local nudges so nothing slips.") {
            if !notifier.authorized {
                RMCard(light: false) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash").foregroundColor(RM.warn)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications off").font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
                            Text("Enable to receive soak / batch / seam reminders.").font(.system(size: 12)).foregroundColor(RM.textSub)
                        }
                        Spacer()
                        Button(action: { notifier.requestAuthorization { _ in } }) {
                            Text("Enable").font(.system(size: 13, weight: .bold)).foregroundColor(RM.bg)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(RM.secondary).cornerRadius(10)
                        }
                    }
                }
            }

            // existing reminders
            if store.reminders.isEmpty {
                RMCard {
                    HStack { Image(systemName: "bell").foregroundColor(RM.textMuted); Text("No reminders yet.").foregroundColor(RM.textSub).font(.system(size: 14)) }
                }
            } else {
                ForEach(store.reminders) { r in
                    reminderCard(r)
                }
            }

            // add new
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ADD REMINDER").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    EnumChips(items: ReminderKind.allCases, selection: $kind, label: { $0.label }, icon: { $0.icon })
                    DatePicker("When", selection: $when, in: Date()...)
                        .datePickerStyle(CompactDatePickerStyle())
                        .accentColor(RM.primary)
                        .foregroundColor(RM.textMain)
                    if !store.walls.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WALL").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                            FlowChips(items: store.walls.map { $0.title }) { t in
                                RMChip(label: t, selected: wallTitle == t) { wallTitle = t }
                            }
                        }
                    }
                    Toggle(isOn: $repeats) {
                        Text("Repeat daily").font(.system(size: 14, weight: .semibold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: RM.primary))
                }
            }

            PrimaryButton(title: "Add Reminder", icon: "plus") { addReminder() }
            SecondaryButton(title: "Keep Reminders", icon: "tray.and.arrow.down") { flash("Reminders kept") }
            HStack(spacing: 12) {
                GhostButton(title: "Clear Fields", icon: "xmark.circle") { wallTitle = ""; repeats = false; flash("Cleared") }
                NavigationLink(destination: ReportsExportScreen(initialWallID: store.walls.first?.id)) {
                    HStack(spacing: 6) { Image(systemName: "doc.text"); Text("Reports").font(.system(size: 14, weight: .bold)) }
                        .foregroundColor(RM.bg).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(RM.strip).cornerRadius(14)
                }
            }
        }
        .onAppear { notifier.refreshAuthStatus() }
        .toast($toast, message: toastMsg)
    }

    private func reminderCard(_ r: ReminderItem) -> some View {
        RMCard {
            HStack(spacing: 12) {
                Image(systemName: r.kind.icon).font(.system(size: 22)).foregroundColor(RM.primary).frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.title.isEmpty ? r.kind.label : r.title).font(.system(size: 14, weight: .bold)).foregroundColor(RM.textMain)
                    Text(DateFormatter.rmShortDateTime.string(from: r.fireDate) + (r.repeats ? " • daily" : ""))
                        .font(.system(size: 12)).foregroundColor(RM.textSub)
                }
                Spacer()
                Button(action: {
                    notifier.cancel(id: r.notifID)
                    store.deleteReminder(r)
                }) { Image(systemName: "trash").foregroundColor(RM.defect) }
            }
        }
    }

    private func addReminder() {
        notifier.requestAuthorization { granted in
            if granted {
                let title = "\(kind.label)\(wallTitle.isEmpty ? "" : " — \(wallTitle)")"
                let id = notifier.schedule(title: kind.label,
                                           body: title,
                                           at: when, repeats: repeats)
                var r = ReminderItem(kind: kind, title: title, fireDate: when, wallTitle: wallTitle, repeats: repeats)
                r.notifID = id
                store.addReminder(r)
                flash("Reminder scheduled")
            } else { flash("Enable notifications first") }
        }
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}

// MARK: - Settings

struct SettingsScreen: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifier: NotificationManager
    @State private var showClearConfirm = false
    @State private var toast = false
    @State private var toastMsg = ""
    private let currencies = ["$", "€", "£", "₽", "₴"]

    var body: some View {
        DetailScaffold("Settings", caption: "Everything is stored locally on this device.") {
            // Theme
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THEME").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    HStack(spacing: 8) {
                        ForEach(ThemeMode.allCases) { m in
                            Button(action: { settings.themeMode = m; settings.haptic(.light) }) {
                                VStack(spacing: 6) {
                                    Image(systemName: m.icon).font(.system(size: 20))
                                    Text(m.label).font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(settings.themeMode == m ? RM.bg : RM.textSub)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(settings.themeMode == m ? RM.primary : RM.cardBlue)
                                .cornerRadius(12)
                            }
                        }
                    }
                    Text("Applies instantly across the whole app.").font(.system(size: 12)).foregroundColor(RM.textMuted)
                }
            }

            // Accent
            RMCard {
                Toggle(isOn: Binding(get: { settings.accentYellow }, set: { settings.accentYellow = $0; settings.haptic(.light) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yellow accent").font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                        Text("Switch primary accent orange ↔ yellow").font(.system(size: 12)).foregroundColor(RM.textSub)
                    }
                }.toggleStyle(SwitchToggleStyle(tint: settings.accent))
            }

            // Units & currency
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("UNITS").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    FlowChips(items: MeasureUnit.allCases) { u in
                        RMChip(label: u.label, selected: settings.units == u) { settings.units = u }
                    }
                    Text("CURRENCY").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    FlowChips(items: currencies) { c in
                        RMChip(label: c, selected: settings.currency == c) { settings.currency = c }
                    }
                }
            }

            // Notifications + haptics
            RMCard {
                VStack(spacing: 14) {
                    Toggle(isOn: Binding(get: { settings.notificationsEnabled }, set: { on in
                        settings.notificationsEnabled = on
                        if on { notifier.requestAuthorization { _ in } } else { notifier.cancelAll() }
                    })) {
                        Text("Notifications").font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: settings.accent))
                    Toggle(isOn: Binding(get: { settings.hapticsEnabled }, set: { settings.hapticsEnabled = $0 })) {
                        Text("Haptics").font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                    }.toggleStyle(SwitchToggleStyle(tint: settings.accent))
                }
            }

            // Data
            RMCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DATA").font(.system(size: 11, weight: .heavy)).foregroundColor(RM.textSub)
                    HStack {
                        Text("\(store.walls.count) walls • \(store.reminders.count) reminders")
                            .font(.system(size: 13)).foregroundColor(RM.textSub)
                        Spacer()
                    }
                    if showClearConfirm {
                        Text("Delete all walls & reminders? This cannot be undone.")
                            .font(.system(size: 12)).foregroundColor(RM.defect)
                        HStack(spacing: 12) {
                            GhostButton(title: "Cancel", icon: "xmark") { showClearConfirm = false }
                            DangerButton(title: "Delete All", icon: "trash") {
                                store.walls = []; store.reminders = []; notifier.cancelAll()
                                showClearConfirm = false; flash("All data cleared")
                            }
                        }
                    } else {
                        DangerButton(title: "Clear All Data", icon: "trash") { showClearConfirm = true }
                    }
                }
            }

            // About
            RMCard(light: false) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Roll Match").font(.system(size: 15, weight: .bold)).foregroundColor(RM.textMain)
                    Text("Pattern-repeat wallpaper planner. Match the pattern, not the panic.")
                        .font(.system(size: 12)).foregroundColor(RM.textSub)
                    Text("No account • No tracking • 100% on-device.")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(RM.ok)
                }
            }
        }
        .toast($toast, message: toastMsg)
    }
    private func flash(_ m: String) { settings.haptic(); toastMsg = m; withAnimation { toast = true } }
}
