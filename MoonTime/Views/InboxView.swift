import SwiftUI

struct InboxView: View {
    @Environment(DayStore.self) private var store
    @Environment(ChromeState.self) private var chrome

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("安排到 \(TimeFormat.monthDay(store.selectedDate))的空闲时间")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.secondaryLabel)
                    Text("收件箱").font(.system(size: 26, weight: .bold))
                }
                .padding(.horizontal, 4)

                if store.inbox.isEmpty {
                    Text("收件箱已清空")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.secondaryLabel)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }

                ForEach(store.inbox) { item in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.system(size: 12, weight: .semibold))
                            Text("预计 \(TimeFormat.duration(item.estimate))")
                                .font(.system(size: 10))
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                        Spacer()
                        Button("安排") {
                            var scheduled: TimeBlock?
                            withAnimation(.bouncy(duration: 0.5)) { scheduled = store.schedule(item) }
                            if let scheduled {
                                chrome.show("已安排到 \(TimeFormat.clock(scheduled.start))", symbol: "calendar.badge.plus")
                            }
                        }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.softAccentText)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 36)
                            .glassSurface(in: Capsule(), tint: Palette.accent.opacity(0.14), interactive: true)
                            .buttonStyle(.pressScale)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassSurface(in: RoundedRectangle(cornerRadius: 20))
                    .glassPop()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .collapsesTabBarOnScroll()
        .safeAreaInset(edge: .top, spacing: 0) { TopScrollEdgeBlur() }
        .background(AmbientBackground())
        .foregroundStyle(Palette.label)
    }
}
