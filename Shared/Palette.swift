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

/// App colours. With the white scheme (the default) every accent turns
/// white or grey and text stays near-black; the colour scheme keeps the
/// original design colours.
enum Palette {
    static let schemeKey = "appearance.palette"

    /// true = all-white scheme. Read once at launch and updated by the app
    /// when the setting changes (the root view is rebuilt then).
    static var monochrome: Bool = (UserDefaults.standard.string(forKey: schemeKey) ?? "white") == "white"

    private static func pick(_ white: Color, _ colour: Color) -> Color { monochrome ? white : colour }

    // Light screens
    static var accent: Color { pick(Color(hex: 0x1C1C1E), Color(hex: 0x0060DF)) }
    /// Fill behind prominent buttons; nil = untinted (white) glass.
    static var accentFill: Color? { monochrome ? nil : Color(hex: 0x0060DF) }
    /// Text and icons on top of `accentFill`.
    static var onAccent: Color { pick(Color(hex: 0x1C1C1E), .white) }
    static var background: Color { pick(.white, Color(hex: 0xF2F2F7)) }
    static let label = Color(hex: 0x1C1C1E)
    static let secondaryLabel = Color(hex: 0x6C6C70)
    static let tertiaryLabel = Color(hex: 0x3A3A3C)
    static var gridLine: Color { pick(Color(hex: 0xE5E5EA), Color(hex: 0xD8D8DE)) }
    static var nowLine: Color { pick(Color(hex: 0x1C1C1E), Color(hex: 0xD70015)) }
    static let freeSlotBorder = Color(hex: 0xA8A8B0)
    static let freeSlotText = Color(hex: 0x5A5A5F)
    static var plannedBar: Color { pick(Color(hex: 0xE5E5EA), Color(hex: 0xB9D3F7)) }
    static var softAccentFill: Color { pick(Color(hex: 0xF2F2F7), Color(hex: 0xE8EFFC)) }
    static var softAccentText: Color { pick(Color(hex: 0x1C1C1E), Color(hex: 0x0050BA)) }

    // Focus screen (white in the white scheme, dark otherwise)
    static var focusBackground: Color { pick(.white, Color(hex: 0x0E0F14)) }
    static var focusForeground: Color { pick(Color(hex: 0x1C1C1E), .white) }
    static var focusAccent: Color { pick(Color(hex: 0x1C1C1E), Color(hex: 0x2563EB)) }
    static var focusAccentFill: Color? { monochrome ? nil : Color(hex: 0x2563EB) }
    static var focusSecondary: Color { pick(Color(hex: 0x8E8E93), Color(hex: 0xA9ABB8)) }
    static var focusTrack: Color { pick(Color.black.opacity(0.06), Color.white.opacity(0.08)) }
    static var moon: Color { pick(Color(hex: 0x1C1C1E), Color(hex: 0xC7B8FF)) }

    // Lock screen / Dynamic Island (always drawn on dark)
    static var liveAccent: Color { pick(.white, Color(hex: 0x8AB4FF)) }
    static let liveBackground = Color(hex: 0x141622)
    static var reminderIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x4A2A0A)) }
    static var reminderIcon: Color { pick(.white, Color(hex: 0xFDBA74)) }
    static var islandIconFill: Color { pick(Color.white.opacity(0.14), Color(hex: 0x1F2A4D)) }

    /// A user-picked colour (habit, countdown), greyed in the white scheme.
    static func tone(_ hex: UInt32) -> Color { monochrome ? Color(hex: 0x1C1C1E) : Color(hex: hex) }
}
