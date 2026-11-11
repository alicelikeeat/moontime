import SwiftUI

struct DayTimeline: View {
    @Environment(DayStore.self) private var store

    let day: Date
    let blocks: [TimeBlock]
    let freeSlots: [DateInterval]
    let inboxCount: Int
    let focus: ActiveFocus?
    var onTap: (TimeBlock) -> Void
    var onSchedule: () -> Void

    private let firstHour = 7
    private let lastHour = 23
    private let hourHeight: CGFloat = 56
    private let blockInset: CGFloat = 56

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    hourGrid

                    ForEach(freeSlots, id: \.start) { slot in
                        freeSlotCard(slot)
                            .frame(height: min(46, height(for: slot.duration) - 10))
                            .padding(.leading, blockInset)
                            .offset(y: y(for: slot.start) + 4)
                    }

                    ForEach(blocks) { block in
                        let h = max(25, height(for: block.duration) - 3)
                        BlockCard(block: block, height: h, focus: focus?.blockID == block.id ? focus : nil)
                            .frame(height: h)
                            .padding(.leading, blockInset)
                            .offset(y: y(for: block.start) + 1)
                            .onTapGesture { onTap(block) }
                            .contextMenu { menu(for: block) }
                    }

                    if Calendar.current.isDateInToday(day) {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            nowLine(at: context.date)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 110) // room for the floating tab bar
            }
            .onAppear { proxy.scrollTo(scrollAnchorHour, anchor: .top) }
            .onChange(of: day) { proxy.scrollTo(scrollAnchorHour, anchor: .top) }
        }
    }

    private var scrollAnchorHour: Int {
        let first = blocks.first.map { Calendar.current.component(.hour, from: $0.start) } ?? 8
        return max(firstHour, min(first, lastHour))
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(firstHour...lastHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(hour):00")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(width: 40, alignment: .trailing)
                        .offset(y: -7)
                    Rectangle().fill(Palette.gridLine).frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
                .id(hour)
            }
        }
    }

    private func nowLine(at now: Date) -> some View {
        let offset = y(for: now)
        return HStack(spacing: 0) {
            Circle().fill(Palette.nowLine).frame(width: 10, height: 10)
            Rectangle().fill(Palette.nowLine).frame(height: 2)
        }
        .padding(.leading, 43)
        .offset(y: offset - 5)
        .opacity(offset >= 0 && offset <= CGFloat(lastHour - firstHour + 1) * hourHeight ? 1 : 0)
        .accessibilityHidden(true)
    }

    private func freeSlotCard(_ slot: DateInterval) -> some View {
        HStack {
            Text(inboxCount > 0
                 ? "空闲 \(TimeFormat.duration(slot.duration)) · 收件箱里有 \(inboxCount) 件事"
                 : "空闲 \(TimeFormat.duration(slot.duration))")
                .font(.system(size: 13))
                .foregroundStyle(Palette.freeSlotText)
            Spacer()
            if inboxCount > 0 {
                Button("安排", action: onSchedule)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Palette.freeSlotBorder, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
    }

    @ViewBuilder
    private func menu(for block: TimeBlock) -> some View {
        if !block.isDone, store.focus == nil, Calendar.current.isDateInToday(block.start) {
            Button("开始专注", systemImage: "timer") { onTap(block) }
        }
        Button(block.isDone ? "标记为未完成" : "标记为完成", systemImage: "checkmark.circle") {
            store.toggleDone(block.id)
        }
        Button("移到明天", systemImage: "arrow.turn.down.right") { store.moveToTomorrow(block.id) }
        Button("删除", systemImage: "trash", role: .destructive) { store.delete(block.id) }
    }

    private func y(for date: Date) -> CGFloat {
        let start = Calendar.current.date(bySettingHour: firstHour, minute: 0, second: 0, of: day) ?? day
        return CGFloat(date.timeIntervalSince(start) / 3600) * hourHeight
    }

    private func height(for duration: TimeInterval) -> CGFloat {
        CGFloat(duration / 3600) * hourHeight
    }
}

struct BlockCard: View {
    let block: TimeBlock
    let height: CGFloat
    /// Set when this block is the one being focused on.
    let focus: ActiveFocus?

    private var category: BlockCategory { block.category }

    var body: some View {
        Group {
            if let focus {
                activeCard(focus)
            } else if height < 44 {
                compactCard
            } else {
                regularCard
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(category.fill, in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            if focus != nil {
                RoundedRectangle(cornerRadius: cornerRadius).stroke(Palette.accent, lineWidth: 2)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var cornerRadius: CGFloat { height < 44 ? 8 : (height < 70 ? 10 : 12) }

    private var timeRange: String { "\(TimeFormat.clock(block.start)) – \(TimeFormat.clock(block.end))" }

    private var compactCard: some View {
        HStack(spacing: 6) {
            if block.isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(category.title)
            }
            Text(block.displayTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(category.title)
                .strikethrough(block.isDone)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(block.isDone
                 ? TimeFormat.clock(block.start)
                 : "\(TimeFormat.clock(block.start)) · \(TimeFormat.duration(block.duration))")
                .font(.system(size: 12))
                .foregroundStyle(category.detail)
        }
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity)
    }

    private var regularCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            if height >= 70 {
                Text(timeRange).font(.system(size: 12)).foregroundStyle(category.detail)
            }
            Text(block.displayTitle)
                .font(.system(size: height >= 70 ? 15 : 14, weight: height >= 70 ? .bold : .semibold))
                .foregroundStyle(category.title)
                .strikethrough(block.isDone)
                .lineLimit(1)
            if height >= 70 {
                if let note = block.note {
                    Text(note).font(.system(size: 12)).foregroundStyle(category.detail).lineLimit(1)
                }
            } else {
                Text(timeRange).font(.system(size: 12)).foregroundStyle(category.detail)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func activeCard(_ focus: ActiveFocus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(focus.state.isPaused ? "已暂停" : "进行中")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.accent, in: Capsule())
                Text(timeRange).font(.system(size: 12)).foregroundStyle(category.detail)
            }
            Text(block.displayTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(category.title)
                .lineLimit(2)
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text("已专注 \(TimeFormat.minutes(focus.state.elapsed(at: context.date))) 分钟")
                    .font(.system(size: 13))
                    .foregroundStyle(category.detail)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
