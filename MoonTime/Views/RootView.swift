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
    @State private var chrome = ChromeState()
    @State private var tab: AppTab = .today
    @State private var showingNewBlock = false
    @State private var menuOpen = false
    @Namespace private var glass

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

            if menuOpen {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { toggleMenu() }
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }

            // The focus screen is full-bleed, like the design.
            if tab != .focus {
                bottomChrome
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .environment(chrome)
        .onChange(of: tab) {
            chrome.setTabBarCollapsed(false)
            if menuOpen { toggleMenu() }
        }
        .sheet(isPresented: $showingNewBlock) {
            NewBlockSheet()
        }
    }

    /// Tab bar, add button, quick-action menu and messages share one glass
    /// container, so they merge, split and morph into each other.
    private var bottomChrome: some View {
        // Merge distance stays below the gaps between pieces, so each one
        // keeps its own touch target once settled; they only blend while
        // popping in and out.
        GlassGroup(spacing: 8) {
            VStack(alignment: .trailing, spacing: 12) {
                if let toast = chrome.toast {
                    HStack(spacing: 8) {
                        Image(systemName: toast.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Palette.accent)
                        Text(toast.text)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.label)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 46)
                    .glassSurface(in: Capsule())
                    .glassID("toast", in: glass)
                    .glassPop()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("toast")
                }

                if menuOpen {
                    menuItem("新建时间块", symbol: "square.and.pencil", id: "fab.new") {
                        toggleMenu()
                        showingNewBlock = true
                    }
                    menuItem("开始专注", symbol: "timer", id: "fab.focus") {
                        toggleMenu()
                        if store.focus == nil, let block = store.suggestedFocusBlock() {
                            store.startFocus(block)
                        }
                        tab = .focus
                    }
                    menuItem("从收件箱安排", symbol: "tray", id: "fab.inbox") {
                        toggleMenu()
                        tab = .inbox
                    }
                }

                HStack(alignment: .bottom) {
                    if chrome.tabBarCollapsed {
                        Button {
                            chrome.setTabBarCollapsed(false)
                        } label: {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 64, height: 64)
                                .glassSurface(in: Circle(), interactive: true)
                                .glassID("tabbar", in: glass)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("展开标签栏")
                        .accessibilityIdentifier("tabbar.collapsed")
                    } else {
                        FloatingTabBar(selection: $tab, glass: glass)
                    }
                    Spacer(minLength: 12)
                    Button(action: toggleMenu) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(menuOpen ? 45 : 0))
                            .frame(width: 64, height: 64)
                            .glassSurface(in: Circle(), tint: Palette.accent, interactive: true)
                            .glassID("fab", in: glass)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(menuOpen ? "关闭菜单" : "快捷操作")
                    .accessibilityIdentifier("new-block")
                }
            }
        }
    }

    private func menuItem(_ title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.label)
                .padding(.horizontal, 20)
                .frame(height: 52)
                .glassSurface(in: Capsule(), interactive: true)
                .glassID(id, in: glass)
        }
        .buttonStyle(.plain)
        .glassPop()
        .accessibilityIdentifier(id)
    }

    private func toggleMenu() {
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.12)) { menuOpen.toggle() }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var glass: Namespace.ID
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let selected = tab == selection
                Button {
                    withAnimation(.bouncy(duration: 0.4)) { selection = tab }
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
                            // A liquid lens that slides to the selected tab.
                            Capsule()
                                .fill(Palette.accent.opacity(0.12))
                                .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
                                .matchedGeometryEffect(id: "lens", in: indicator)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("tab.\(tab)")
            }
        }
        .padding(4)
        .frame(maxWidth: 278)
        .frame(height: 64)
        .glassSurface(in: Capsule(), interactive: true)
        .glassID("tabbar", in: glass)
    }
}
