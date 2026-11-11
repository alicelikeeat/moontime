import SwiftUI

struct NewBlockSheet: View {
    @Environment(DayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var note = ""
    @State private var category: BlockCategory = .deepWork
    @State private var start = Date.now
    @State private var minutes = 60

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                    TextField("备注（可选）", text: $note)
                }
                Section {
                    Picker("类型", selection: $category) {
                        ForEach(BlockCategory.allCases) { Text($0.name).tag($0) }
                    }
                    DatePicker("开始", selection: $start, displayedComponents: .hourAndMinute)
                    Stepper("时长 \(TimeFormat.duration(TimeInterval(minutes * 60)))", value: $minutes, in: 15...480, step: 15)
                }
            }
            .navigationTitle("新建时间块")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: suggestStart)
        }
        .presentationDetents([.fraction(0.64), .large])
    }

    /// Default to the next free slot on the selected day.
    private func suggestStart() {
        let day = store.selectedDate
        start = store.freeSlots(on: day, minimum: 15 * 60)
            .first { $0.end > .now || !Calendar.current.isDateInToday(day) }?.start
            ?? store.selectedBlocks.last?.end
            ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day)
            ?? day
    }

    private func save() {
        // Keep the picked time but put it on the selected day.
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: start)
        let startDate = calendar.date(
            bySettingHour: time.hour ?? 9, minute: time.minute ?? 0, second: 0, of: store.selectedDate
        ) ?? start
        store.add(TimeBlock(
            title: title.trimmingCharacters(in: .whitespaces),
            note: note.isEmpty ? nil : note,
            start: startDate,
            end: startDate.addingTimeInterval(TimeInterval(minutes * 60)),
            category: category
        ))
        dismiss()
    }
}
