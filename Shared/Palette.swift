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

/// App colours.
///
/// "Moonlight" (default): warm paper background, ink text, one calm indigo
/// accent, muted category pastels of equal lightness and a coral "now".
/// "White": white glass with all-black text and icons.
enum Palette {
    static let schemeKey = "appearance.palette"

    /// true = white scheme. Updated by the app when the setting changes
    /// (the root view is rebuilt then).
    static var monochrome: Bool = (UserDefaults.standard.string(forKey: schemeKey) ?? "colour") == "white"

    private static func pick(_ white: Color, _ moon: Color) -> Color { monochrome ? white : moon }

    // Ink and paper
    static var label: Color { pick(.black, Color(hex: 0x1D1D1F)) }
    static var secondaryLabel: Color { pick(.black, Color(hex: 0x86868B)) }
    static var tertiaryLabel: Color { pick(.black, Color(hex: 0x48484D)) }
    static var background: Color { pick(.white, Color(hex: 0xF8F7F4)) }
    static var gridLine: Color { pick(Color(hex: 0xE5E5EA), Color(hex: 0xE8E5DF)) }

    // One accent
    static var accent: Color { pick(.black, Color(hex: 0x4F5BD5)) }
    /// Fill behind prominent buttons; nil = untinted (white) glass.
    static var accentFill: Color? { monochrome ? nil : Color(hex: 0x4F5BD5) }
    static var onAccent: Color { pick(.black, .white) }
    static var softAccentFill: Color { pick(Color(hex: 0xF2F2F7), Color(hex: 0xECEEFB)) }
    static var softAccentText: Color { pick(.black, Color(hex: 0x3C47B8)) }
    static var nowLine: Color { pick(.black, Color(hex: 0xE5675A)) }

    static var freeSlotBorder: Color { pick(Color(hex: 0xA8A8B0), Color(hex: 0xC9C5BC)) }
    static var freeSlotText: Color { pick(.black, Color(hex: 0x86868B)) }
    static var plannedBar: Color { pick(Color(hex: 0xE5E5EA), Color(hex: 0xDCDFF7)) }

    // Focus screen: midnight with an indigo glow (white in the white scheme)
    static var focusBackground: Color { pick(.white, Color(hex: 0x0D0F1C)) }
    static var focusForeground: Color { pick(.black, Color(hex: 0xF4F4F8)) }
    static var focusAccent: Color { pick(.black, Color(hex: 0x7C8BFF)) }
    static var focusAccentFill: Color? { monochrome ? nil : Color(hex: 0x4F5BD5) }
    static var focusSecondary: Color { pick(.black, Color(hex: 0x9A9DB4)) }
    static var focusTrack: Color { pick(Color.black.opacity(0.06), Color.white.opacity(0.08)) }
    static var moon: Color { pick(.black, Color(hex: 0xCBC4FF)) }

    // Lock screen / Dynamic Island (always on dark)
    static var liveAccent: Color { pick(.white, Color(hex: 0xA9B4FF)) }
    static let liveBackground = Color(hex: 0x12142A)
    static var reminderIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x3A2620)) }
    static var reminderIcon: Color { pick(.white, Color(hex: 0xF3A68C)) }
    static var islandIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x23284D)) }

    /// Colours people can pick for habits and countdowns: same lightness,
    /// low saturation, so any mix sits well together.
    static let choices: [UInt32] = [0x4F5BD5, 0x8E6BBF, 0x3F8F6B, 0xC48A3A, 0xD9675A, 0x5E6675]

    /// A picked colour as shown. Older saved colours map to the new set;
    /// the white scheme shows everything in black.
    static func tone(_ hex: UInt32) -> Color {
        if monochrome { return .black }
        let legacy: [UInt32: UInt32] = [
            0x0060DF: 0x4F5BD5, 0x5B3FD9: 0x8E6BBF, 0x00796B: 0x3F8F6B,
            0xC2410C: 0xC48A3A, 0xD70015: 0xD9675A, 0x3A3A3C: 0x5E6675,
        ]
        return Color(hex: legacy[hex] ?? hex)
    }
}
