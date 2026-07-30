//
//  DesignSystem.swift
//  RollMatch
//
//  Reusable component library: backgrounds, cards, buttons, fields, chips, badges.
//  Built so every screen shares the night-blue construction look without repetition.
//

import SwiftUI

// MARK: - Screen background

struct RMBackground: View {
    var body: some View {
        ZStack {
            RM.bgGradient.ignoresSafeArea()
            // Faint blueprint grid for depth.
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 34
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += step
                    }
                }
                .stroke(RM.divider, lineWidth: 0.5)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Card

struct RMCard<Content: View>: View {
    var light: Bool = true       // white card vs light-blue
    var padding: CGFloat = 16
    let content: Content
    init(light: Bool = true, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.light = light
        self.padding = padding
        self.content = content()
    }
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(light ? RM.cardWhite : RM.cardBlue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(RM.cardBorder, lineWidth: 1)
            )
            .shadow(color: RM.shadow, radius: 10, x: 0, y: 6)
    }
}

// MARK: - Detail screen scaffold (dark bg + scroll + nav title)

struct DetailScaffold<Content: View>: View {
    let title: String
    var caption: String? = nil
    let content: Content
    init(_ title: String, caption: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content()
    }
    var body: some View {
        ZStack {
            RMBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if let caption = caption {
                        Text(caption)
                            .font(.system(size: 14))
                            .foregroundColor(RM.textMuted)
                    }
                    content
                    Spacer().frame(height: 40)
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section header (white, for use on dark bg)

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(RM.secondary)
                    .font(.system(size: 18, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RM.textHead)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(RM.textMuted)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: LinearGradient = RM.primaryGradient
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(RM.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(fill)
            .cornerRadius(15)
            .shadow(color: RM.orangeGlow, radius: 12, x: 0, y: 6)
        }
        .scaleEffect(pressed ? 0.96 : 1)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @State private var pressed = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(RM.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RM.secondaryGradient)
            .cornerRadius(15)
            .shadow(color: RM.yellowGlow, radius: 10, x: 0, y: 5)
        }
        .scaleEffect(pressed ? 0.96 : 1)
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(RM.strip)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(RM.strip.opacity(0.6), lineWidth: 1.4)
            )
        }
    }
}

struct DangerButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RM.defect)
            .cornerRadius(14)
        }
    }
}

/// Small navigation row used inside tab hubs.
struct NavRow: View {
    let number: String
    let title: String
    let subtitle: String
    let icon: String
    var accent: Color = RM.primary
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accent.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RM.textMain)
                Text(subtitle)
                    .font(.system(size: 12.5))
                    .foregroundColor(RM.textSub)
                    .lineLimit(2)
            }
            Spacer()
            Text(number)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(RM.textMuted)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(RM.textMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(RM.cardWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RM.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Text & number fields

struct RMTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(RM.textSub)
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon).foregroundColor(RM.textMuted)
                }
                TextField(placeholder, text: $text)
                    .foregroundColor(RM.textMain)
                    .accentColor(RM.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RM.cardBorder, lineWidth: 1))
        }
    }
}

struct RMNumberField: View {
    let title: String
    @Binding var value: Double
    var unit: String = ""
    var icon: String? = nil
    @State private var textValue: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(RM.textSub)
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon).foregroundColor(RM.textMuted)
                }
                TextField("0", text: Binding(
                    get: { textValue },
                    set: { newVal in
                        textValue = newVal
                        let cleaned = newVal.replacingOccurrences(of: ",", with: ".")
                        if let d = Double(cleaned) { value = d }
                        else if newVal.isEmpty { value = 0 }
                    }
                ))
                .keyboardType(.decimalPad)
                .foregroundColor(RM.textMain)
                .accentColor(RM.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(RM.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RM.cardBorder, lineWidth: 1))
        }
        .onAppear { textValue = trimmed(value) }
    }
    private func trimmed(_ d: Double) -> String {
        if d == d.rounded() { return String(format: "%.0f", d) }
        return String(format: "%.2f", d)
    }
}

struct RMIntStepper: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...999
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(RM.textSub)
            HStack {
                Button(action: { if value > range.lowerBound { value -= 1 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RM.bg)
                        .frame(width: 38, height: 38)
                        .background(RM.secondary)
                        .cornerRadius(10)
                }
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RM.textMain)
                    .frame(maxWidth: .infinity)
                Button(action: { if value < range.upperBound { value += 1 } }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RM.bg)
                        .frame(width: 38, height: 38)
                        .background(RM.primary)
                        .cornerRadius(10)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(RM.cardBlue))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RM.cardBorder, lineWidth: 1))
        }
    }
}

// MARK: - Chips & segmented selectors

struct RMChip: View {
    let label: String
    var icon: String? = nil
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon { Image(systemName: icon).font(.system(size: 13, weight: .bold)) }
                Text(label).font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(selected ? RM.bg : RM.textSub)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(selected ? RM.primary : RM.cardBlue)
            )
            .overlay(
                Capsule().stroke(selected ? RM.primary : RM.cardBorder, lineWidth: 1.3)
            )
        }
    }
}

/// Generic enum picker rendered as wrapping chips.
struct EnumChips<T: Identifiable & Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    var icon: ((T) -> String)? = nil
    var body: some View {
        FlowChips(items: items) { item in
            RMChip(label: label(item),
                   icon: icon?(item),
                   selected: item == selection) {
                selection = item
            }
        }
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let text: String
    let color: Color
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon { Image(systemName: icon).font(.system(size: 11, weight: .bold)) }
            Text(text).font(.system(size: 12, weight: .heavy))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.16)))
    }
}

// MARK: - Toast confirmation

struct ToastView: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(RM.ok)
            Text(message).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(RM.bgSoft))
        .overlay(Capsule().stroke(RM.ok.opacity(0.5), lineWidth: 1))
        .shadow(color: RM.shadow, radius: 10, y: 5)
    }
}

/// Drop-in modifier to flash a confirmation toast.
struct ToastModifier: ViewModifier {
    @Binding var show: Bool
    let message: String
    func body(content: Content) -> some View {
        ZStack {
            content
            if show {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation { show = false }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(_ show: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(show: show, message: message))
    }
}

// MARK: - Wrapping chip layout (iOS 14 compatible, GeometryReader + PreferenceKey)

struct FlowChips<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    var spacing: CGFloat = 8
    let content: (Data.Element) -> Content
    @State private var totalHeight: CGFloat = 0

    var body: some View {
        VStack {
            GeometryReader { geo in
                self.generate(in: geo)
            }
        }
        .frame(height: totalHeight)
    }

    private func generate(in geo: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        let maxWidth = geo.size.width
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > maxWidth {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == Array(items).last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == Array(items).last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(heightReader)
    }

    private var heightReader: some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                self.totalHeight = geo.size.height
            }
            return Color.clear
        }
    }
}
