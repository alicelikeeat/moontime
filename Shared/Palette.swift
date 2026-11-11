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

/// Colors taken from the MoonTime design canvas.
enum Palette {
    // Light screens (Today, Inbox, Review)
    static let accent = Color(hex: 0x0060DF)
    static let background = Color(hex: 0xF2F2F7)
    static let label = Color(hex: 0x1C1C1E)
    static let secondaryLabel = Color(hex: 0x6C6C70)
    static let tertiaryLabel = Color(hex: 0x3A3A3C)
    static let gridLine = Color(hex: 0xD8D8DE)
    static let nowLine = Color(hex: 0xD70015)
    static let freeSlotBorder = Color(hex: 0xA8A8B0)
    static let freeSlotText = Color(hex: 0x5A5A5F)
    static let plannedBar = Color(hex: 0xB9D3F7)
    static let softAccentFill = Color(hex: 0xE8EFFC)
    static let softAccentText = Color(hex: 0x0050BA)

    // Dark focus screen
    static let focusBackground = Color(hex: 0x0E0F14)
    static let focusAccent = Color(hex: 0x2563EB)
    static let focusSecondary = Color(hex: 0xA9ABB8)
    static let moon = Color(hex: 0xC7B8FF)

    // Lock screen / Dynamic Island
    static let liveAccent = Color(hex: 0x8AB4FF)
    static let liveBackground = Color(hex: 0x141622)
    static let reminderIconFill = Color(hex: 0x4A2A0A)
    static let reminderIcon = Color(hex: 0xFDBA74)
    static let islandIconFill = Color(hex: 0x1F2A4D)
}
