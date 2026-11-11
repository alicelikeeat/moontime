import SwiftUI

struct TodayView: View {
    @Environment(DayStore.self) private var store
    @Environment(CountdownStore.self) private var countdowns
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
        .padding(.horizontal, Metrics.page - 4)
        .safeAreaInset(edge: .top, spacing: 0) {
            // Pinned header; the timeline fades out underneath it.
            VStack(alignment: .leading, spacing: 14) {
                PageHeader(subtitle: "\(TimeFormat.monthDay(day)) \(TimeFormat.weekday(day))", title: relativeTitle(for: day)) {
                    featuredCountdown
                }
                WeekStrip()
                statsLine(day: day, blocks: blocks)
            }
            .padding(.horizontal, Metrics.page)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background { HeaderFade() }
        }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }

    @ViewBuilder
    private var featuredCountdown: some View {
        if let featured = countdowns.featured {
            let phrase = featured.phrase()
            VStack(alignment: .trailing, spacing: 0) {
                Text(featured.title)
                    .font(.mtMicro)
                    .foregroundStyle(Palette.secondaryLabel)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(phrase.lead).font(.mtMicro)
                    Text(phrase.number)
                        .font(.mtNumber(24))
                        .monospacedDigit()
                        .foregroundStyle(featured.color)
                    Text(phrase.unit).font(.mtMicro)
                }
                .foregroundStyle(Palette.secondaryLabel)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// "6.2 小时已安排 · 2.8 小时空闲 · 1/6 完成"
    private func statsLine(day: Date, blocks: [TimeBlock]) -> some View {
        HStack(spacing: 6) {
            stat(TimeFormat.hours(store.scheduledTime(on: day)), "小时已安排")
            dot
            stat(TimeFormat.hours(store.freeTime(on: day)), "小时空闲")
            dot
            stat("\(blocks.filter(\.isDone).count)/\(blocks.count)", "完成")
        }
        .font(.mtCaption)
        .foregroundStyle(Palette.secondaryLabel)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.label)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
        }
    }

    private var dot: some View {
        Circle().fill(Palette.secondaryLabel.opacity(0.5)).frame(width: 2, height: 2)
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
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let selected = Calendar.current.isDate(day, inSameDayAs: store.selectedDate)
                let isToday = Calendar.current.isDateInToday(day)
                let weekend = index >= 5
                Button {
                    withAnimation(.bouncy(duration: 0.45, extraBounce: 0.08)) {
                        store.selectedDate = Calendar.current.startOfDay(for: day)
                    }
                } label: {
                    VStack(spacing: 1) {
                        Text(symbols[index])
                            .font(.mtMicro)
                            .foregroundStyle(selected ? Palette.accent : Palette.secondaryLabel)
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 13, weight: selected || isToday ? .semibold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(selected || isToday ? Palette.accent : (weekend ? Palette.secondaryLabel : Palette.label))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        if selected {
                            SelectionLens().matchedGeometryEffect(id: "day-lens", in: lens)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel("\(TimeFormat.monthDay(day)) \(TimeFormat.weekday(day))")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .glassSurface(in: Capsule(style: .continuous))
        .sensoryFeedback(.selection, trigger: store.selectedDate)
    }
}
