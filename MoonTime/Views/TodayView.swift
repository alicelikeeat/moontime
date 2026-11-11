import SwiftUI

struct TodayView: View {
    @Environment(DayStore.self) private var store
    var onStartFocus: (TimeBlock) -> Void
    var onOpenFocus: () -> Void
    var onOpenInbox: () -> Void

    var body: some View {
        let day = store.selectedDate
        let blocks = store.selectedBlocks

        DayTimeline(
            day: day,
            blocks: blocks,
            freeSlots: store.freeSlots(on: day),
            inboxCount: store.inbox.count,
            focus: store.focus,
            onTap: tap,
            onSchedule: onOpenInbox
        )
        .padding(.horizontal, 16)
        .safeAreaInset(edge: .top, spacing: 8) {
            // Timeline scrolls underneath this glass panel.
            GlassGroup(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    header(for: day)
                    WeekStrip()
                    HStack(spacing: 8) {
                        Chip(text: "已安排 \(TimeFormat.hours(store.scheduledTime(on: day))) 小时")
                        Chip(text: "空闲 \(TimeFormat.hours(store.freeTime(on: day))) 小时")
                        Chip(text: "完成 \(blocks.filter(\.isDone).count)/\(blocks.count)")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassSurface(in: RoundedRectangle(cornerRadius: 28))
            }
            .padding(.horizontal, 12)
        }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }

    private func header(for day: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(day, format: .dateTime.month(.defaultDigits).day().weekday(.wide).locale(Locale(identifier: "zh_CN")))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.secondaryLabel)
            Text(relativeTitle(for: day))
                .font(.system(size: 34, weight: .bold))
        }
    }

    private func relativeTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "今天" }
        if calendar.isDateInTomorrow(day) { return "明天" }
        if calendar.isDateInYesterday(day) { return "昨天" }
        return day.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "zh_CN")))
    }

    private func tap(_ block: TimeBlock) {
        if store.focus?.blockID == block.id {
            onOpenFocus()
        } else if !block.isDone, store.focus == nil, Calendar.current.isDateInToday(block.start) {
            onStartFocus(block)
        }
    }
}

private struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.tertiaryLabel)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassSurface(in: Capsule(), tint: .white.opacity(0.35))
    }
}

private struct WeekStrip: View {
    @Environment(DayStore.self) private var store

    private var days: [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        let start = calendar.dateInterval(of: .weekOfYear, for: store.selectedDate)?.start ?? store.selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private let symbols = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let selected = Calendar.current.isDate(day, inSameDayAs: store.selectedDate)
                let weekend = index >= 5
                Button {
                    store.selectedDate = Calendar.current.startOfDay(for: day)
                } label: {
                    VStack(spacing: 2) {
                        Text(symbols[index])
                            .font(.system(size: 12))
                            .foregroundStyle(selected ? .white : Palette.secondaryLabel)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 17, weight: selected ? .bold : .semibold))
                            .foregroundStyle(selected ? .white : (weekend ? Palette.secondaryLabel : Palette.label))
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(selected ? Palette.accent : .clear, in: RoundedRectangle(cornerRadius: 14))
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
