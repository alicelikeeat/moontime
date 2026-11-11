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
