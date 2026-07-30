//
//  MatchEngine.swift
//  RollMatch
//
//  Pure pattern-repeat + strip-layout engine. No UI, no state. The heart of the app:
//  it counts strips-per-roll WITH pattern fitting (not naive length/height), separates
//  pattern waste from generic safety stock, and computes centering & cut lists.
//

import Foundation

struct StripPlan: Identifiable {
    let id = UUID()
    var index: Int          // 1-based strip number
    var cutLength: Double    // metres of roll consumed for this strip (rounded to repeats)
    var requiredDrop: Double // metres actually covering the wall + trim
    var repeatShift: Double  // metres of pattern offset applied at the top of this strip
    var trimTop: Double
    var trimBottom: Double
    var isFirst: Bool
    var wasteOnStrip: Double  // cutLength - requiredDrop
}

struct RollResult {
    var stripsNeeded: Int
    var stripsPerRoll: Int
    var rollsForPattern: Int      // rolls needed to cover strips incl. pattern fitting
    var rollsTotal: Int           // incl. generic extra %
    var effectiveCutLength: Double
    var patternWastePercent: Double  // waste caused by pattern fitting only
    var extraPercent: Double         // generic safety %
    var totalLengthNeeded: Double    // metres of paper actually used (strips × cut)
    var usableLengthBought: Double   // metres bought (rolls × roll length)
}

enum MatchEngine {

    static let epsilon = 0.0001

    // MARK: - Strip count across the wall width

    static func stripsNeeded(wallWidth: Double, rollWidth: Double) -> Int {
        guard rollWidth > epsilon, wallWidth > epsilon else { return 0 }
        return Int(ceil(wallWidth / rollWidth - epsilon))
    }

    // MARK: - Effective cut length (one strip) honoring the repeat

    /// The drop that must physically reach floor→ceiling plus trim.
    static func requiredDrop(wallHeight: Double, trim: Double, repeatOffset: Double) -> Double {
        return max(0, wallHeight + trim + repeatOffset)
    }

    /// How much roll a single strip consumes once the pattern repeat is honored.
    /// straight/free: round the drop up to whole repeats (free can be exact, but we keep a
    /// small repeat to allow trimming). drop match: alternate strips need +half a repeat.
    static func cutLength(for pattern: PatternSpec, drop: Double, isOdd: Bool) -> Double {
        let rh = max(pattern.repeatHeight, epsilon)
        switch pattern.matchType {
        case .free:
            // Free match: no alignment, so the cut is the drop plus a tiny squaring allowance.
            return drop
        case .straight:
            let repeats = ceil(drop / rh - epsilon)
            return repeats * rh
        case .drop:
            // Drop match: alternate strips are offset by the drop offset, so they "start"
            // higher up the roll and need an extra partial repeat to land in pattern.
            let extra = isOdd ? 0 : min(pattern.dropOffset, rh)
            let repeats = ceil((drop + extra) / rh - epsilon)
            return repeats * rh
        }
    }

    // MARK: - Per-strip cut list

    static func stripPlans(for wall: Wall) -> [StripPlan] {
        let count = stripsNeeded(wallWidth: wall.width, rollWidth: wall.roll.width)
        guard count > 0 else { return [] }
        let drop = requiredDrop(wallHeight: wall.height, trim: wall.trimAllowance, repeatOffset: wall.repeatOffset)
        var plans: [StripPlan] = []
        for i in 1...count {
            let isOdd = (i % 2 == 1)
            let cut = cutLength(for: wall.pattern, drop: drop, isOdd: isOdd)
            // Pattern shift at the top of this strip.
            let shift: Double
            switch wall.pattern.matchType {
            case .drop: shift = isOdd ? 0 : wall.pattern.dropOffset
            default: shift = 0
            }
            let trimTop = wall.trimAllowance / 2
            let trimBottom = wall.trimAllowance / 2
            plans.append(StripPlan(index: i,
                                   cutLength: cut,
                                   requiredDrop: drop,
                                   repeatShift: shift,
                                   trimTop: trimTop,
                                   trimBottom: trimBottom,
                                   isFirst: i == 1,
                                   wasteOnStrip: max(0, cut - drop)))
        }
        return plans
    }

    // MARK: - Roll totals

