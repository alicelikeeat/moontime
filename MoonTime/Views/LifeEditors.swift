import SwiftUI

struct HabitEditor: View {
    @Environment(HabitStore.self) private var habits
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Habit
    private let isNew: Bool
    var onSaved: (Habit, Bool) -> Void

    init(habit: Habit, isNew: Bool, onSaved: @escaping (Habit, Bool) -> Void) {
        _draft = State(initialValue: habit)
        self.isNew = isNew
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        SymbolBadge(symbol: draft.symbol, color: draft.color, size: 36)
                            .animation(.bouncy, value: draft.symbol)
                        TextField("习惯名称，比如：早睡、背单词", text: $draft.title)
                            .font(.system(size: 14))
                    }
                } footer: {
                    if !isNew {
                        Text("连续 \(draft.streak()) 天 · 共打卡 \(draft.total) 次")
                    }
                }
                Section("图标") {
                    SymbolGrid(symbols: Habit.symbols, selection: $draft.symbol, color: draft.color)
                }
                Section("颜色") {
                    ColorRow(selection: $draft.colorHex)
                }
                if !isNew {
                    Section {
                        Button("删除这个习惯", role: .destructive) {
                            habits.delete(draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "新建习惯" : "编辑习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "添加" : "保存") {
                        draft.title = draft.title.trimmingCharacters(in: .whitespaces)
                        habits.upsert(draft)
                        onSaved(draft, isNew)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct AlarmEditor: View {
    @Environment(AlarmStore.self) private var alarms
    @Environment(\.dismiss) private var dismiss

    @State private var draft: MoonAlarm
    @State private var time: Date
    @State private var saving = false
    private let isNew: Bool
    var onSaved: (MoonAlarm, Bool) -> Void

    init(alarm: MoonAlarm, isNew: Bool, onSaved: @escaping (MoonAlarm, Bool) -> Void) {
        _draft = State(initialValue: alarm)
        _time = State(initialValue: Calendar.current.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: .now) ?? .now)
        self.isNew = isNew
        self.onSaved = onSaved
    }

    private let order = [2, 3, 4, 5, 6, 7, 1]
    private let names = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("时间", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                Section {
                    TextField("标签，比如：起床、吃药", text: $draft.label)
                        .font(.system(size: 14))
                    Toggle("开启", isOn: $draft.enabled)
                }
                Section {
                    HStack(spacing: 6) {
                        ForEach(order, id: \.self) { weekday in
                            let on = draft.weekdays.contains(weekday)
                            Button {
                                withAnimation(.bouncy(duration: 0.35)) {
                                    if on { draft.weekdays.removeAll { $0 == weekday } } else { draft.weekdays.append(weekday) }
                                }
                            } label: {
                                Text(names[weekday] ?? "")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(on ? .white : Palette.label)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(on ? Palette.accent : Palette.accent.opacity(0.08), in: Circle())
                            }
                            .buttonStyle(.pressScale)
                            .accessibilityLabel("周\(names[weekday] ?? "")")
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                } header: {
                    Text("重复")
                } footer: {
                    Text(draft.repeatText).contentTransition(.interpolate)
                }
                if !isNew {
                    Section {
                        Button("删除这个闹钟", role: .destructive) {
                            Task {
                                await alarms.delete(draft.id)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "新建闹钟" : "编辑闹钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "添加" : "保存") {
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                        draft.hour = parts.hour ?? draft.hour
                        draft.minute = parts.minute ?? draft.minute
                        draft.label = draft.label.trimmingCharacters(in: .whitespaces)
                        saving = true
                        let alarm = draft
                        Task {
                            let allowed = await alarms.upsert(alarm)
                            onSaved(alarm, allowed)
                            dismiss()
                        }
                    }
                    .disabled(saving)
                    .accessibilityIdentifier("alarm.save")
                }
            }
        }
    }
}

// MARK: Shared pickers

struct SymbolGrid: View {
    let symbols: [String]
    @Binding var selection: String
    let color: Color

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
            ForEach(symbols, id: \.self) { symbol in
                let selected = selection == symbol
                Button {
                    withAnimation(.bouncy) { selection = symbol }
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selected ? .white : color)
                        .frame(width: 44, height: 44)
                        .background(selected ? color : color.opacity(0.1), in: Circle())
                        .symbolEffect(.bounce, value: selected)
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel(symbol)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

struct ColorRow: View {
    @Binding var selection: UInt32
    var colors: [UInt32] = Countdown.colors

    var body: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                let selected = selection == hex
                Button {
                    withAnimation(.bouncy) { selection = hex }
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.white, lineWidth: selected ? 3 : 0).padding(2))
                        .scaleEffect(selected ? 1.12 : 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel("颜色")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
