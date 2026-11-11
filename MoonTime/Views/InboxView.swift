import SwiftUI

struct InboxView: View {
    @Environment(DayStore.self) private var store

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("安排到 \(TimeFormat.monthDay(store.selectedDate))的空闲时间")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.secondaryLabel)
                    Text("收件箱").font(.system(size: 34, weight: .bold))
                }
                .padding(.horizontal, 4)

                if store.inbox.isEmpty {
                    Text("收件箱已清空")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }

                ForEach(store.inbox) { item in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.system(size: 15, weight: .semibold))
                            Text("预计 \(TimeFormat.duration(item.estimate))")
                                .font(.system(size: 12))
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                        Spacer()
                        Button("安排") { store.schedule(item) }
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .safeAreaInset(edge: .top, spacing: 0) { TopScrollEdgeBlur() }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }
}
