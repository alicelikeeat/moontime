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
        if Palette.monochrome { return .white }
        return switch self {
        case .planning: Color(hex: 0xEEE6FB)
        case .deepWork: Color(hex: 0xDCEAFF)
        case .meeting: Color(hex: 0xFFE9D6)
        case .life: Color(hex: 0xE6E6EB)
        case .exercise: Color(hex: 0xDDF3E2)
        }
    }

    /// Text color for titles on top of `fill`.
    var title: Color {
        if Palette.monochrome { return Palette.label }
        return switch self {
        case .planning: Color(hex: 0x5B2EA6)
        case .deepWork: Color(hex: 0x0B3570)
        case .meeting: Color(hex: 0x6B2F00)
        case .life: Color(hex: 0x3A3A3C)
        case .exercise: Color(hex: 0x145A2A)
        }
    }

    /// Text color for secondary lines on top of `fill`.
    var detail: Color {
        if Palette.monochrome { return Palette.secondaryLabel }
        return switch self {
        case .planning: Color(hex: 0x6B4FA0)
        case .deepWork: Color(hex: 0x1F4E8C)
        case .meeting: Color(hex: 0x8A3D00)
        case .life: Color(hex: 0x5A5A5F)
        case .exercise: Color(hex: 0x1E6B35)
        }
    }

    /// Categories shown in the evening "plan vs actual" chart.
    static let reviewed: [BlockCategory] = [.deepWork, .meeting, .life, .exercise]
}
