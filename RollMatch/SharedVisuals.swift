//
//  SharedVisuals.swift
//  RollMatch
//
//  Signature schematic components reused across functional screens:
//  the strip layout (blue strips + orange seam lines), the repeat ruler,
//  and the wall schematic with openings.
//

import SwiftUI

// MARK: - Strip layout: blue panels with orange seam lines, ceiling/skirting marks

struct StripLayoutView: View {
    let wall: Wall
    var height: CGFloat = 170
    var showMotif: Bool = true

    var body: some View {
        GeometryReader { geo in
            self.content(in: geo.size)
        }
        .frame(height: height)
    }

    private func content(in size: CGSize) -> some View {
        let strips = max(MatchEngine.stripsNeeded(wallWidth: wall.width, rollWidth: wall.roll.width), 1)
        let stripW = size.width / CGFloat(strips)
        let repeatPx = repeatPixels(in: size, strips: strips)
        let dropOffsetFraction: CGFloat = wall.pattern.matchType == .drop
            ? CGFloat(min(wall.pattern.dropOffset / max(wall.pattern.repeatHeight, 0.001), 1)) : 0

        return ZStack(alignment: .topLeading) {
            // ceiling / skirting guide band
            RoundedRectangle(cornerRadius: 10)
                .fill(RM.bgSoft)
            HStack(spacing: 0) {
                ForEach(0..<strips, id: \.self) { i in
                    self.strip(index: i, width: stripW, height: size.height,
                               repeatPx: repeatPx, dropFraction: dropOffsetFraction)
                }
            }
            // ceiling line
            Rectangle().fill(RM.secondary).frame(height: 2)
                .offset(y: 6)
            // skirting line
            Rectangle().fill(RM.secondary.opacity(0.7)).frame(height: 2)
                .offset(y: size.height - 8)
        }
    }

    private func repeatPixels(in size: CGSize, strips: Int) -> CGFloat {
        let drop = MatchEngine.requiredDrop(wallHeight: wall.height, trim: wall.trimAllowance, repeatOffset: wall.repeatOffset)
        guard drop > 0.001 else { return size.height / 3 }
        let repeatsVisible = max(drop / max(wall.pattern.repeatHeight, 0.001), 1)
        return size.height / CGFloat(repeatsVisible)
    }

