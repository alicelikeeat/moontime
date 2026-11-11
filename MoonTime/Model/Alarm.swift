import Foundation
import Observation
import SwiftUI
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
#endif

/// An alarm at a time of day, optionally repeating on some weekdays.
struct MoonAlarm: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String = ""
    var hour: Int
    var minute: Int
    /// Calendar weekdays (1 = Sunday … 7 = Saturday). Empty = rings once.
    var weekdays: [Int] = []
    var enabled = false

    var timeText: String { String(format: "%d:%02d", hour, minute) }

    var repeatText: String {
        let set = Set(weekdays)
        if set.isEmpty { return "仅一次" }
        if set.count == 7 { return "每天" }
        if set == [2, 3, 4, 5, 6] { return "工作日" }
        if set == [1, 7] { return "周末" }
        let names = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        return [2, 3, 4, 5, 6, 7, 1].filter(set.contains).map { "周" + (names[$0] ?? "") }.joined(separator: " ")
    }

    var title: String { label.isEmpty ? "闹钟" : label }
}

/// Alarms, saved to UserDefaults and scheduled with AlarmKit (iOS 26)
/// or local notifications on older systems.
@Observable
@MainActor
final class AlarmStore {
    private(set) var items: [MoonAlarm]
    private static let key = "alarms.v1"

    /// AlarmKit rings like the Clock app, even on silent. Older systems use notifications.
    var usesSystemAlarms: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([MoonAlarm].self, from: data) {
            items = saved
        } else {
            items = [
                MoonAlarm(label: "起床", hour: 7, minute: 0, weekdays: [2, 3, 4, 5, 6]),
                MoonAlarm(label: "该睡觉了", hour: 23, minute: 0, weekdays: [1, 2, 3, 4, 5, 6, 7]),
            ]
        }
    }

    var sorted: [MoonAlarm] { items.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) } }
    func contains(_ id: UUID) -> Bool { items.contains { $0.id == id } }

    /// Returns false when the user hasn't allowed alarms.
    @discardableResult
    func setEnabled(_ id: UUID, _ on: Bool) async -> Bool {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return false }
        if on {
            guard await AlarmScheduler.authorize() else { return false }
            items[i].enabled = true
            await AlarmScheduler.schedule(items[i])
        } else {
            items[i].enabled = false
            await AlarmScheduler.cancel(items[i])
        }
        save()
        return true
    }

    @discardableResult
    func upsert(_ alarm: MoonAlarm) async -> Bool {
        var alarm = alarm
        if let old = items.first(where: { $0.id == alarm.id }) { await AlarmScheduler.cancel(old) }
        var allowed = true
        if alarm.enabled {
            allowed = await AlarmScheduler.authorize()
            if allowed { await AlarmScheduler.schedule(alarm) } else { alarm.enabled = false }
        }
        if let i = items.firstIndex(where: { $0.id == alarm.id }) {
            items[i] = alarm
        } else {
            items.append(alarm)
        }
        save()
        return allowed
    }

    func delete(_ id: UUID) async {
        if let old = items.first(where: { $0.id == id }) { await AlarmScheduler.cancel(old) }
        items.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

// MARK: Scheduling

enum AlarmScheduler {
    static func authorize() async -> Bool {
        if #available(iOS 26.0, *) {
            return await SystemAlarms.authorize()
        }
        let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        return granted ?? false
    }

    static func schedule(_ alarm: MoonAlarm) async {
        if #available(iOS 26.0, *) {
            await SystemAlarms.schedule(alarm)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "MoonTime 闹钟 · \(alarm.timeText)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let center = UNUserNotificationCenter.current()
        if alarm.weekdays.isEmpty {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: alarm.hour, minute: alarm.minute), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger))
        } else {
            for weekday in alarm.weekdays {
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: alarm.hour, minute: alarm.minute, weekday: weekday), repeats: true)
                try? await center.add(UNNotificationRequest(
                    identifier: "\(alarm.id.uuidString)-\(weekday)", content: content, trigger: trigger))
            }
        }
    }

    static func cancel(_ alarm: MoonAlarm) async {
        if #available(iOS 26.0, *) {
            SystemAlarms.cancel(alarm.id)
            return
        }
        let ids = [alarm.id.uuidString] + (1...7).map { "\(alarm.id.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct MoonAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
private enum SystemAlarms {
    static func authorize() async -> Bool {
        switch AlarmManager.shared.authorizationState {
        case .authorized: return true
        case .denied: return false
        case .notDetermined:
            return (try? await AlarmManager.shared.requestAuthorization()) == .authorized
        @unknown default: return false
        }
    }

    static func schedule(_ alarm: MoonAlarm) async {
        let stop = AlarmButton(text: "关闭", textColor: .white, systemImageName: "stop.circle")
        let alert = AlarmPresentation.Alert(title: "\(alarm.title)", stopButton: stop)
        let attributes = AlarmAttributes<MoonAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: MoonAlarmMetadata(),
            tintColor: Palette.accent
        )
        let weekdays: [Locale.Weekday] = alarm.weekdays.compactMap {
            [1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday, 5: .thursday, 6: .friday, 7: .saturday][$0]
        }
        let schedule = Alarm.Schedule.relative(.init(
            time: .init(hour: alarm.hour, minute: alarm.minute),
            repeats: weekdays.isEmpty ? .never : .weekly(weekdays)
        ))
        let configuration = AlarmManager.AlarmConfiguration<MoonAlarmMetadata>.alarm(
            schedule: schedule, attributes: attributes
        )
        _ = try? await AlarmManager.shared.schedule(id: alarm.id, configuration: configuration)
    }

    static func cancel(_ id: UUID) {
        try? AlarmManager.shared.cancel(id: id)
    }
}
#else
@available(iOS 26.0, *)
private enum SystemAlarms {
    static func authorize() async -> Bool { false }
    static func schedule(_ alarm: MoonAlarm) async {}
    static func cancel(_ id: UUID) {}
}
#endif
