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
        .safeAreaInset(edge: .top, spacing: 0) { TopScrollEdgeBlur() }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }

    private func header(for day: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(TimeFormat.monthDay(day)) \(TimeFormat.weekday(day))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.secondaryLabel)
            Text(relativeTitle(for: day))
                .font(.system(size: 26, weight: .bold))
                .tracking(-0.4)
                .contentTransition(.interpolate)
        }
    }

    private func relativeTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "今天" }
        if calendar.isDateInTomorrow(day) { return "明天" }
        if calendar.isDateInYesterday(day) { return "昨天" }
        return TimeFormat.weekday(day)
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
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(Palette.tertiaryLabel)
            .contentTransition(.numericText())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassSurface(in: Capsule(), tint: .white.opacity(0.35))
    }
}

private struct WeekStrip: View {
    @Environment(DayStore.self) private var store
    @Namespace private var lens

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
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) {
                        store.selectedDate = Calendar.current.startOfDay(for: day)
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(symbols[index])
                            .font(.system(size: 10))
                            .foregroundStyle(selected ? .white : Palette.secondaryLabel)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 13, weight: selected ? .bold : .semibold))
                            .foregroundStyle(selected ? .white : (weekend ? Palette.secondaryLabel : Palette.label))
                    }
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background {
                        if selected {
                            // Tinted glass lens that slides to the picked day.
                            Color.clear
                                .glassSurface(in: RoundedRectangle(cornerRadius: 16), tint: Palette.accent, interactive: true)
                                .matchedGeometryEffect(id: "day-lens", in: lens)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.pressScale)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
