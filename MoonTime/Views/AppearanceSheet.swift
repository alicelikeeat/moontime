import SwiftUI

/// Background and glass controls. Changes show live behind the sheet.
struct AppearanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(GlassAppearance.backgroundKey) private var background = GlassAppearance.Background.plain
    @AppStorage(GlassAppearance.styleKey) private var glassStyle = GlassAppearance.Style.clear
    @AppStorage(GlassAppearance.frostKey) private var frost = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("背景") {
                    Picker("背景", selection: $background) {
                        ForEach(GlassAppearance.Background.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("appearance.background")
                }
                Section {
                    Picker("玻璃", selection: $glassStyle) {
                        ForEach(GlassAppearance.Style.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("appearance.glass")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("雾化程度")
                            Spacer()
                            Text(frost, format: .percent.precision(.fractionLength(0)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $frost, in: 0...1) {
                            Text("雾化程度")
                        } minimumValueLabel: {
                            Image(systemName: "circle.dashed")
                        } maximumValueLabel: {
                            Image(systemName: "circle.fill")
                        }
                        .accessibilityIdentifier("appearance.frost")
                    }
                } header: {
                    Text("玻璃")
                } footer: {
                    Text("透明：iOS 26 的 Clear Liquid Glass，最通透。标准：带模糊的常规玻璃。雾化程度越高，玻璃越白、文字越清楚。")
                }
                Section {
                    Button("恢复默认（纯白 + 透明）") {
                        withAnimation {
                            background = .plain
                            glassStyle = .clear
                            frost = 0
                        }
                    }
                }
            }
            .navigationTitle("外观")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }
}
