import SwiftUI

struct InboxView: View {
    @Environment(DayStore.self) private var store
    @Environment(ChromeState.self) private var chrome

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Metrics.gap) {
                PageHeader(subtitle: "安排到 \(TimeFormat.monthDay(store.selectedDate))的空闲时间", title: "收件箱")
                    .padding(.bottom, 8)

                if store.inbox.isEmpty {
                    EmptyHint(symbol: "tray", text: "收件箱已清空")
                }

                ForEach(store.inbox) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.mtHeadline)
                            Text("预计 \(TimeFormat.duration(item.estimate))")
                                .font(.mtCaption)
                                .foregroundStyle(Palette.secondaryLabel)
                        }
                        Spacer(minLength: 8)
                        PillButton(title: "安排") {
                            var scheduled: TimeBlock?
                            withAnimation(.bouncy(duration: 0.5)) { scheduled = store.schedule(item) }
                            if let scheduled {
                                chrome.show("已安排到 \(TimeFormat.clock(scheduled.start))", symbol: "calendar.badge.plus")
                            }
                        }
                    }
                    .card(padding: 14)
                    .glassPop()
                }
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
}
