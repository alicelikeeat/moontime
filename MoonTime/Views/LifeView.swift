import SwiftUI

/// The Daily tab: habits, countdown days and alarms behind a glass switcher.
struct LifeView: View {
    enum Section: String, CaseIterable, Identifiable {
        case habits, countdowns, alarms
        var id: String { rawValue }
        var title: String {
            switch self {
            case .habits: "习惯"
            case .countdowns: "倒数日"
            case .alarms: "闹钟"
            }
        }
        var symbol: String {
            switch self {
            case .habits: "checkmark.circle"
            case .countdowns: "hourglass"
            case .alarms: "alarm"
            }
        }
    }

    @Environment(HabitStore.self) private var habits
    @Environment(CountdownStore.self) private var countdowns
    @Environment(AlarmStore.self) private var alarms
    @Environment(ChromeState.self) private var chrome

    @AppStorage("life.section") private var section: Section = .habits
    @State private var editingHabit: Habit?
    @State private var editingCountdown: Countdown?
    @State private var editingAlarm: MoonAlarm?
    @Namespace private var lens

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metrics.gap) {
                header
                switcher
                Group {
                    switch section {
                    case .habits:
                        HabitList(onEdit: { editingHabit = $0 })
                    case .countdowns:
                        CountdownList(onEdit: { editingCountdown = $0 })
                    case .alarms:
                        AlarmList(onEdit: { editingAlarm = $0 })
                    }
                }
                .transition(.opacity)
            }
            .padding(.horizontal, Metrics.page)
            .padding(.top, 8)
            .padding(.bottom, Metrics.tabBarClearance)
        }
        .collapsesTabBarOnScroll()
        .safeAreaInset(edge: .top, spacing: 0) { TopScrollEdgeBlur() }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
        .sheet(item: $editingHabit) { habit in
            HabitEditor(habit: habit, isNew: !habits.contains(habit.id)) { saved, isNew in
                chrome.show(isNew ? "已添加习惯「\(saved.title)」" : "已保存", symbol: "checkmark.circle")
            }
        }
        .sheet(item: $editingCountdown) { item in
            CountdownEditor(countdown: item, isNew: !countdowns.contains(item.id)) { saved, _ in
                let phrase = saved.phrase()
                chrome.show("\(saved.title) · \(phrase.lead) \(phrase.number) \(phrase.unit)", symbol: "hourglass")
            }
        }
        .sheet(item: $editingAlarm) { alarm in
            AlarmEditor(alarm: alarm, isNew: !alarms.contains(alarm.id)) { saved, allowed in
                chrome.show(
                    allowed ? "\(saved.timeText) · \(saved.repeatText)" : "请在设置里允许 MoonTime 使用闹钟",
                    symbol: allowed ? "alarm" : "exclamationmark.triangle"
                )
            }
        }
    }

    private var header: some View {
        PageHeader(subtitle: subtitle, title: "日常") {
            HeaderAddButton(label: "新建\(section.title)", id: "life.add", action: add)
        }
        .padding(.bottom, 4)
    }

    private var subtitle: String {
        switch section {
        case .habits: "今天完成 \(habits.doneToday())/\(habits.items.count)"
        case .countdowns: "\(countdowns.items.count) 个日子"
        case .alarms: "\(alarms.items.filter(\.enabled).count) 个闹钟已开启"
        }
    }

    /// Glass segmented control with a lens that slides between sections.
    private var switcher: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { item in
                let selected = item == section
                Button {
                    withAnimation(.bouncy(duration: 0.45, extraBounce: 0.08)) { section = item }
                } label: {
                    Label(item.title, systemImage: item.symbol)
                        .font(.mtHeadline)
                        .foregroundStyle(selected ? Palette.accent : Palette.tertiaryLabel)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if selected {
                                SelectionLens().matchedGeometryEffect(id: "segment", in: lens)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.pressScale)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("life.\(item.rawValue)")
            }
        }
        .padding(4)
        .glassSurface(in: Capsule())
        .sensoryFeedback(.selection, trigger: section)
    }

    private func add() {
        switch section {
        case .habits:
            editingHabit = Habit(title: "")
        case .countdowns:
            let inAMonth = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
            editingCountdown = Countdown(title: "", date: inAMonth)
        case .alarms:
            editingAlarm = MoonAlarm(hour: 7, minute: 30, weekdays: [2, 3, 4, 5, 6], enabled: true)
        }
    }
}

// MARK: Habits

