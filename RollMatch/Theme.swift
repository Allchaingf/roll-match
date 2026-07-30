//
//  Theme.swift
//  RollMatch
//
//  Color palette, theme mode and app-wide settings (MVVM environment object).
//

import SwiftUI
import Combine

// MARK: - Hex color support

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r, g, b, a: Double
        switch s.count {
        case 8: // RRGGBBAA
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        default: // RRGGBB
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Palette (night-blue construction theme)

enum RM {
    // Backgrounds
    static let bg = Color(hex: "0E1A2E")
    static let bgDeep = Color(hex: "091324")
    static let bgSoft = Color(hex: "15243C")

    // Cards
    static let cardWhite = Color(hex: "FFFFFF")
    static let cardBlue = Color(hex: "E7F0FB")
    static let cardHover = Color(hex: "DCEAF8")
    static let cardBorder = Color(hex: "C7D9EE")
    static let divider = Color(red: 120/255, green: 170/255, blue: 255/255, opacity: 0.12)

    // Primary (orange)
    static let primary = Color(hex: "F77A1E")
    static let primaryActive = Color(hex: "E0650C")
    static let primaryGlowEdge = Color(hex: "FF9A4D")

    // Secondary (yellow)
    static let secondary = Color(hex: "F5C026")
    static let secondaryGlow = Color(hex: "FFD964")

    // Structural / strips
    static let strip = Color(hex: "4DA3F0")
    static let seam = Color(hex: "F77A1E")

    // Statuses
    static let ok = Color(hex: "38C172")
    static let inWork = Color(hex: "4DA3F0")
    static let warn = Color(hex: "F5C026")
    static let defect = Color(hex: "EF4444")

    // Text (on light cards)
    static let textHead = Color(hex: "FFFFFF")
    static let textMain = Color(hex: "102A4A")
    static let textSub = Color(hex: "44587A")
    static let textMuted = Color(hex: "8AA0BE")

    // Effects
    static let orangeGlow = Color(red: 247/255, green: 122/255, blue: 30/255, opacity: 0.35)
    static let yellowGlow = Color(red: 245/255, green: 192/255, blue: 38/255, opacity: 0.28)
    static let shadow = Color(black: 0, opacity: 0.55)

    // Gradients
    static var bgGradient: LinearGradient {
        LinearGradient(colors: [bg, bgDeep], startPoint: .top, endPoint: .bottom)
    }
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primaryGlowEdge, primary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var secondaryGradient: LinearGradient {
        LinearGradient(colors: [secondaryGlow, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    /// Convenience grayscale-with-alpha initializer used above.
    init(black: Double, opacity: Double) {
        self.init(.sRGB, red: black, green: black, blue: black, opacity: opacity)
    }
}

// MARK: - Theme mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system, dark, light
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.fill"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

// MARK: - Units

enum MeasureUnit: String, CaseIterable, Identifiable, Codable {
    case metric   // metres / centimetres
    case imperial // feet / inches
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric (m)" : "Imperial (ft)" }
    var big: String { self == .metric ? "m" : "ft" }
    var small: String { self == .metric ? "cm" : "in" }
}

// MARK: - App settings (theme + preferences), persisted via @AppStorage

final class AppSettings: ObservableObject {
    @AppStorage("themeMode") var themeModeRaw: String = ThemeMode.system.rawValue {
        willSet { objectWillChange.send() }
    }
    @AppStorage("units") var unitsRaw: String = MeasureUnit.metric.rawValue {
        willSet { objectWillChange.send() }
    }
    @AppStorage("currency") var currency: String = "$" {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("accentYellow") var accentYellow: Bool = false {
        willSet { objectWillChange.send() }
    }

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }
    var units: MeasureUnit {
        get { MeasureUnit(rawValue: unitsRaw) ?? .metric }
        set { unitsRaw = newValue.rawValue }
    }

    /// Primary accent reflects the "accentYellow" toggle so Settings visibly changes the app.
    var accent: Color { accentYellow ? RM.secondary : RM.primary }
    var accentGradient: LinearGradient { accentYellow ? RM.secondaryGradient : RM.primaryGradient }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticsEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
    }
}
