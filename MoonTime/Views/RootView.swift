import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case today, inbox, focus, review

    var title: String {
        switch self {
        case .today: "今天"
        case .inbox: "收件箱"
        case .focus: "专注"
        case .review: "复盘"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .inbox: "tray"
        case .focus: "timer"
        case .review: "chart.bar"
        }
    }
}

struct RootView: View {
    @Environment(DayStore.self) private var store
    @State private var tab: AppTab = .today
    @State private var showingNewBlock = false

    var body: some View {
        ZStack(alignment: .bottom) {
            switch tab {
            case .today:
                TodayView(
                    onStartFocus: { block in
                        store.startFocus(block)
                        tab = .focus
                    },
                    onOpenFocus: { tab = .focus },
                    onOpenInbox: { tab = .inbox }
                )
            case .inbox:
                InboxView()
            case .focus:
                FocusView(onClose: { tab = .today })
            case .review:
                ReviewView(onPlanTomorrow: { tab = .today })
            }

            // The focus screen is full-bleed, like the design.
            if tab != .focus {
                HStack(alignment: .bottom) {
                    FloatingTabBar(selection: $tab)
                    Spacer(minLength: 12)
                    Button {
                        showingNewBlock = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Palette.accent, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                            .shadow(color: Palette.accent.opacity(0.35), radius: 12, y: 8)
                    }
                    .accessibilityLabel("新建时间块")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingNewBlock) {
            NewBlockSheet()
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Palette.accent : Palette.tertiaryLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected {
                            Capsule().fill(Palette.accent.opacity(0.12))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(maxWidth: 278)
        .frame(height: 64)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 15, y: 8)
    }
}