    private func strip(index i: Int, width: CGFloat, height: CGFloat,
                       repeatPx: CGFloat, dropFraction: CGFloat) -> some View {
        let isEven = (i % 2 == 0)
        let yOffset: CGFloat = wall.pattern.matchType == .drop && !isEven ? repeatPx * dropFraction : 0
        return ZStack(alignment: .top) {
            Rectangle()
                .fill(LinearGradient(colors: [RM.strip.opacity(0.95), RM.strip.opacity(0.6)],
                                     startPoint: .top, endPoint: .bottom))
            if showMotif && wall.pattern.matchType != .free {
                self.motifMarks(width: width, height: height, repeatPx: repeatPx, yOffset: yOffset)
            } else if showMotif {
                self.freeMarks(width: width, height: height)
            }
            // seam line on the right edge of each strip (except last visual edge handled by spacing)
            HStack {
                Spacer()
                Rectangle().fill(RM.seam).frame(width: 2)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private func motifMarks(width: CGFloat, height: CGFloat, repeatPx: CGFloat, yOffset: CGFloat) -> some View {
        let count = Int(height / max(repeatPx, 12)) + 2
        return ZStack(alignment: .top) {
            ForEach(0..<count, id: \.self) { r in
                Circle()
                    .stroke(RM.secondary.opacity(0.85), lineWidth: 1.6)
                    .frame(width: min(width * 0.5, 22), height: min(width * 0.5, 22))
                    .offset(y: CGFloat(r) * repeatPx + yOffset + 8)
            }
        }
        .frame(width: width, height: height, alignment: .top)
    }

    private func freeMarks(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { k in
                Circle()
                    .fill(RM.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .offset(x: CGFloat((k * 37) % max(Int(width) - 8, 1)) - width/2 + 6,
                            y: CGFloat((k * 53) % max(Int(height) - 8, 1)) - height/2 + 6)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Repeat ruler (vertical, "breathing" ticks)

struct RepeatRulerView: View {
    let repeatHeight: Double   // metres
    let rollLength: Double     // metres
    var animated: Bool = true
    @State private var breathe = false

    var body: some View {
        GeometryReader { geo in
            self.body(in: geo.size)
        }
    }

    private func body(in size: CGSize) -> some View {
        let totalRepeats = max(Int(rollLength / max(repeatHeight, 0.01)), 1)
        let visible = min(totalRepeats, 14)
        let step = size.height / CGFloat(visible)
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8).fill(RM.bgSoft)
            // The roll strip
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [RM.strip, RM.strip.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .frame(width: size.width * 0.5)
                .padding(.leading, size.width * 0.28)
            // Repeat marks
            ForEach(0..<(visible + 1), id: \.self) { i in
                HStack(spacing: 4) {
                    Rectangle().fill(RM.secondary)
                        .frame(width: (i % 2 == 0 ? size.width * 0.22 : size.width * 0.14),
                               height: 2)
                    if i % 2 == 0 {
                        Text(String(format: "%.2fm", Double(i) * repeatHeight))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(RM.textMuted)
                    }
                }
                .offset(y: CGFloat(i) * step - 1)
                .opacity(breathe ? 1 : 0.55)
            }
            // motif circles on the roll
            ForEach(0..<visible, id: \.self) { i in
                Circle().stroke(RM.seam, lineWidth: 1.6)
                    .frame(width: size.width * 0.22, height: size.width * 0.22)
                    .position(x: size.width * 0.53, y: CGFloat(i) * step + step/2)
                    .opacity(0.9)
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onDisappear { breathe = false }
    }
}

// MARK: - Wall schematic with openings (top-level outline + dimension lines)

struct WallSchematicView: View {
    let wall: Wall
    var height: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            self.content(in: geo.size)
        }
        .frame(height: height)
    }

    private func content(in size: CGSize) -> some View {
        let pad: CGFloat = 26
        let w = size.width - pad * 2
        let h = size.height - pad * 2
        let aspect = CGFloat(wall.height / max(wall.width, 0.01))
        let drawH = min(h, w * aspect)
        let drawW = drawH / max(aspect, 0.01)
        let originX = (size.width - drawW) / 2
        let originY = pad

        return ZStack(alignment: .topLeading) {
            // wall outline
            RoundedRectangle(cornerRadius: 6)
                .stroke(RM.strip, lineWidth: 2)
                .frame(width: drawW, height: drawH)
                .offset(x: originX, y: originY)
            // focal axis
            Rectangle().fill(RM.secondary.opacity(0.7))
                .frame(width: 1.4, height: drawH)
                .offset(x: originX + drawW * CGFloat(wall.centering.focalPoint), y: originY)
            // openings
            ForEach(wall.openings) { o in
                self.openingRect(o, drawW: drawW, drawH: drawH, originX: originX, originY: originY)
            }
            // width dimension line
            Text(MatchEngine.lengthString(wall.width, unit: .metric, decimals: 2))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(RM.secondary)
                .offset(x: originX + drawW/2 - 18, y: originY + drawH + 4)
            // height label
            Text(MatchEngine.lengthString(wall.height, unit: .metric, decimals: 2))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(RM.secondary)
                .rotationEffect(.degrees(-90))
                .offset(x: originX - 22, y: originY + drawH/2 - 8)
        }
    }

    private func openingRect(_ o: Opening, drawW: CGFloat, drawH: CGFloat, originX: CGFloat, originY: CGFloat) -> some View {
        let ow = drawW * CGFloat(min(o.width / max(wall.width, 0.01), 1))
        let oh = drawH * CGFloat(min(o.height / max(wall.height, 0.01), 1))
        // place windows mid-height, doors at floor
        let ox = originX + drawW * 0.3
        let oy = o.type == .door ? originY + drawH - oh : originY + drawH * 0.3
        return ZStack {
            Rectangle()
                .fill(RM.bg.opacity(0.85))
            Rectangle()
                .stroke(RM.secondary, style: StrokeStyle(lineWidth: 1.4, dash: [4, 3]))
        }
        .frame(width: max(ow, 10), height: max(oh, 10))
        .offset(x: ox, y: oy)
    }
}

// MARK: - Big metric tile

struct MetricTile: View {
    let value: String
    let label: String
    var color: Color = RM.primary
    var icon: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let icon = icon {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16, weight: .bold))
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(RM.textMain)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(RM.textSub)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 14).fill(RM.cardWhite))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
    }
}
