import Foundation
import Observation
import SwiftUI

/// A daily habit and the days it was done.
struct Habit: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var symbol = "checkmark.circle"
    var colorHex: UInt32 = 0x3F8F6B
    /// Day keys ("2026-11-11") the habit was done.
    var checkins: Set<String> = []

    var color: Color { Palette.tone(colorHex) }
    var total: Int { checkins.count }

    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func isDone(on date: Date) -> Bool { checkins.contains(Self.key(date)) }

    /// Consecutive days up to today (or yesterday, if today isn't done yet).
    func streak(asOf today: Date = .now, calendar: Calendar = .current) -> Int {
        var day = today
        if !isDone(on: day) { day = calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while isDone(on: day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    /// The last seven days, oldest first.
    func lastWeek(asOf today: Date = .now, calendar: Calendar = .current) -> [(date: Date, done: Bool)] {
        (0..<7).reversed().compactMap { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (d, isDone(on: d))
        }
    }

    static let symbols = [
        "sunrise", "book", "figure.run", "drop", "leaf", "brain.head.profile",
        "pencil.and.scribble", "bed.double", "fork.knife", "dumbbell", "music.note", "checkmark.circle",
    ]
}

/// Habits, saved to UserDefaults.
@Observable
@MainActor
final class HabitStore {
    private(set) var items: [Habit]
    private static let key = "habits.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([Habit].self, from: data) {
            items = saved
        } else {
            items = Self.samples()
        }
    }

    func doneToday(_ today: Date = .now) -> Int { items.filter { $0.isDone(on: today) }.count }
    var bestStreak: Int { items.map { $0.streak() }.max() ?? 0 }

    func toggle(_ id: UUID, on date: Date = .now) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let key = Habit.key(date)
        if items[i].checkins.contains(key) {
            items[i].checkins.remove(key)
        } else {
            items[i].checkins.insert(key)
        }
        save()
    }

    func contains(_ id: UUID) -> Bool { items.contains { $0.id == id } }

    func upsert(_ habit: Habit) {
        if let i = items.firstIndex(where: { $0.id == habit.id }) {
            items[i] = habit
        } else {
            items.append(habit)
        }
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private static func samples(now: Date = .now) -> [Habit] {
        let calendar = Calendar.current
        func days(_ offsets: [Int]) -> Set<String> {
            Set(offsets.compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }.map { Habit.key($0) })
        }
        return [
            Habit(title: "早起", symbol: "sunrise", colorHex: 0xC48A3A, checkins: days([1, 2, 3, 4, 6])),
            Habit(title: "阅读 30 分钟", symbol: "book", colorHex: 0x8E6BBF, checkins: days([0, 1, 2, 3, 4, 5])),
            Habit(title: "运动", symbol: "figure.run", colorHex: 0x00796B, checkins: days([1, 3, 5])),
            Habit(title: "喝够 8 杯水", symbol: "drop", colorHex: 0x4F5BD5, checkins: days([2, 3])),
        ]
    }
}
