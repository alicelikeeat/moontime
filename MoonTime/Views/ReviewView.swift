import SwiftUI

struct ReviewView: View {
    @Environment(DayStore.self) private var store
    @Environment(ChromeState.self) private var chrome
    var onPlanTomorrow: () -> Void

    var body: some View {
        @Bindable var store = store
        let blocks = store.todayBlocks
        let done = blocks.filter(\.isDone)
        let unfinished = blocks.filter { !$0.isDone }
        let focusTime = done.filter { $0.category == .deepWork }.reduce(0) { $0 + ($1.actualDuration ?? 0) }
        let onPlanRate = blocks.isEmpty ? 0 : Double(done.count) / Double(blocks.count)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metrics.gap) {
                PageHeader(subtitle: "\(TimeFormat.monthDay(.now)) · \(TimeFormat.clock(.now))", title: "今日复盘")
                    .padding(.bottom, 8)

                GlassGroup(spacing: 10) {
                    HStack(spacing: 10) {
                        statCard("\(done.count)/\(blocks.count)", "完成事项")
                        statCard(TimeFormat.hoursMinutes(focusTime), "专注时长")
                        statCard(onPlanRate.formatted(.percent.precision(.fractionLength(0))), "按计划执行")
                    }
                }

                PlanVsActualCard(blocks: blocks)

                if !unfinished.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("未完成 · \(unfinished.count)")
                            .font(.mtCaption.weight(.semibold))
                            .foregroundStyle(Palette.secondaryLabel)
                            .padding(.bottom, 6)
                        ForEach(Array(unfinished.enumerated()), id: \.element.id) { index, block in
                            if index > 0 { Divider().overlay(Palette.gridLine) }
                            HStack(spacing: 12) {
                                Text(block.title).font(.mtBody).lineLimit(1)
                                Spacer(minLength: 8)
                                Button("移到明天") {
                                    withAnimation(.snappy) { store.moveToTomorrow(block.id) }
                                    chrome.show("已移到明天", symbol: "arrow.turn.down.right")
                                }
                                .font(.mtCaption.weight(.semibold))
                                .foregroundStyle(Palette.accent)
                                .frame(minHeight: 44)
                                .buttonStyle(.pressScale)
                            }
                        }
                    }
                    .card(padding: 14)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("今天最有成就感的一件事？").font(.mtHeadline)
                    TextField("写一句就好", text: $store.reflection, axis: .vertical)
                        .font(.mtBody)
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Palette.accent.opacity(0.04), in: RoundedRectangle(cornerRadius: Metrics.small, style: .continuous))
                }
                .card()

                Button {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                    store.selectedDate = Calendar.current.startOfDay(for: tomorrow)
                    onPlanTomorrow()
                } label: {
                    Label("规划明天", systemImage: "moon.fill")
                        .font(.mtTitle)
                        .foregroundStyle(Palette.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(Capsule())
                }
                .systemGlassButton(prominent: Palette.accentFill != nil, tint: Palette.accentFill, shape: Capsule())
                .padding(.top, 8)
            }
            .padding(.horizontal, Metrics.page)
            .padding(.top, 8)
            .padding(.bottom, Metrics.tabBarClearance)
        }
        .collapsesTabBarOnScroll()
        .safeAreaInset(edge: .top, spacing: 0) { TopScrollEdgeBlur() }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.mtNumber(24))
                .monospacedDigit()
                .tracking(-0.5)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(label).font(.mtCaption).foregroundStyle(Palette.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
    }
}

private struct PlanVsActualCard: View {
    let blocks: [TimeBlock]
    @State private var grown = false

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
                Text("计划 vs 实际").font(.mtTitle)
                Spacer()
                legend(Palette.plannedBar, "计划")
                legend(Palette.accent, "实际")
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(row.category.name).font(.mtHeadline)
                        Spacer()
                        Text("\(TimeFormat.short(row.planned)) → \(TimeFormat.short(row.actual))")
                            .font(.mtBody)
                            .foregroundStyle(Palette.secondaryLabel)
                    }
                    // Bars grow in one row after another.
                    Group {
                        bar(Palette.plannedBar, grown ? row.planned / scale : 0)
                        bar(Palette.accent, grown ? row.actual / scale : 0)
                    }
                    .animation(.bouncy(duration: 0.7, extraBounce: 0.08).delay(0.15 + Double(index) * 0.07), value: grown)
                }
                .accessibilityElement(children: .combine)
            }
            Text(insight)
                .font(.mtBody)
                .foregroundStyle(Palette.tertiaryLabel)
                .lineSpacing(3)
        }
        .card()
        .onAppear { grown = true }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(color).frame(width: 8, height: 8)
            Text(text).font(.mtCaption).foregroundStyle(Palette.secondaryLabel)
        }
    }

    private func bar(_ color: Color, _ fraction: Double) -> some View {
        GeometryReader { geo in
            Capsule()
                .fill(color)
                .frame(width: max(fraction > 0 ? 6 : 0, geo.size.width * min(1, fraction)))
        }
        .frame(height: 6)
    }
}
