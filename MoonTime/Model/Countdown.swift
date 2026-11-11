import Foundation
import Observation
import SwiftUI

/// A day to count down to (or, once passed, count up from).
struct Countdown: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var date: Date
    /// Birthdays and anniversaries: count to the next occurrence.
    var repeatsYearly = false
    var symbol = "calendar"
    var colorHex: UInt32 = 0x4F5BD5
    var pinned = false

    var color: Color { Palette.tone(colorHex) }

    /// The day being counted to, at midnight.
    func target(from today: Date = .now, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        guard repeatsYearly else { return start }
        let todayStart = calendar.startOfDay(for: today)
        var parts = calendar.dateComponents([.month, .day], from: start)
        parts.year = calendar.component(.year, from: todayStart)
        var next = calendar.date(from: parts) ?? start
        if next < todayStart {
            parts.year = (parts.year ?? 0) + 1
            next = calendar.date(from: parts) ?? next
        }
        return next
    }

    /// Positive: days to go. 0: today. Negative: days since.
    func days(from today: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: target(from: today, calendar: calendar)).day ?? 0
    }

    /// ("还有", "84", "天"), ("就是", "今天", ""), ("已经", "365", "天")
    func phrase(from today: Date = .now) -> (lead: String, number: String, unit: String) {
        let d = days(from: today)
        if d > 0 { return ("还有", "\(d)", "天") }
        if d == 0 { return ("就是", "今天", "") }
        return ("已经", "\(-d)", "天")
    }

    static let symbols = [
        "calendar", "gift", "birthday.cake", "heart", "star", "airplane",
        "graduationcap", "briefcase", "flag", "sparkles", "leaf", "moon.stars",
    ]
    static let colors: [UInt32] = Palette.choices
}

/// Countdowns, saved to UserDefaults so they survive relaunches.
@Observable
@MainActor
final class CountdownStore {
    private(set) var items: [Countdown]

    private static let key = "countdowns.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([Countdown].self, from: data) {
            items = saved
        } else {
            items = Self.samples()
        }
    }

    /// Pinned first; otherwise the nearest upcoming one.
    var featured: Countdown? {
        items.first(where: \.pinned) ?? sorted.first
    }

    /// Upcoming soonest first, then past ones most recent first.
    var sorted: [Countdown] {
        // Work out each day count once instead of on every comparison.
        let keyed = items.map { (item: $0, days: $0.days()) }
        let upcoming = keyed.filter { $0.days >= 0 }.sorted { $0.days < $1.days }
        let past = keyed.filter { $0.days < 0 }.sorted { $0.days > $1.days }
        return (upcoming + past).map(\.item)
    }

    func contains(_ id: UUID) -> Bool { items.contains { $0.id == id } }

    func upsert(_ countdown: Countdown) {
        if countdown.pinned { unpinAll() }
        if let i = items.firstIndex(where: { $0.id == countdown.id }) {
            items[i] = countdown
        } else {
            items.append(countdown)
        }
        save()
    }

    func togglePin(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        let pin = !items[i].pinned
        unpinAll()
        items[i].pinned = pin
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    private func unpinAll() {
        for i in items.indices { items[i].pinned = false }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private static func samples(now: Date = .now) -> [Countdown] {
        var list: [Countdown] = []
        // Next Spring Festival, from the Chinese lunar calendar.
        let lunar = Calendar(identifier: .chinese)
        if let festival = lunar.nextDate(after: now, matching: DateComponents(month: 1, day: 1), matchingPolicy: .nextTime) {
            list.append(Countdown(title: "春节", date: festival, symbol: "sparkles", colorHex: 0xD9675A, pinned: true))
        }
        let calendar = Calendar.current
        if let newYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1)) {
            list.append(Countdown(title: "元旦", date: newYear, repeatsYearly: true, symbol: "flag", colorHex: 0x4F5BD5))
        }
        list.append(Countdown(title: "开始用 MoonTime", date: calendar.startOfDay(for: now), symbol: "moon.stars", colorHex: 0x8E6BBF))
        return list
    }
}