    static func rollResult(for wall: Wall) -> RollResult {
        let plans = stripPlans(for: wall)
        let strips = plans.count
        let drop = requiredDrop(wallHeight: wall.height, trim: wall.trimAllowance, repeatOffset: wall.repeatOffset)
        // Use the heavier (even-strip) cut length as the limiting "effective cut".
        let effCut = cutLength(for: wall.pattern, drop: drop, isOdd: false)
        let perRoll = effCut > epsilon ? Int(floor(wall.roll.length / effCut + epsilon)) : 0

        let rollsForPattern = (perRoll > 0 && strips > 0) ? Int(ceil(Double(strips) / Double(perRoll) - epsilon)) : 0

        // Generic extra stock — applied to strip count then re-divided into rolls.
        let stripsWithExtra = Double(strips) * (1 + wall.extraPercent / 100)
        let rollsTotal = (perRoll > 0) ? Int(ceil(stripsWithExtra / Double(perRoll) - epsilon)) : 0

        let totalUsed = plans.reduce(0) { $0 + $1.cutLength }
        let totalNeededByDrop = Double(strips) * drop
        let patternWaste = totalUsed > epsilon ? (totalUsed - totalNeededByDrop) / totalUsed * 100 : 0
        let bought = Double(max(rollsForPattern, 0)) * wall.roll.length

        return RollResult(stripsNeeded: strips,
                          stripsPerRoll: max(perRoll, 0),
                          rollsForPattern: rollsForPattern,
                          rollsTotal: max(rollsTotal, rollsForPattern),
                          effectiveCutLength: effCut,
                          patternWastePercent: max(patternWaste, 0),
                          extraPercent: wall.extraPercent,
                          totalLengthNeeded: totalUsed,
                          usableLengthBought: bought)
    }

    // MARK: - Centering on a focal point

    struct CenterResult {
        var fullStrips: Int
        var leftCut: Double
        var rightCut: Double
        var firstStripShift: Double
        var balanced: Bool
    }

    static func centerResult(for wall: Wall) -> CenterResult {
        let rw = max(wall.roll.width, epsilon)
        // Full strips that fit, leaving side cuts.
        let full = max(Int(floor(wall.width / rw + epsilon)), 0)
        let remainder = wall.width - Double(full) * rw

        if wall.centering.centerMotif {
            // Balance: split the remainder evenly across both side strips.
            let side = remainder / 2
            // Shift the first strip so the motif's centre lands on the focal point.
            let focalX = wall.centering.focalPoint * wall.width
            let nearestSeam = (focalX / rw).rounded() * rw
            let shift = focalX - nearestSeam
            return CenterResult(fullStrips: full,
                                leftCut: side,
                                rightCut: side,
                                firstStripShift: shift,
                                balanced: abs(side) > epsilon)
        } else {
            return CenterResult(fullStrips: full,
                                leftCut: remainder,
                                rightCut: 0,
                                firstStripShift: 0,
                                balanced: false)
        }
    }

    // MARK: - Openings → net area + partial drops kept

    struct OpeningResult {
        var grossArea: Double
        var openingsArea: Double
        var netArea: Double
        var partialStripsKept: Int
    }

    static func openingResult(for wall: Wall) -> OpeningResult {
        let gross = wall.width * wall.height
        var openArea: Double = 0
        var kept = 0
        for o in wall.openings {
            openArea += o.width * o.height
            if o.keepPattern { kept += 1 } // strips above & below kept in pattern
        }
        return OpeningResult(grossArea: gross,
                             openingsArea: openArea,
                             netArea: max(gross - openArea, 0),
                             partialStripsKept: kept)
    }

    // MARK: - Cost roll-up

    static func totalCost(for wall: Wall) -> Double {
        let r = rollResult(for: wall)
        let c = wall.cost
        let base = Double(r.rollsTotal) * c.rollUnitPrice + c.pastePrice + c.liningPrice + c.toolsPrice
        return base * (1 + c.reservePercent / 100)
    }

    // MARK: - Formatting helpers (length in current units)

    static func lengthString(_ metres: Double, unit: MeasureUnit, decimals: Int = 2) -> String {
        switch unit {
        case .metric:
            return String(format: "%.\(decimals)f m", metres)
        case .imperial:
            let feet = metres * 3.28084
            return String(format: "%.\(decimals)f ft", feet)
        }
    }

    static func shortLength(_ metres: Double, unit: MeasureUnit) -> String {
        switch unit {
        case .metric:
            return String(format: "%.0f cm", metres * 100)
        case .imperial:
            return String(format: "%.1f in", metres * 39.3701)
        }
    }
}
