import ActivityKit
import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class DayStore {
    var blocks: [TimeBlock]
    var inbox: [InboxItem]
    var selectedDate: Date
    var focus: ActiveFocus?
    var reflection = ""

    /// Free time is measured inside this window.
    let workdayHours = 8..<17

    @ObservationIgnored private let calendar = Calendar.current
    @ObservationIgnored private let isUITesting: Bool
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var reminderTask: Task<Void, Never>?
    private static let reminderNotificationID = "moontime.next-block"

    init(now: Date = .now) {
        let today = Calendar.current.startOfDay(for: now)
        selectedDate = today
        let arguments = ProcessInfo.processInfo.arguments
        isUITesting = arguments.contains("-UITests")
        blocks = arguments.contains("-EveningDemo") ? SampleData.eveningBlocks(on: today) : SampleData.blocks(on: today)
        inbox = SampleData.inbox
        observeLiveActivityButtons()
    }

    // MARK: Queries

    func blocks(on day: Date) -> [TimeBlock] {
        blocks.filter { calendar.isDate($0.start, inSameDayAs: day) }.sorted { $0.start < $1.start }
    }

    var selectedBlocks: [TimeBlock] { blocks(on: selectedDate) }
    var todayBlocks: [TimeBlock] { blocks(on: .now) }

    func scheduledTime(on day: Date) -> TimeInterval {
        blocks(on: day).reduce(0) { $0 + $1.duration }
    }

    func freeTime(on day: Date) -> TimeInterval {
        let window = workdayWindow(on: day).duration
        return max(0, window - scheduledTime(on: day))
    }

    /// Gaps of at least `minimum` inside the workday.
    func freeSlots(on day: Date, minimum: TimeInterval = 3600) -> [DateInterval] {
        gaps(on: day, in: workdayWindow(on: day)).filter { $0.duration >= minimum }
    }

    func block(withID id: UUID) -> TimeBlock? { blocks.first { $0.id == id } }

    func nextBlock(after block: TimeBlock) -> TimeBlock? {
        blocks(on: block.start).first { $0.start >= block.end && !$0.isDone }
    }

    /// The deep-work block to offer on the empty focus screen.
    func suggestedFocusBlock(now: Date = .now) -> TimeBlock? {
        blocks(on: now).first { $0.category == .deepWork && !$0.isDone && $0.end > now }
            ?? blocks(on: now).first { !$0.isDone && $0.end > now }
    }

    // MARK: Editing

    func add(_ block: TimeBlock) {
        blocks.append(block)
    }

    func toggleDone(_ id: UUID) {
        guard let i = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[i].isDone.toggle()
        blocks[i].actualDuration = blocks[i].isDone ? blocks[i].duration : nil
    }

    func delete(_ id: UUID) {
        if focus?.blockID == id { cancelFocus() }
        blocks.removeAll { $0.id == id }
    }

    func moveToTomorrow(_ id: UUID) {
        guard let i = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[i].start = calendar.date(byAdding: .day, value: 1, to: blocks[i].start) ?? blocks[i].start
        blocks[i].end = calendar.date(byAdding: .day, value: 1, to: blocks[i].end) ?? blocks[i].end
    }

    /// Puts an inbox item into the first gap that fits on the selected day.
    func schedule(_ item: InboxItem) {
        let day = selectedDate
        let window = DateInterval(start: hour(8, on: day), end: hour(22, on: day))
        let gap = gaps(on: day, in: window).first { $0.duration >= item.estimate }
        let start = gap?.start ?? (blocks(on: day).last?.end ?? hour(9, on: day))
        add(TimeBlock(title: item.title, start: start, end: start.addingTimeInterval(item.estimate), category: .life))
        inbox.removeAll { $0.id == item.id }
    }

    // MARK: Focus

    func startFocus(_ block: TimeBlock, now: Date = .now) {
        let endsAt = (block.start...block.end).contains(now) ? block.end : now.addingTimeInterval(block.duration)
        let next = nextBlock(after: block)
        let state = FocusActivityAttributes.ContentState(
            phase: .focusing,
            startedAt: now,
            endsAt: endsAt,
            pausedRemaining: nil,
            nextTitle: next?.title,
            nextStart: next?.start,
            remindAt: next.map { $0.start.addingTimeInterval(-5 * 60) }
        )
        focus = ActiveFocus(
            blockID: block.id, title: block.title, category: block.category,
            plannedDuration: endsAt.timeIntervalSince(now), state: state
        )
        requestNotificationPermission()
        scheduleReminder()
        Task {
            await FocusActivityController.start(
                blockID: block.id, title: block.title, categoryName: block.category.name, state: state
            )
        }
    }

    func togglePause() { change(.togglePause) }
    func extendFocus() { change(.extend(15 * 60)) }
    func snoozeReminder() { change(.snoozeReminder(10 * 60)) }
    func dismissReminder() { change(.dismissReminder) }

    func completeFocus(now: Date = .now) {
        guard let focus else { return }
        finish(blockID: focus.blockID, state: focus.state, now: now)
        Task { await FocusActivityController.endAll() }
    }

    func cancelFocus() {
        focus = nil
        clearReminder()
        Task { await FocusActivityController.endAll() }
    }

    /// Pull the latest state from the Live Activity when the app comes back.
    func syncWithLiveActivity() {
        guard let activity = FocusActivityController.current,
              focus?.blockID == activity.attributes.blockID else { return }
        focus?.state = activity.content.state
        scheduleReminder()
    }

    private func change(_ change: FocusChange, alert: AlertConfiguration? = nil) {
        guard var focus else { return }
        if change == .togglePause, !focus.state.isPaused { focus.pauseCount += 1 }
        focus.state = focus.state.applying(change)
        self.focus = focus
        scheduleReminder()
        let state = focus.state
        Task { await FocusActivityController.push(state, alert: alert) }
    }

    private func finish(blockID: UUID, state: FocusActivityAttributes.ContentState, now: Date) {
        if let i = blocks.firstIndex(where: { $0.id == blockID }) {
            blocks[i].isDone = true
            blocks[i].actualDuration = state.elapsed(at: now)
        }
        focus = nil
        clearReminder()
    }

    // MARK: Next-block reminder

    /// In the foreground a timer flips the Live Activity into its reminder state.
    /// In the background a local notification covers it (updating a Live Activity
    /// from the background needs ActivityKit push notifications from a server).
    private func scheduleReminder() {
        clearReminder()
        guard let focus, let remindAt = focus.state.remindAt, let nextTitle = focus.state.nextTitle else { return }
        let delay = remindAt.timeIntervalSinceNow
        let nextStart = focus.state.nextStart ?? remindAt

        let body = "\(TimeFormat.clock(nextStart)) 开始 · 当前专注会自动保存"
        let title = "\(nextTitle) 即将开始"

        if delay > 0 {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: Self.reminderNotificationID, content: content, trigger: trigger)
            )
        }

        reminderTask = Task { [weak self] in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled, let self, self.focus?.state.remindAt == remindAt else { return }
            let alert = AlertConfiguration(title: "\(title)", body: "\(body)", sound: .default)
            self.change(.showReminder, alert: alert)
        }
    }

    private func clearReminder() {
        reminderTask?.cancel()
        reminderTask = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderNotificationID])
    }

    private func requestNotificationPermission() {
        // A system permission alert would block the screenshot tests.
        guard !isUITesting else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: Live Activity buttons

    private func observeLiveActivityButtons() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .focusActivityChanged, object: nil, queue: .main) { [weak self] note in
            guard let state = note.userInfo?["state"] as? FocusActivityAttributes.ContentState else { return }
            MainActor.assumeIsolated {
                guard let self, var focus = self.focus else { return }
                if state.isPaused, !focus.state.isPaused { focus.pauseCount += 1 }
                focus.state = state
                self.focus = focus
                self.scheduleReminder()
            }
        })
        observers.append(center.addObserver(forName: .focusActivityCompleted, object: nil, queue: .main) { [weak self] note in
            guard let id = note.userInfo?["blockID"] as? UUID,
                  let state = note.userInfo?["state"] as? FocusActivityAttributes.ContentState else { return }
            MainActor.assumeIsolated {
                self?.finish(blockID: id, state: state, now: .now)
            }
        })
    }

    // MARK: Helpers

    private func hour(_ h: Int, on day: Date) -> Date {
        calendar.date(bySettingHour: h, minute: 0, second: 0, of: day) ?? day
    }

    private func workdayWindow(on day: Date) -> DateInterval {
        DateInterval(start: hour(workdayHours.lowerBound, on: day), end: hour(workdayHours.upperBound, on: day))
    }

    private func gaps(on day: Date, in window: DateInterval) -> [DateInterval] {
        var result: [DateInterval] = []
        var cursor = window.start
        for block in blocks(on: day) {
            if block.start > cursor, cursor < window.end {
                result.append(DateInterval(start: cursor, end: min(block.start, window.end)))
            }
            cursor = max(cursor, block.end)
        }
        if cursor < window.end { result.append(DateInterval(start: cursor, end: window.end)) }
        return result
    }
}
