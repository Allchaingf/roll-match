//
//  Models.swift
//  RollMatch
//
//  All Codable data structures + enums. Pure data — no UI, no logic.
//

import Foundation
import SwiftUI

// MARK: - Enums

enum MatchType: String, Codable, CaseIterable, Identifiable {
    case straight   // straight match — repeat lines up at the same height
    case drop       // drop / offset match — alternate strips drop by half a repeat
    case free       // free / random match — no alignment needed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .straight: return "Straight Match"
        case .drop: return "Drop Match"
        case .free: return "Free Match"
        }
    }
    var shortLabel: String {
        switch self {
        case .straight: return "Straight"
        case .drop: return "Drop"
        case .free: return "Free"
        }
    }
    var detail: String {
        switch self {
        case .straight: return "Pattern lines up at the same height on every strip."
        case .drop: return "Every other strip drops by half the repeat to align."
        case .free: return "No pattern alignment — least waste, fastest hang."
        }
    }
    var icon: String {
        switch self {
        case .straight: return "equal.square"
        case .drop: return "arrow.down.right.square"
        case .free: return "shuffle"
        }
    }
}

enum WallStatus: String, Codable, CaseIterable, Identifiable {
    case planning, inWork, hung, approved
    var id: String { rawValue }
    var label: String {
        switch self {
        case .planning: return "Planning"
        case .inWork: return "In Work"
        case .hung: return "Hung"
        case .approved: return "Approved"
        }
    }
    var color: Color {
        switch self {
        case .planning: return RM.warn
        case .inWork: return RM.inWork
        case .hung: return RM.ok
        case .approved: return RM.ok
        }
    }
    var icon: String {
        switch self {
        case .planning: return "pencil.and.ruler"
        case .inWork: return "hammer"
        case .hung: return "checkmark.seal"
        case .approved: return "checkmark.seal.fill"
        }
    }
}

enum WallPriority: String, Codable, CaseIterable, Identifiable {
    case low, normal, high
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .low: return RM.textMuted
        case .normal: return RM.inWork
        case .high: return RM.primary
        }
    }
}

enum SurfaceType: String, Codable, CaseIterable, Identifiable {
    case painted, lining, plaster
    var id: String { rawValue }
    var label: String {
        switch self {
        case .painted: return "Painted"
        case .lining: return "Lining"
        case .plaster: return "Plaster"
        }
    }
    var icon: String {
        switch self {
        case .painted: return "paintbrush"
        case .lining: return "doc.plaintext"
        case .plaster: return "square.dashed"
        }
    }
}

enum MainGoal: String, Codable, CaseIterable, Identifiable {
    case featureWall, wholeRoom, ceiling
    var id: String { rawValue }
    var label: String {
        switch self {
        case .featureWall: return "Feature Wall"
        case .wholeRoom: return "Whole Room"
        case .ceiling: return "Ceiling"
        }
    }
    var icon: String {
        switch self {
        case .featureWall: return "rectangle.portrait"
        case .wholeRoom: return "square.split.2x2"
        case .ceiling: return "rectangle.grid.1x2"
        }
    }
}

enum OpeningType: String, Codable, CaseIterable, Identifiable {
    case window, door, socket, vent
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .window: return "square.grid.2x2"
        case .door: return "door.left.hand.closed"
        case .socket: return "poweroutlet.type.b"
        case .vent: return "wind"
        }
    }
}

enum CornerType: String, Codable, CaseIterable, Identifiable {
    case internalCorner, externalCorner
    var id: String { rawValue }
    var label: String { self == .internalCorner ? "Internal" : "External" }
    var icon: String { self == .internalCorner ? "arrow.turn.down.right" : "arrow.turn.up.right" }
}

enum DefectType: String, Codable, CaseIterable, Identifiable {
    case bubble, lifting, mismatch, tear, gap
    var id: String { rawValue }
    var label: String {
        switch self {
        case .bubble: return "Bubble"
        case .lifting: return "Lifting / Peel"
        case .mismatch: return "Pattern Mismatch"
        case .tear: return "Tear"
        case .gap: return "Open Seam"
        }
    }
    var icon: String {
        switch self {
        case .bubble: return "circle.dashed"
        case .lifting: return "arrow.up.right.circle"
        case .mismatch: return "arrow.left.and.right"
        case .tear: return "scissors"
        case .gap: return "rectangle.split.2x1"
        }
    }
}

enum ApprovalDecision: String, Codable, CaseIterable, Identifiable {
    case pending, approved, redo
    var id: String { rawValue }
    var label: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .redo: return "Needs Redo"
        }
    }
    var color: Color {
        switch self {
        case .pending: return RM.warn
        case .approved: return RM.ok
        case .redo: return RM.defect
        }
    }
}

enum ReminderKind: String, Codable, CaseIterable, Identifiable {
    case soak, batch, seamCheck, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .soak: return "Paste Soak"
        case .batch: return "Restock Batch"
        case .seamCheck: return "Seam Check"
        case .custom: return "Custom"
        }
    }
    var icon: String {
        switch self {
        case .soak: return "timer"
        case .batch: return "shippingbox"
        case .seamCheck: return "checkmark.circle"
        case .custom: return "bell"
        }
    }
}

// MARK: - Roll & Pattern spec

