import ActivityKit
import Foundation

/// Data shown in the Live Activity (lock screen + Dynamic Island) and
/// mirrored by the in-app focus screen.
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable, Hashable {
            case focusing
            case paused
            /// "Next block starts in 5 minutes" alert. The timer keeps running.
            case reminder
        }

        var phase: Phase
        /// Shifted forward on resume so `endsAt - startedAt` is always the planned length.
        var startedAt: Date
        var endsAt: Date
        /// Time left, frozen while paused.
        var pausedRemaining: TimeInterval?
        var nextTitle: String?
        var nextStart: Date?
        /// When to show the "next block" reminder. nil = no reminder pending.
        var remindAt: Date?

        var isPaused: Bool { phase == .paused }
        var total: TimeInterval { max(1, endsAt.timeIntervalSince(startedAt)) }
        var timerRange: ClosedRange<Date> { startedAt...max(startedAt, endsAt) }

        func remaining(at now: Date) -> TimeInterval {
            isPaused ? (pausedRemaining ?? 0) : max(0, endsAt.timeIntervalSince(now))
        }

        func elapsed(at now: Date) -> TimeInterval { total - remaining(at: now) }

        func progress(at now: Date) -> Double {
            min(1, max(0, elapsed(at: now) / total))
        }
    }

    var blockID: UUID
    var taskTitle: String
    var categoryName: String
}

enum FocusChange: Hashable {
    case togglePause
    case extend(TimeInterval)
    case showReminder
    case snoozeReminder(TimeInterval)
    case dismissReminder
}

extension FocusActivityAttributes.ContentState {
    func applying(_ change: FocusChange, now: Date = .now) -> Self {
        var s = self
        switch change {
        case .togglePause:
            if isPaused {
                let left = pausedRemaining ?? 0
                let length = total
                s.endsAt = now.addingTimeInterval(left)
                s.startedAt = s.endsAt.addingTimeInterval(-length)
                s.pausedRemaining = nil
                s.phase = .focusing
            } else {
                s.pausedRemaining = max(0, endsAt.timeIntervalSince(now))
                s.phase = .paused
            }
        case .extend(let seconds):
            s.endsAt = endsAt.addingTimeInterval(seconds)
            if isPaused { s.pausedRemaining = (pausedRemaining ?? 0) + seconds }
        case .showReminder:
            if !isPaused { s.phase = .reminder }
            s.remindAt = nil
        case .snoozeReminder(let seconds):
            if phase == .reminder { s.phase = .focusing }
            s.remindAt = now.addingTimeInterval(seconds)
        case .dismissReminder:
            if phase == .reminder { s.phase = .focusing }
            s.remindAt = nil
        }
        return s
    }
}
