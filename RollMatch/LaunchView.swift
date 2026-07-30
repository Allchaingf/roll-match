//
//  LaunchView.swift
//  RollMatch
//
//  Thematic splash: a wallpaper roll unrolls top→down, two pattern fragments meet,
//  and an orange seam line "snaps" into alignment. Three simultaneous animated layers,
//  staged by a single coordinator timer, with full cleanup on disappear.
//

import SwiftUI

struct LaunchView: View {
    let onFinish: () -> Void

    // Loop flags (infinite)
    @State private var isVisible = true
    @State private var gradientShift = false
    @State private var seamShimmer = false
    @State private var motifPulse = false

    // Staged one-shot flags
    @State private var bgIn = false
    @State private var rollUnroll: CGFloat = 0     // 0 → 1 reveal
    @State private var seamSnapped = false
    @State private var logoIn = false
    @State private var exiting = false

    @State private var coordinator: Timer?
    @State private var step = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                rollAndPattern(in: geo.size)
                logo
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear(perform: start)
        .onDisappear(perform: cleanup)
    }

    // MARK: Layer 1 — background gradient shift + grid

    private var background: some View {
        ZStack {
            LinearGradient(colors: [RM.bg, RM.bgDeep],
                           startPoint: gradientShift ? .topLeading : .top,
                           endPoint: gradientShift ? .bottomTrailing : .bottom)
                .ignoresSafeArea()
            // soft orange glow that breathes
            Circle()
                .fill(RM.orangeGlow)
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .scaleEffect(motifPulse ? 1.15 : 0.85)
                .opacity(bgIn ? 0.9 : 0)
                .offset(y: -40)
        }
        .opacity(exiting ? 0 : 1)
    }

    // MARK: Layer 2 — the wallpaper roll unrolling with a snapping seam

    private func rollAndPattern(in size: CGSize) -> some View {
        let panelW = min(size.width * 0.5, 220)
        let panelH = size.height * 0.5
        return ZStack(alignment: .top) {
            // The roll "tube" at the top
            Capsule()
                .fill(LinearGradient(colors: [RM.strip, RM.strip.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                .frame(width: panelW + 30, height: 22)
                .overlay(Capsule().stroke(RM.cardBorder.opacity(0.5), lineWidth: 1))
                .offset(y: -panelH/2 - 14)
                .opacity(bgIn ? 1 : 0)

            // The unrolling panel (two halves meeting at a seam)
            ZStack {
                HStack(spacing: 0) {
                    patternHalf(width: panelW/2, height: panelH, leftSide: true)
                    patternHalf(width: panelW/2, height: panelH, leftSide: false)
                }
                .frame(width: panelW, height: panelH)
                .mask(
                    Rectangle()
                        .frame(width: panelW, height: panelH * rollUnroll, alignment: .top)
                        .frame(height: panelH, alignment: .top)
                )

                // The seam line that snaps
                Rectangle()
                    .fill(RM.seam)
                    .frame(width: seamSnapped ? 3 : 7, height: panelH * rollUnroll)
                    .shadow(color: RM.seam.opacity(0.9), radius: seamSnapped ? 8 : 2)
                    .overlay(
                        // shimmer dot travelling along the seam (infinite loop)
                        Circle()
                            .fill(RM.secondaryGlow)
                            .frame(width: 10, height: 10)
                            .offset(y: seamShimmer ? panelH/2 - 8 : -panelH/2 + 8)
                            .opacity(rollUnroll > 0.6 ? 1 : 0)
                    )
                    .frame(height: panelH, alignment: .top)
            }
            .frame(width: panelW, height: panelH)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RM.cardBorder.opacity(0.4), lineWidth: 1))
        }
        .scaleEffect(exiting ? 1.4 : 1)
        .opacity(exiting ? 0 : 1)
        .offset(y: -10)
    }

    private func patternHalf(width: CGFloat, height: CGFloat, leftSide: Bool) -> some View {
        let rows = 4
        return ZStack {
            Rectangle()
                .fill(LinearGradient(colors: [RM.strip.opacity(0.9), RM.strip.opacity(0.55)],
                                     startPoint: .top, endPoint: .bottom))
            VStack(spacing: height/CGFloat(rows) - 26) {
                ForEach(0..<rows, id: \.self) { _ in
                    HalfMotif(leftSide: leftSide, snapped: seamSnapped)
                        .frame(width: 44, height: 26)
                        .foregroundColor(RM.secondary)
                        .scaleEffect(motifPulse ? 1.06 : 0.96)
                }
            }
            .padding(.top, 14)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: Layer 3 — logo + title entrance

    private var logo: some View {
        VStack(spacing: 10) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(RM.primaryGradient)
                    .frame(width: 74, height: 74)
                    .shadow(color: RM.orangeGlow, radius: 16, y: 6)
                Image(systemName: "square.grid.3x3.topleft.filled")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(RM.bg)
            }
            .scaleEffect(logoIn ? 1 : 0.4)
            .opacity(logoIn ? 1 : 0)

            Text("Roll Match")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(RM.textHead)
                .opacity(logoIn ? 1 : 0)
                .offset(y: logoIn ? 0 : 16)

            Text("Match the pattern, not the panic.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RM.textMuted)
                .opacity(logoIn ? 1 : 0)
            Spacer().frame(height: 70)
        }
        .scaleEffect(exiting ? 1.15 : 1)
        .opacity(exiting ? 0 : 1)
    }

    // MARK: - Coordinator (single timer)

    private func start() {
        isVisible = true
        // Infinite loops
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { gradientShift = true }
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { motifPulse = true }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { seamShimmer = true }

        step = 0
        coordinator = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { t in
            guard isVisible else { t.invalidate(); return }
            step += 1
            switch step {
            case 1: // phase 1: background builds (0.2s)
                withAnimation(.easeOut(duration: 0.5)) { bgIn = true }
            case 3: // phase 2: roll unrolls (0.6s)
                withAnimation(.easeInOut(duration: 0.9)) { rollUnroll = 1 }
            case 7: // seam snaps (1.4s)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { seamSnapped = true }
            case 8: // phase 3: logo entrance (1.6s)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { logoIn = true }
            case 12: // phase 4: designed exit (2.4s)
                withAnimation(.easeIn(duration: 0.45)) { exiting = true }
            case 14: // finish (2.8s)
                t.invalidate()
                onFinish()
            default:
                break
            }
        }
    }

    private func cleanup() {
        isVisible = false
        coordinator?.invalidate()
        coordinator = nil
        gradientShift = false
        seamShimmer = false
        motifPulse = false
    }
}

// A half motif that completes when the seam snaps (two halves form a full diamond).
private struct HalfMotif: View {
    let leftSide: Bool
    let snapped: Bool
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width
                let h = geo.size.height
                if leftSide {
                    p.move(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: snapped ? 0 : w * 0.4, y: h/2))
                    p.addLine(to: CGPoint(x: w, y: h))
                } else {
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: snapped ? w : w * 0.6, y: h/2))
                    p.addLine(to: CGPoint(x: 0, y: h))
                }
            }
            .stroke(RM.secondary, lineWidth: 2.2)
        }
    }
}
