import Foundation

enum TimeFormat {
    /// "9:00"
    static func clock(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    private static let weekdays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]

    /// "11月11日" — built by hand so it reads the same whatever the device language.
    static func monthDay(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return "\(c.month ?? 1)月\(c.day ?? 1)日"
    }

    /// "星期三"
    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        weekdays[(calendar.component(.weekday, from: date) - 1) % 7]
    }

    /// "1:19:48"
    static func countdown(_ interval: TimeInterval) -> String {
        let s = max(0, Int(interval.rounded()))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    static func minutes(_ interval: TimeInterval) -> Int {
        Int((interval / 60).rounded())
    }

    /// "1.5" — hours with at most one decimal.
    static func hours(_ interval: TimeInterval) -> String {
        (interval / 3600).formatted(.number.precision(.fractionLength(0...1)))
    }

    /// "30 分钟" or "1.5 小时"
    static func duration(_ interval: TimeInterval) -> String {
        let m = minutes(interval)
        return m < 60 ? "\(m) 分钟" : "\(hours(interval)) 小时"
    }

    /// "45m" or "2.5h"
    static func short(_ interval: TimeInterval) -> String {
        let m = minutes(interval)
        return m < 60 ? "\(m)m" : "\(hours(interval))h"
    }

    /// "3h 10m"
    static func hoursMinutes(_ interval: TimeInterval) -> String {
        let m = minutes(interval)
        let h = m / 60, rest = m % 60
        if h == 0 { return "\(rest)m" }
        return rest == 0 ? "\(h)h" : "\(h)h \(rest)m"
    }
}
