import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case today, inbox, focus, life, review

    var title: String {
        switch self {
        case .today: "今天"
        case .inbox: "收件箱"
        case .focus: "专注"
        case .life: "日常"
        case .review: "复盘"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .inbox: "tray"
        case .focus: "timer"
        case .life: "square.grid.2x2"
        case .review: "chart.bar"
        }
    }
}

struct RootView: View {
    @Environment(DayStore.self) private var store
    @State private var chrome = ChromeState()

    @State private var tab: AppTab = .today
    @State private var showingNewBlock = false
    @State private var showingAppearance = false
    @State private var menuOpen = false
    @Namespace private var glass

    var body: some View {
        ZStack(alignment: .bottom) {
            switch tab {
            case .today:
                TodayView(
                    onStartFocus: { block in
                        store.startFocus(block)
                        go(.focus)
                    },
                    onOpenFocus: { go(.focus) },
                    onOpenInbox: { go(.inbox) }
                )
                .transition(.opacity)
            case .inbox:
                InboxView()
                    .transition(.opacity)
            case .focus:
                FocusView(onClose: { go(.today) })
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            case .life:
                LifeView()
                    .transition(.opacity)
            case .review:
                ReviewView(onPlanTomorrow: { go(.today) })
                    .transition(.opacity)
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
        .sensoryFeedback(.selection, trigger: tab)
        .sensoryFeedback(.impact(weight: .light), trigger: menuOpen)
        .sensoryFeedback(.success, trigger: chrome.toast?.id) { _, new in new != nil }
        .onChange(of: tab) {
            chrome.setTabBarCollapsed(false)
            if menuOpen { toggleMenu() }
        }
        .sheet(isPresented: $showingNewBlock) {
            NewBlockSheet()
        }
        .sheet(isPresented: $showingAppearance) {
            AppearanceSheet()
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
                            .font(.mtHeadline)
                            .foregroundStyle(Palette.accent)
                            .symbolEffect(.bounce, value: toast.id)
                        Text(toast.text)
                            .font(.mtHeadline)
                            .foregroundStyle(Palette.label)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .glassSurface(in: Capsule(), chrome: true)
                    .glassID("toast", in: glass)
                    .glassPop(anchor: .bottomLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("toast")
                }

                if menuOpen {
                    menuItem("新建时间块", symbol: "square.and.pencil", id: "fab.new", order: 3) {
                        toggleMenu()
                        showingNewBlock = true
                    }
                    menuItem("开始专注", symbol: "timer", id: "fab.focus", order: 2) {
                        toggleMenu()
                        if store.focus == nil, let block = store.suggestedFocusBlock() {
                            store.startFocus(block)
                        }
                        go(.focus)
                    }
                    menuItem("从收件箱安排", symbol: "tray", id: "fab.inbox", order: 1) {
                        toggleMenu()
                        go(.inbox)
                    }
                    menuItem("外观", symbol: "paintbrush", id: "fab.appearance", order: 0) {
                        toggleMenu()
                        showingAppearance = true
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    if chrome.tabBarCollapsed {
                        Button {
                            chrome.setTabBarCollapsed(false)
                        } label: {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 56, height: 56)
                                .glassSurface(in: Circle(), interactive: true)
                                .glassID("tabbar", in: glass)
                        }
                        .buttonStyle(.pressScale)
                        .accessibilityLabel("展开标签栏")
                        .accessibilityIdentifier("tabbar.collapsed")
                        Spacer(minLength: 0)
                    } else {
                        FloatingTabBar(selection: $tab, glass: glass)
                    }
                    Button(action: toggleMenu) {
                        Image(systemName: "plus")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Palette.label)
                            .rotationEffect(.degrees(menuOpen ? 45 : 0))
                            .frame(width: 56, height: 56)
                            .contentShape(Circle())
                    }
                    .systemGlassButton(prominent: false, tint: nil, shape: Circle())
                    .glassID("fab", in: glass)
                    .accessibilityLabel(menuOpen ? "关闭菜单" : "快捷操作")
                    .accessibilityIdentifier("new-block")
                }
            }
        }
    }

    /// `order` 0 sits next to the + button and appears first.
    private func menuItem(_ title: String, symbol: String, id: String, order: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.mtTitle)
                .foregroundStyle(Palette.label)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .contentShape(Capsule())
        }
        .systemGlassButton(shape: Capsule())
        .glassID(id, in: glass)
        .glassPop(delay: Double(order) * 0.04, anchor: .bottomTrailing)
        .accessibilityIdentifier(id)
    }

    private func go(_ destination: AppTab) {
        withAnimation(.smooth(duration: 0.25)) { tab = destination }
    }

    private func toggleMenu() {
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.12)) { menuOpen.toggle() }
    }
}

/// Tab bar with a glass lens you can drag across the tabs; it snaps to the
/// nearest one on release. Tapping a tab still works.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var glass: Namespace.ID
    /// Lens centre while the finger is sliding; nil when resting.
    @State private var dragX: CGFloat?

    private let tabs = AppTab.allCases

    var body: some View {
        GeometryReader { geo in
            let itemWidth = geo.size.width / CGFloat(tabs.count)
            let selectedIndex = CGFloat(tabs.firstIndex(of: selection) ?? 0)
            let lensX = dragX ?? (selectedIndex + 0.5) * itemWidth
            let hovered = min(tabs.count - 1, max(0, Int(lensX / itemWidth)))
            let sliding = dragX != nil

            ZStack(alignment: .topLeading) {
                Color.clear
                    .glassSurface(in: Capsule(style: .continuous), tint: Palette.accent.opacity(0.08), interactive: true, elevated: false, chrome: true)
                    .frame(width: itemWidth, height: geo.size.height)
                    .scaleEffect(sliding ? 1.12 : 1)
                    .position(x: lensX, y: geo.size.height / 2)
                    .allowsHitTesting(false)

                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                        let lit = index == hovered
                        Button {
                            withAnimation(.bouncy(duration: 0.4, extraBounce: 0.1)) { selection = tab }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: tab.symbol)
                                    .font(.system(size: 17, weight: .medium))
                                    .symbolEffect(.bounce.down, value: tab == selection)
                                Text(tab.title)
                                    .font(.mtMicro)
                            }
                            .foregroundStyle(lit ? Palette.accent : Palette.secondaryLabel)
                            .scaleEffect(lit && sliding ? 1.08 : 1)
                            .frame(width: itemWidth, height: geo.size.height)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressScale)
                        .accessibilityAddTraits(tab == selection ? .isSelected : [])
                        .accessibilityIdentifier("tab.\(tab)")
                    }
                }
            }
            .animation(.snappy(duration: 0.18), value: hovered)
            .sensoryFeedback(.selection, trigger: hovered)
            .simultaneousGesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        let half = itemWidth / 2
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                            dragX = min(max(value.location.x, half), geo.size.width - half)
                        }
                    }
                    .onEnded { value in
                        let index = min(tabs.count - 1, max(0, Int(value.location.x / itemWidth)))
                        withAnimation(.bouncy(duration: 0.45, extraBounce: 0.12)) {
                            selection = tabs[index]
                            dragX = nil
                        }
                    }
            )
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .glassSurface(in: Capsule(), interactive: true, chrome: true)
        .glassID("tabbar", in: glass)
    }
}
