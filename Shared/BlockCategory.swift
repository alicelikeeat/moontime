import SwiftUI

enum BlockCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case planning, deepWork, meeting, life, exercise

    var id: String { rawValue }

    var name: String {
        switch self {
        case .planning: "规划"
        case .deepWork: "深度工作"
        case .meeting: "会议"
        case .life: "生活"
        case .exercise: "运动"
        }
    }

    var fill: Color {
        if !Palette.usesColour { return Palette.surface }
        return switch self {
        case .planning: Color(hex: 0xEEECF8)
        case .deepWork: Color(hex: 0xE9EDFB)
        case .meeting: Color(hex: 0xF6EFE4)
        case .life: Color(hex: 0xEFEEEA)
        case .exercise: Color(hex: 0xE7F1EA)
        }
    }

    /// Text color for titles on top of `fill`.
    var title: Color {
        if !Palette.usesColour { return Palette.label }
        return switch self {
        case .planning: Color(hex: 0x4A4589)
        case .deepWork: Color(hex: 0x2E3B8C)
        case .meeting: Color(hex: 0x6E4A1F)
        case .life: Color(hex: 0x45453F)
        case .exercise: Color(hex: 0x2D5B42)
        }
    }

    /// Text color for secondary lines on top of `fill`.
    var detail: Color {
        if !Palette.usesColour { return Palette.secondaryLabel }
        return switch self {
        case .planning: Color(hex: 0x77729F)
        case .deepWork: Color(hex: 0x5C67A8)
        case .meeting: Color(hex: 0x957556)
        case .life: Color(hex: 0x7A7A73)
        case .exercise: Color(hex: 0x5E8670)
        }
    }

    /// Categories shown in the evening "plan vs actual" chart.
    static let reviewed: [BlockCategory] = [.deepWork, .meeting, .life, .exercise]
}
