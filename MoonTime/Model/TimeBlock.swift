import Foundation

struct TimeBlock: Identifiable, Hashable {
    let id: UUID
    var title: String
    var note: String?
    var start: Date
    var end: Date
    var category: BlockCategory
    var isDone: Bool
    /// Time actually spent, set when the block is completed.
    var actualDuration: TimeInterval?

    init(
        id: UUID = UUID(), title: String, note: String? = nil, start: Date, end: Date,
        category: BlockCategory, isDone: Bool = false, actualDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.start = start
        self.end = end
        self.category = category
        self.isDone = isDone
        self.actualDuration = actualDuration
    }

    var duration: TimeInterval { end.timeIntervalSince(start) }

    var displayTitle: String {
        category == .deepWork ? "\(category.name)：\(title)" : title
    }
}

struct InboxItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var estimate: TimeInterval
}

struct ActiveFocus: Equatable {
    var blockID: UUID
    var title: String
    var category: BlockCategory
    var plannedDuration: TimeInterval
    var state: FocusActivityAttributes.ContentState
    var pauseCount = 0
}

enum SampleData {
    static func blocks(on day: Date, calendar: Calendar = .current) -> [TimeBlock] {
        func at(_ h: Int, _ m: Int = 0) -> Date {
            calendar.date(bySettingHour: h, minute: m, second: 0, of: day) ?? day
        }
        return [
            TimeBlock(title: "晨间规划", start: at(8, 30), end: at(9), category: .planning,
                      isDone: true, actualDuration: 30 * 60),
            TimeBlock(title: "写产品需求文档", start: at(9), end: at(11), category: .deepWork),
            TimeBlock(title: "团队站会", start: at(11), end: at(11, 30), category: .meeting),
            TimeBlock(title: "午餐 + 散步", start: at(12), end: at(13), category: .life),
            TimeBlock(title: "设计评审", note: "会议室 B", start: at(14), end: at(15, 30), category: .meeting),
            TimeBlock(title: "健身", start: at(16), end: at(16, 45), category: .exercise),
        ]
    }

    static let inbox: [InboxItem] = [
        InboxItem(title: "回复投资人邮件", estimate: 30 * 60),
        InboxItem(title: "整理本周报销", estimate: 20 * 60),
        InboxItem(title: "读完竞品分析", estimate: 45 * 60),
    ]
}
