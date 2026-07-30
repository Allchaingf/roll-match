//
//  Store.swift
//  RollMatch
//
//  App-wide data store. ObservableObject with @Published arrays, persisted as JSON in
//  UserDefaults. All CRUD lives here; Views never touch persistence directly.
//

import Foundation
import Combine
import SwiftUI

final class AppStore: ObservableObject {
    @Published var walls: [Wall] = [] { didSet { save() } }
    @Published var reminders: [ReminderItem] = [] { didSet { saveReminders() } }

    private let wallsKey = "rm_walls_v1"
    private let remindersKey = "rm_reminders_v1"

    init() {
        load()
        loadReminders()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(walls) {
            UserDefaults.standard.set(data, forKey: wallsKey)
        }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: wallsKey),
              let decoded = try? JSONDecoder().decode([Wall].self, from: data) else { return }
        walls = decoded
    }
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: remindersKey)
        }
    }
    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: remindersKey),
              let decoded = try? JSONDecoder().decode([ReminderItem].self, from: data) else { return }
        reminders = decoded
    }

    // MARK: - Walls CRUD

    func addWall(_ wall: Wall) {
        walls.insert(wall, at: 0)
    }

    func updateWall(_ wall: Wall) {
        guard let idx = walls.firstIndex(where: { $0.id == wall.id }) else { return }
        walls[idx] = wall
    }

    func deleteWall(_ wall: Wall) {
        walls.removeAll { $0.id == wall.id }
    }

    func deleteWalls(at offsets: IndexSet) {
        walls.remove(atOffsets: offsets)
    }

    @discardableResult
    func duplicateWall(_ wall: Wall) -> Wall {
        var copy = wall
        copy.id = UUID()
        copy.title = wall.title + " (copy)"
        copy.createdAt = Date()
        copy.status = .planning
        copy.progress = HangProgress()
        copy.approval = Approval()
        walls.insert(copy, at: 0)
        return copy
    }

    func binding(for wall: Wall) -> Binding<Wall>? {
        guard let idx = walls.firstIndex(where: { $0.id == wall.id }) else { return nil }
        return Binding(
            get: { self.walls[idx] },
            set: { self.walls[idx] = $0 }
        )
    }

    func wall(by id: UUID) -> Wall? {
        walls.first { $0.id == id }
    }

    /// Crash-safe two-way binding to a wall by id (writes flow back through updateWall).
    func wallBinding(_ id: UUID) -> Binding<Wall> {
        Binding(
            get: { self.wall(by: id) ?? Wall() },
            set: { self.updateWall($0) }
        )
    }

    // MARK: - Reminders CRUD

    func addReminder(_ r: ReminderItem) {
        reminders.insert(r, at: 0)
    }
    func deleteReminder(_ r: ReminderItem) {
        reminders.removeAll { $0.id == r.id }
    }
    func deleteReminders(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }

    // MARK: - Analytics summaries

    var totalRollsPlanned: Int {
        walls.reduce(0) { $0 + MatchEngine.rollResult(for: $1).rollsTotal }
    }
    var wallsApproved: Int { walls.filter { $0.status == .approved }.count }
    var wallsInWork: Int { walls.filter { $0.status == .inWork }.count }
    var openDefects: Int { walls.reduce(0) { $0 + $1.defects.count } }

    var avgPatternWaste: Double {
        guard !walls.isEmpty else { return 0 }
        let sum = walls.reduce(0.0) { $0 + MatchEngine.rollResult(for: $1).patternWastePercent }
        return sum / Double(walls.count)
    }

    var readinessPercent: Double {
        guard !walls.isEmpty else { return 0 }
        let done = walls.filter { $0.status == .hung || $0.status == .approved }.count
        return Double(done) / Double(walls.count) * 100
    }

    // MARK: - Sample seeding (onboarding "Use Sample")

    static func sampleWall() -> Wall {
        var w = Wall()
        w.title = "Living Room Feature"
        w.projectName = "Apartment"
        w.goal = .featureWall
        w.width = 3.80
        w.height = 2.55
        w.tolerance = 0.02
        w.measurePoint = "Skirting → ceiling, centre"
        w.roll = .standard
        w.pattern = PatternSpec(matchType: .drop, repeatHeight: 0.64, dropOffset: 0.32, motifScale: 1.0)
        w.trimAllowance = 0.10
        w.openings = [Opening(type: .socket, width: 0.08, height: 0.08, keepPattern: true)]
        w.corners = [CornerPlan(type: .internalCorner, wrapOverlap: 0.025, newPlumbLine: true)]
        w.centering = Centering(focalPoint: 0.5, centerMotif: true, firstStripShift: 0)
        w.prep = SurfacePrep(liningPaper: true, sizingPrimer: true, peelTestOK: true, repairsDone: true, notes: "Filled two nail holes.", isPrepped: true)
        w.paste = PasteSoak(pasteType: "Ready-mixed", soakMinutes: 10, pasteTheWall: false, booking: true)
        w.batch = BatchCheck(batchNo: "A-2291", shadeNote: "Warm grey, consistent", rollsInBatch: 6, orderExtra: false)
        w.cost = CostEstimate(rollUnitPrice: 28, pastePrice: 12, liningPrice: 18, toolsPrice: 25, reservePercent: 10)
        w.extraPercent = 10
        w.status = .inWork
        w.priority = .high
        w.notes = "Centre the floral motif on the TV unit."
        w.startWall = "Left of TV unit"
        w.hangDirection = "Centre → Out"
        w.finishCorner = "Behind door"
        return w
    }
}
