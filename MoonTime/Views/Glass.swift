import SwiftUI

enum GlassTone { case light, dark }

extension View {
    /// Liquid Glass on iOS 26+, frosted material with a light rim on older systems.
    /// `tint` is used as-is, so pass a low opacity for a subtle tint.
    @ViewBuilder
    func glassSurface<S: Shape>(
        in shape: S, tint: Color? = nil, interactive: Bool = false, tone: GlassTone = .light
    ) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
            background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint { shape.fill(tint) }
                }
            }
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [.white.opacity(tone == .light ? 0.9 : 0.35), .white.opacity(tone == .light ? 0.2 : 0.05)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(tone == .light ? 0.08 : 0.35), radius: 12, y: 6)
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

/// Soft colour fields behind the glass so it has something to refract.
struct AmbientBackground: View {
    var dark = false

    var body: some View {
        ZStack {
            dark ? Palette.focusBackground : Palette.background
            blob(dark ? Palette.focusAccent : Palette.accent, opacity: dark ? 0.35 : 0.16, size: 360)
                .offset(x: -150, y: -300)
            blob(Color(hex: 0x7B61FF), opacity: dark ? 0.28 : 0.13, size: 320)
                .offset(x: 170, y: 40)
            blob(Color(hex: 0xF97316), opacity: dark ? 0.12 : 0.10, size: 300)
                .offset(x: -110, y: 380)
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
