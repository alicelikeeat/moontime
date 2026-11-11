import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// App colours, in three schemes:
/// - minimal (default): white page, near-black ink, grey surfaces, black
///   primary buttons; glass only on floating controls.
/// - moon: warm paper, ink, one indigo accent, muted category pastels.
/// - white: white glass with all-black text and icons.
enum Palette {
    enum Scheme: String { case minimal, moon = "colour", white }

    static let schemeKey = "appearance.palette"

    /// Updated by the app when the setting changes (the root view is rebuilt then).
    static var scheme: Scheme = Scheme(rawValue: UserDefaults.standard.string(forKey: schemeKey) ?? "") ?? .minimal

    static var monochrome: Bool { scheme == .white }
    /// Content cards are flat grey instead of glass.
    static var flatContent: Bool { scheme == .minimal }

    private static func pick(_ minimal: Color, _ moon: Color, _ white: Color) -> Color {
        switch scheme {
        case .minimal: minimal
        case .moon: moon
        case .white: white
        }
    }

    // Ink and paper
    static var label: Color { pick(Color(hex: 0x0D0D0D), Color(hex: 0x1D1D1F), .black) }
    static var secondaryLabel: Color { pick(Color(hex: 0x8F8F8F), Color(hex: 0x86868B), .black) }
    static var tertiaryLabel: Color { pick(Color(hex: 0x424242), Color(hex: 0x48484D), .black) }
    static var background: Color { pick(.white, Color(hex: 0xF8F7F4), .white) }
    /// Flat card fill (minimal scheme).
    static var surface: Color { pick(Color(hex: 0xF4F4F4), Color(hex: 0xF2F1EE), Color(hex: 0xF4F4F4)) }
    static var gridLine: Color { pick(Color(hex: 0xEDEDED), Color(hex: 0xE8E5DF), Color(hex: 0xE5E5EA)) }

    // Accent
    static var accent: Color { pick(Color(hex: 0x0D0D0D), Color(hex: 0x4F5BD5), .black) }
    /// Fill behind primary buttons; nil = untinted glass.
    static var accentFill: Color? {
        switch scheme {
        case .minimal: Color(hex: 0x0D0D0D)
        case .moon: Color(hex: 0x4F5BD5)
        case .white: nil
        }
    }
    static var onAccent: Color { pick(.white, .white, .black) }
    static var softAccentFill: Color { pick(Color(hex: 0xF4F4F4), Color(hex: 0xECEEFB), Color(hex: 0xF2F2F7)) }
    static var softAccentText: Color { pick(Color(hex: 0x0D0D0D), Color(hex: 0x3C47B8), .black) }
    static var nowLine: Color { pick(Color(hex: 0x0D0D0D), Color(hex: 0xE5675A), .black) }

    static var freeSlotBorder: Color { pick(Color(hex: 0xD9D9D9), Color(hex: 0xC9C5BC), Color(hex: 0xA8A8B0)) }
    static var freeSlotText: Color { pick(Color(hex: 0x8F8F8F), Color(hex: 0x86868B), .black) }
    static var plannedBar: Color { pick(Color(hex: 0xE3E3E3), Color(hex: 0xDCDFF7), Color(hex: 0xE5E5EA)) }

    // Focus screen
    static var focusBackground: Color { pick(Color(hex: 0x212121), Color(hex: 0x0D0F1C), .white) }
    static var focusForeground: Color { pick(Color(hex: 0xECECEC), Color(hex: 0xF4F4F8), .black) }
    static var focusAccent: Color { pick(Color(hex: 0xECECEC), Color(hex: 0x7C8BFF), .black) }
    static var focusAccentFill: Color? {
        switch scheme {
        case .minimal: Color(hex: 0xECECEC)
        case .moon: Color(hex: 0x4F5BD5)
        case .white: nil
        }
    }
    /// Text on `focusAccentFill`.
    static var onFocusAccent: Color { pick(Color(hex: 0x0D0D0D), .white, .black) }
    static var focusSecondary: Color { pick(Color(hex: 0x9B9B9B), Color(hex: 0x9A9DB4), .black) }
    static var focusTrack: Color { pick(Color.white.opacity(0.08), Color.white.opacity(0.08), Color.black.opacity(0.06)) }
    static var moon: Color { pick(Color(hex: 0xECECEC), Color(hex: 0xCBC4FF), .black) }
    static var focusIsDark: Bool { scheme != .white }

    // Lock screen / Dynamic Island (always on dark)
    static var liveAccent: Color { pick(.white, Color(hex: 0xA9B4FF), .white) }
    static let liveBackground = Color(hex: 0x12142A)
    static var reminderIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x3A2620), Color.white.opacity(0.14)) }
    static var reminderIcon: Color { pick(.white, Color(hex: 0xF3A68C), .white) }
    static var islandIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x23284D), Color.white.opacity(0.14)) }

    /// Colours people can pick for habits and countdowns (moon scheme).
    static let choices: [UInt32] = [0x4F5BD5, 0x8E6BBF, 0x3F8F6B, 0xC48A3A, 0xD9675A, 0x5E6675]

    /// A picked colour as shown: black in the minimal and white schemes;
    /// older saved colours map onto the moon set.
    static func tone(_ hex: UInt32) -> Color {
        if scheme != .moon { return label }
        let legacy: [UInt32: UInt32] = [
            0x0060DF: 0x4F5BD5, 0x5B3FD9: 0x8E6BBF, 0x00796B: 0x3F8F6B,
            0xC2410C: 0xC48A3A, 0xD70015: 0xD9675A, 0x3A3A3C: 0x5E6675,
        ]
        return Color(hex: legacy[hex] ?? hex)
    }
}