struct HabitList: View {
    @Environment(HabitStore.self) private var habits
    @Environment(ChromeState.self) private var chrome
    var onEdit: (Habit) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if !habits.items.isEmpty { summary }
            ForEach(habits.items) { habit in
                HabitCard(habit: habit) {
                    withAnimation(.bouncy(duration: 0.45)) { habits.toggle(habit.id) }
                }
                .onTapGesture { onEdit(habit) }
                .contextMenu {
                    Button("编辑", systemImage: "pencil") { onEdit(habit) }
                    Button("删除", systemImage: "trash", role: .destructive) {
                        withAnimation(.bouncy) { habits.delete(habit.id) }
                        chrome.show("已删除「\(habit.title)」", symbol: "trash")
                    }
                }
                .glassPop()
            }
            if habits.items.isEmpty {
                EmptyHint(symbol: "checkmark.circle", text: "还没有习惯，点右上角 + 添加")
            }
        }
    }

    private var summary: some View {
        let done = habits.doneToday()
        let total = max(habits.items.count, 1)
        return HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Palette.accent.opacity(0.12), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: Double(done) / Double(total))
                    .stroke(Palette.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.bouncy(duration: 0.6), value: done)
                Text("\(done)/\(habits.items.count)")
                    .font(.mtHeadline)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(done == habits.items.count ? "今天全部完成" : "今天还差 \(habits.items.count - done) 个")
                    .font(.mtTitle)
                    .contentTransition(.numericText())
                Text("最长连续 \(habits.bestStreak) 天")
                    .font(.mtCaption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding(16)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct HabitCard: View {
    let habit: Habit
    var onToggle: () -> Void

    var body: some View {
        let done = habit.isDone(on: .now)
        HStack(spacing: 12) {
            SymbolBadge(symbol: habit.symbol, color: habit.color, size: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text(habit.title)
                    .font(.mtHeadline)
                    .lineLimit(1)
                Text("连续 \(habit.streak()) 天 · 共 \(habit.total) 次")
                    .font(.mtCaption)
                    .foregroundStyle(Palette.secondaryLabel)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                HStack(spacing: 4) {
                    ForEach(habit.lastWeek(), id: \.date) { day in
                        Circle()
                            .fill(day.done ? habit.color : habit.color.opacity(0.12))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityHidden(true)
            }
            Spacer(minLength: 8)
            Button(action: onToggle) {
                Image(systemName: done ? "checkmark" : "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(done ? .white : habit.color)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 48, height: 48)
                    .glassSurface(in: Circle(), tint: done ? habit.color : habit.color.opacity(0.08), interactive: true)
                    .symbolEffect(.bounce, value: done)
            }
            .buttonStyle(.pressScale)
            .sensoryFeedback(.success, trigger: done) { _, now in now }
            .accessibilityLabel(done ? "取消今天的打卡" : "打卡")
            .accessibilityIdentifier("habit.check.\(habit.title)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
    }
}

// MARK: Alarms

struct AlarmList: View {
    @Environment(AlarmStore.self) private var alarms
    @Environment(ChromeState.self) private var chrome
    var onEdit: (MoonAlarm) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(alarms.sorted) { alarm in
                AlarmRow(alarm: alarm) { on in
                    Task {
                        let ok = await alarms.setEnabled(alarm.id, on)
                        if !ok { chrome.show("请在设置里允许 MoonTime 使用闹钟", symbol: "exclamationmark.triangle") }
                    }
                }
                .onTapGesture { onEdit(alarm) }
                .contextMenu {
                    Button("编辑", systemImage: "pencil") { onEdit(alarm) }
                    Button("删除", systemImage: "trash", role: .destructive) {
                        Task { await alarms.delete(alarm.id) }
                        chrome.show("已删除闹钟", symbol: "trash")
                    }
                }
                .glassPop()
            }
            if alarms.items.isEmpty {
                EmptyHint(symbol: "alarm", text: "还没有闹钟，点右上角 + 添加")
            }
            Text(alarms.usesSystemAlarms
                 ? "闹钟由系统负责响铃，静音模式下也会响，并显示在锁屏上。"
                 : "当前系统以通知提醒，静音模式下不会响铃。升级到 iOS 26 可使用系统闹钟。")
                .font(.mtCaption)
                .foregroundStyle(Palette.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }
}

private struct AlarmRow: View {
    let alarm: MoonAlarm
    var onToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.timeText)
                    .font(.system(size: 40, weight: .thin))
                    .monospacedDigit()
                    .tracking(-1)
                Text("\(alarm.title) · \(alarm.repeatText)")
                    .font(.mtCaption)
                    .foregroundStyle(Palette.secondaryLabel)
            }
            .opacity(alarm.enabled ? 1 : 0.45)
            .animation(.smooth, value: alarm.enabled)
            Spacer()
            Toggle(alarm.title, isOn: Binding(get: { alarm.enabled }, set: onToggle))
                .labelsHidden()
                .tint(Palette.accent)
                .accessibilityIdentifier("alarm.toggle.\(alarm.title)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Metrics.card, style: .continuous))
    }
}
