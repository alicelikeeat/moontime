import SwiftUI

enum GlassTone { case light, dark }

// MARK: Appearance setting

/// User-adjustable look: background, glass style and how frosted the glass is.
struct GlassAppearance: Equatable {
    enum Background: String, CaseIterable, Identifiable {
        case plain, ambient
        var id: String { rawValue }
        var title: String { self == .plain ? "纯白" : "氛围光" }
    }

    enum Style: String, CaseIterable, Identifiable {
        case clear, regular
        var id: String { rawValue }
        var title: String { self == .clear ? "透明" : "标准" }
    }

    var background: Background = .plain
    var style: Style = .clear
    /// 0 = fully clear, 1 = milky.
    var frost: Double = 0

    static let backgroundKey = "appearance.background"
    static let styleKey = "appearance.glass"
    static let frostKey = "appearance.frost"
}

private struct GlassAppearanceKey: EnvironmentKey {
    static let defaultValue = GlassAppearance()
}

extension EnvironmentValues {
    var glassAppearance: GlassAppearance {
        get { self[GlassAppearanceKey.self] }
        set { self[GlassAppearanceKey.self] = newValue }
    }
}

// MARK: Glass surface

extension View {
    /// Liquid Glass on iOS 26+, a hand-made glass look on older systems.
    /// Follows the appearance setting. `tint` is used as-is (pass a low
    /// opacity for a subtle tint) and replaces the frost tint.
    func glassSurface<S: Shape>(
        in shape: S, tint: Color? = nil, interactive: Bool = false, tone: GlassTone = .light
    ) -> some View {
        modifier(GlassSurface(shape: shape, tint: tint, interactive: interactive, tone: tone))
    }
}

private struct GlassSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool
    let tone: GlassTone
    @Environment(\.glassAppearance) private var look

    private var frostColor: Color {
        (tone == .light ? Color.white : Color.black).opacity(look.frost * 0.5)
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(liquidGlass, in: shape)
        } else {
            content
                .background {
                    ZStack {
                        if look.style == .regular {
                            shape.fill(.ultraThinMaterial)
                        } else {
                            shape.fill(.white.opacity(tone == .light ? 0.12 : 0.05))
                        }
                        shape.fill(tint ?? frostColor)
                    }
                }
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(tone == .light ? 0.95 : 0.35), .white.opacity(tone == .light ? 0.25 : 0.05)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: .black.opacity(tone == .light ? 0.08 : 0.35), radius: 12, y: 6)
        }
    }

    @available(iOS 26.0, *)
    private var liquidGlass: Glass {
        let base: Glass = look.style == .clear ? .clear : .regular
        let tinted = base.tint(tint ?? (look.frost > 0.01 ? frostColor : nil))
        return tinted.interactive(interactive)
    }
}

extension View {
    /// A button drawn by the system's own glass button style on iOS 26
    /// (it owns the touch handling), with our glass look on older systems.
    @ViewBuilder
    func systemGlassButton<S: Shape>(prominent: Bool = false, tint: Color? = nil, shape: S) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent).tint(tint).buttonBorderShape(.circle)
            } else {
                buttonStyle(.glass).tint(tint).buttonBorderShape(.capsule)
            }
        } else {
            buttonStyle(.plain).glassSurface(in: shape, tint: tint, interactive: true)
        }
    }
}

/// Lets neighbouring glass shapes blend and morph into each other on iOS 26.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

extension View {
    /// Identity for morphing between glass shapes inside a `GlassGroup` (iOS 26+).
    @ViewBuilder
    func glassID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// Glass shapes sharing a union id render as one continuous piece of glass.
    /// Give each view its own id to split them apart again.
    @ViewBuilder
    func glassUnion(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffectUnion(id: id, namespace: namespace)
        } else {
            self
        }
    }

    /// Glass that materializes in and out; a springy scale on older systems.
    @ViewBuilder
    func glassPop() -> some View {
        if #available(iOS 26.0, *) {
            glassEffectTransition(.materialize)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        } else {
            transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }
}

/// App-wide chrome: whether the tab bar is shrunk, and the glass message above it.
@Observable
@MainActor
final class ChromeState {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let symbol: String
    }

    var tabBarCollapsed = false
    var toast: Toast?

    @ObservationIgnored private var toastTask: Task<Void, Never>?

    func show(_ text: String, symbol: String = "checkmark") {
        toastTask?.cancel()
        withAnimation(.bouncy(duration: 0.45)) { toast = Toast(text: text, symbol: symbol) }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.35)) { self?.toast = nil }
        }
    }

    func setTabBarCollapsed(_ collapsed: Bool) {
        guard tabBarCollapsed != collapsed else { return }
        withAnimation(.bouncy(duration: 0.45)) { tabBarCollapsed = collapsed }
    }
}

/// Shrinks the tab bar while scrolling down, restores it when scrolling up (iOS 18+).
struct CollapsesTabBarOnScroll: ViewModifier {
    @Environment(ChromeState.self) private var chrome

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { old, new in
                // Big jumps are programmatic (scrollTo), not the user swiping.
                guard abs(new - old) < 150 else { return }
                if new < 40 {
                    chrome.setTabBarCollapsed(false)
                } else if new - old > 6 {
                    chrome.setTabBarCollapsed(true)
                } else if new - old < -6 {
                    chrome.setTabBarCollapsed(false)
                }
            }
        } else {
            content
        }
    }
}

extension View {
    func collapsesTabBarOnScroll() -> some View { modifier(CollapsesTabBarOnScroll()) }
}

/// Page background: plain (pure white, or solid dark on the focus screen)
/// or soft colour fields for the glass to refract.
struct AmbientBackground: View {
    var dark = false
    @Environment(\.glassAppearance) private var look

    var body: some View {
        ZStack {
            dark ? Palette.focusBackground : (look.background == .plain ? Color.white : Palette.background)
            if look.background == .ambient {
                blob(dark ? Palette.focusAccent : Palette.accent, opacity: dark ? 0.35 : 0.16, size: 360)
                    .offset(x: -150, y: -300)
                blob(Color(hex: 0x7B61FF), opacity: dark ? 0.28 : 0.13, size: 320)
                    .offset(x: 170, y: 40)
                blob(Color(hex: 0xF97316), opacity: dark ? 0.12 : 0.10, size: 300)
                    .offset(x: -110, y: 380)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func blob(_ color: Color, opacity: Double, size: CGFloat) -> some View {
        Circle().fill(color.opacity(opacity)).frame(width: size, height: size).blur(radius: 90)
    }
}

/// Frosted strip behind the status bar so scrolled content doesn't collide with it.
/// Use with `.safeAreaInset(edge: .top, spacing: 0)`; it adds no height of its own.
struct TopScrollEdgeBlur: View {
    var body: some View {
        Color.clear
            .frame(height: 0)
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: .top)
            .accessibilityHidden(true)
    }
}
