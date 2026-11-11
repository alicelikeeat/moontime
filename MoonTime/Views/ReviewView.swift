import SwiftUI

struct ReviewView: View {
    @Environment(DayStore.self) private var store
    var onPlanTomorrow: () -> Void

    var body: some View {
        @Bindable var store = store
        let blocks = store.todayBlocks
        let done = blocks.filter(\.isDone)
        let unfinished = blocks.filter { !$0.isDone }
        let focusTime = done.filter { $0.category == .deepWork }.reduce(0) { $0 + ($1.actualDuration ?? 0) }
        let onPlanRate = blocks.isEmpty ? 0 : Double(done.count) / Double(blocks.count)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(TimeFormat.monthDay(.now)) · \(TimeFormat.clock(.now))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.secondaryLabel)
                    Text("今日复盘").font(.system(size: 34, weight: .bold))
                }
                .padding(.horizontal, 4)

                HStack(spacing: 10) {
                    statCard("\(done.count)/\(blocks.count)", "完成事项")
                    statCard(TimeFormat.hoursMinutes(focusTime), "专注时长")
                    statCard(onPlanRate.formatted(.percent.precision(.fractionLength(0))), "按计划执行")
                }

                PlanVsActualCard(blocks: blocks)

                ForEach(unfinished) { block in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("未完成").font(.system(size: 12)).foregroundStyle(Palette.secondaryLabel)
                            Text(block.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                        }
                        Spacer()
                        Button("移到明天") { store.moveToTomorrow(block.id) }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.softAccentText)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 36)
                            .glassSurface(in: Capsule(), tint: Palette.accent.opacity(0.14), interactive: true)
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassSurface(in: RoundedRectangle(cornerRadius: 20))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("今天最有成就感的一件事？").font(.system(size: 15, weight: .semibold))
                    TextField("写一句就好", text: $store.reflection)
                        .font(.system(size: 15))
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassSurface(in: RoundedRectangle(cornerRadius: 20))

                Button {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                    store.selectedDate = Calendar.current.startOfDay(for: tomorrow)
                    onPlanTomorrow()
                } label: {
                    Label("规划明天", systemImage: "moon.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .glassSurface(in: Capsule(), tint: Palette.accent, interactive: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .bold)).minimumScaleFactor(0.7).lineLimit(1)
            Text(label).font(.system(size: 12)).foregroundStyle(Palette.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassSurface(in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PlanVsActualCard: View {
    let blocks: [TimeBlock]

    private struct Row: Identifiable {
        let category: BlockCategory
        let planned: TimeInterval
        let actual: TimeInterval
        var id: BlockCategory { category }
    }

    private var rows: [Row] {
        BlockCategory.reviewed.compactMap { category in
            let items = blocks.filter { $0.category == category }
            guard !items.isEmpty else { return nil }
            return Row(
                category: category,
                planned: items.reduce(0) { $0 + $1.duration },
                actual: items.reduce(0) { $0 + ($1.actualDuration ?? 0) }
            )
        }
    }

    private var insight: String {
        let completed = blocks.filter(\.isDone)
        guard !completed.isEmpty else { return "完成时间块后，这里会对比计划和实际用时。" }
        let rows = self.rows
        guard let worst = rows.max(by: { ($0.actual - $0.planned) < ($1.actual - $1.planned) }),
              worst.actual - worst.planned >= 5 * 60 else {
            return "今天基本按计划进行。"
        }
        let over = TimeFormat.minutes(worst.actual - worst.planned)
        let deep = rows.first { $0.category == .deepWork }
        if worst.category != .deepWork, let deep, deep.actual < deep.planned {
            return "\(worst.category.name)超时 \(over) 分钟，挤掉了部分深度工作时间。"
        }
        return "\(worst.category.name)超时 \(over) 分钟。"
    }

    var body: some View {
        let rows = self.rows
        let scale = max(rows.map { max($0.planned, $0.actual) }.max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("计划 vs 实际").font(.system(size: 17, weight: .bold))
                Spacer()
                legend(Palette.plannedBar, "计划")
                legend(Palette.accent, "实际")
            }
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(row.category.name).font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("\(TimeFormat.short(row.planned)) → \(TimeFormat.short(row.actual))")
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                    bar(Palette.plannedBar, row.planned / scale)
                    bar(Palette.accent, row.actual / scale)
                }
                .accessibilityElement(children: .combine)
            }
            Text(insight)
                .font(.system(size: 13))
                .foregroundStyle(Palette.tertiaryLabel)
                .lineSpacing(3)
        }
        .padding(16)
        .glassSurface(in: RoundedRectangle(cornerRadius: 20))
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 10, height: 10)
            Text(text).font(.system(size: 12)).foregroundStyle(Palette.secondaryLabel)
        }
    }

    private func bar(_ color: Color, _ fraction: Double) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: max(fraction > 0 ? 8 : 0, geo.size.width * min(1, fraction)))
        }
        .frame(height: 8)
    }
}
