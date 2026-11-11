import AppIntents

// Buttons on the lock screen and in the expanded Dynamic Island.
// LiveActivityIntent runs `perform()` in the app's process.

struct ToggleFocusPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "暂停或继续专注"
    func perform() async throws -> some IntentResult {
        await FocusActivityController.apply(.togglePause)
        return .result()
    }
}

struct ExtendFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "专注延长 15 分钟"
    func perform() async throws -> some IntentResult {
        await FocusActivityController.apply(.extend(15 * 60))
        return .result()
    }
}

struct CompleteFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "完成专注"
    func perform() async throws -> some IntentResult {
        await FocusActivityController.complete()
        return .result()
    }
}

struct SnoozeReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "10 分钟后再提醒"
    func perform() async throws -> some IntentResult {
        await FocusActivityController.apply(.snoozeReminder(10 * 60))
        return .result()
    }
}

struct DismissReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "知道了"
    func perform() async throws -> some IntentResult {
        await FocusActivityController.apply(.dismissReminder)
        return .result()
    }
}
