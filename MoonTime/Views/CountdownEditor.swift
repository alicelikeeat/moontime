import SwiftUI

struct CountdownEditor: View {
    @Environment(CountdownStore.self) private var countdowns
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Countdown
    private let isNew: Bool
    var onSaved: (Countdown, Bool) -> Void

    init(countdown: Countdown, isNew: Bool, onSaved: @escaping (Countdown, Bool) -> Void) {
        _draft = State(initialValue: countdown)
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
                        TextField("名称，比如：生日、旅行、考试", text: $draft.title)
                            .font(.system(size: 14))
                    }
                    DatePicker("日期", selection: $draft.date, displayedComponents: .date)
                    Toggle("每年重复", isOn: $draft.repeatsYearly)
                    Toggle("置顶", isOn: $draft.pinned)
                } footer: {
                    let phrase = draft.phrase()
                    Text("\(phrase.lead) \(phrase.number) \(phrase.unit)")
                        .contentTransition(.numericText())
                        .animation(.snappy, value: phrase.number)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                        ForEach(Countdown.symbols, id: \.self) { symbol in
                            let selected = draft.symbol == symbol
                            Button {
                                withAnimation(.bouncy) { draft.symbol = symbol }
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(selected ? .white : draft.color)
                                    .frame(width: 44, height: 44)
                                    .background(selected ? draft.color : draft.color.opacity(0.1), in: Circle())
                                    .symbolEffect(.bounce, value: selected)
                            }
                            .buttonStyle(.pressScale)
                            .accessibilityLabel(symbol)
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("颜色") {
                    HStack(spacing: 10) {
                        ForEach(Countdown.colors, id: \.self) { hex in
                            let selected = draft.colorHex == hex
                            Button {
                                withAnimation(.bouncy) { draft.colorHex = hex }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(.white, lineWidth: selected ? 3 : 0).padding(2))
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.pressScale)
                            .accessibilityLabel("颜色")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                }

                if !isNew {
                    Section {
                        Button("删除这个倒数日", role: .destructive) {
                            countdowns.delete(draft.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "新建倒数日" : "编辑倒数日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "添加" : "保存") {
                        draft.title = draft.title.trimmingCharacters(in: .whitespaces)
                        countdowns.upsert(draft)
                        onSaved(draft, isNew)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("countdown.save")
                }
            }
        }
        .presentationDetents([.large])
    }
}
