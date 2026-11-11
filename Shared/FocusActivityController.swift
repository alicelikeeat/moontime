import ActivityKit
import Foundation

extension Notification.Name {
    /// userInfo: ["state": FocusActivityAttributes.ContentState]
    static let focusActivityChanged = Notification.Name("MoonTime.focusActivityChanged")
    /// userInfo: ["blockID": UUID, "state": FocusActivityAttributes.ContentState]
    static let focusActivityCompleted = Notification.Name("MoonTime.focusActivityCompleted")
}

/// Starts, updates and ends the focus Live Activity.
/// Used by the app and by the Live Activity buttons (which run in the app's process).
enum FocusActivityController {
    typealias State = FocusActivityAttributes.ContentState

    static var current: Activity<FocusActivityAttributes>? {
        Activity<FocusActivityAttributes>.activities.first
    }

    static func start(blockID: UUID, title: String, categoryName: String, state: State) async {
        await endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = FocusActivityAttributes(blockID: blockID, taskTitle: title, categoryName: categoryName)
        _ = try? Activity.request(attributes: attributes, content: content(for: state), pushType: nil)
    }

    static func push(_ state: State, alert: AlertConfiguration? = nil) async {
        guard let activity = current else { return }
        if let alert {
            await activity.update(content(for: state), alertConfiguration: alert)
        } else {
            await activity.update(content(for: state))
        }
    }

    static func endAll() async {
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: Called from Live Activity buttons

    static func apply(_ change: FocusChange) async {
        guard let activity = current else { return }
        let state = activity.content.state.applying(change)
        await push(state)
        NotificationCenter.default.post(name: .focusActivityChanged, object: nil, userInfo: ["state": state])
    }

    static func complete() async {
        guard let activity = current else { return }
        let blockID = activity.attributes.blockID
        let state = activity.content.state
        await endAll()
        NotificationCenter.default.post(
            name: .focusActivityCompleted, object: nil,
            userInfo: ["blockID": blockID, "state": state]
        )
    }

    private static func content(for state: State) -> ActivityContent<State> {
        ActivityContent(state: state, staleDate: state.isPaused ? nil : state.endsAt)
    }
}