struct RollSpec: Codable, Equatable {
    var width: Double = 0.53      // metres (standard roll 53 cm)
    var length: Double = 10.05    // metres (standard roll 10.05 m)

    static let standard = RollSpec(width: 0.53, length: 10.05)
    static let wide = RollSpec(width: 1.06, length: 25.0)
}

struct PatternSpec: Codable, Equatable {
    var matchType: MatchType = .straight
    var repeatHeight: Double = 0.32   // metres
    var dropOffset: Double = 0.16      // metres (used by drop match; default half-repeat)
    var motifScale: Double = 1.0       // 0.5 ... 2.0 — visual scale of the motif
}

// MARK: - Openings & corners

struct Opening: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: OpeningType = .window
    var width: Double = 1.0
    var height: Double = 1.2
    var keepPattern: Bool = true
}

struct CornerPlan: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: CornerType = .internalCorner
    var wrapOverlap: Double = 0.025   // metres (2.5 cm typical)
    var newPlumbLine: Bool = true
}

// MARK: - Prep / paste / batch

struct SurfacePrep: Codable, Equatable {
    var liningPaper: Bool = false
    var sizingPrimer: Bool = false
    var peelTestOK: Bool = false
    var repairsDone: Bool = false
    var notes: String = ""
    var isPrepped: Bool = false
}

struct PasteSoak: Codable, Equatable {
    var pasteType: String = "Ready-mixed"
    var soakMinutes: Int = 10
    var pasteTheWall: Bool = false
    var booking: Bool = true
}

struct BatchCheck: Codable, Equatable {
    var batchNo: String = ""
    var shadeNote: String = ""
    var rollsInBatch: Int = 0
    var orderExtra: Bool = false
}

// MARK: - Defect / approval

struct Defect: Codable, Identifiable, Equatable {
    var id = UUID()
    var type: DefectType = .bubble
    var severity: Int = 2          // 1...5
    var fixAction: String = ""
    var photo: Data? = nil
    var date: Date = Date()
}

struct Approval: Codable, Equatable {
    var reviewer: String = ""
    var decision: ApprovalDecision = .pending
    var comment: String = ""
    var signature: [SignatureStroke] = []
    var date: Date = Date()
}

struct SignatureStroke: Codable, Equatable {
    var points: [CGPointCodable] = []
}

/// Codable wrapper for CGPoint (CGPoint is Codable on modern SDKs but we keep it explicit for iOS 14).
struct CGPointCodable: Codable, Equatable {
    var x: Double
    var y: Double
    init(_ p: CGPoint) { x = Double(p.x); y = Double(p.y) }
    init(x: Double, y: Double) { self.x = x; self.y = y }
    var cg: CGPoint { CGPoint(x: x, y: y) }
}

// MARK: - Cost & centering & progress

struct CostEstimate: Codable, Equatable {
    var rollUnitPrice: Double = 0
    var pastePrice: Double = 0
    var liningPrice: Double = 0
    var toolsPrice: Double = 0
    var reservePercent: Double = 10
}

struct Centering: Codable, Equatable {
    var focalPoint: Double = 0.5      // 0...1 across the wall width
    var centerMotif: Bool = true
    var firstStripShift: Double = 0   // metres
}

struct HangProgress: Codable, Equatable {
    var stripsDone: Int = 0
    var timeSpentMinutes: Int = 0
    var issues: String = ""
}

// MARK: - Wall (the core record)

struct Wall: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String = "New Wall"
    var projectName: String = "My Room"
    var goal: MainGoal = .featureWall

    // Dimensions (metres)
    var width: Double = 3.6
    var height: Double = 2.4
    var repeatOffset: Double = 0     // measuring-point offset
    var tolerance: Double = 0.02
    var measurePoint: String = "Floor → ceiling, left edge"

    // Spec
    var roll: RollSpec = .standard
    var pattern: PatternSpec = PatternSpec()
    var trimAllowance: Double = 0.10  // metres total trim per strip (top+bottom)

    // Plan parts
    var openings: [Opening] = []
    var corners: [CornerPlan] = []
    var centering: Centering = Centering()
    var prep: SurfacePrep = SurfacePrep()
    var paste: PasteSoak = PasteSoak()
    var batch: BatchCheck = BatchCheck()
    var cost: CostEstimate = CostEstimate()
    var defects: [Defect] = []
    var approval: Approval = Approval()
    var progress: HangProgress = HangProgress()

    // Calc safety margins
    var extraPercent: Double = 10     // generic safety stock %

    // Meta
    var status: WallStatus = .planning
    var priority: WallPriority = .normal
    var notes: String = ""
    var photo: Data? = nil
    var photoCaption: String = ""
    var markPoints: [CGPointCodable] = []   // normalized 0..1 markers on the photo
    var createdAt: Date = Date()

    // Hang sequence
    var startWall: String = "Left of focal point"
    var hangDirection: String = "Left → Right"
    var finishCorner: String = "Behind door"
}

// MARK: - Reminder record (mirrors a scheduled local notification)

struct ReminderItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: ReminderKind = .soak
    var title: String = ""
    var fireDate: Date = Date().addingTimeInterval(600)
    var wallTitle: String = ""
    var repeats: Bool = false
    var notifID: String = UUID().uuidString
}
