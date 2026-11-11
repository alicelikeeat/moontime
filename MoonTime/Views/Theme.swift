import SwiftUI

/// Spacing and corner sizes shared by every screen.
enum Metrics {
    /// Side margin of every page.
    static let page: CGFloat = 20
    /// Gap between cards.
    static let gap: CGFloat = 12
    /// Corner radius of regular cards.
    static let card: CGFloat = 20
    /// Corner radius of small cards (time blocks, badges).
    static let small: CGFloat = 12
    static let cardPadding: CGFloat = 16
    /// Bottom room so content clears the floating tab bar.
    static let tabBarClearance: CGFloat = 110
}

/// Five type roles. Everything on screen uses one of these.
extension Font {
    static let mtLargeTitle = Font.system(size: 26, weight: .bold)
    static let mtTitle = Font.system(size: 14, weight: .semibold)
    static let mtHeadline = Font.system(size: 12, weight: .semibold)
    static let mtBody = Font.system(size: 12)
    static let mtCaption = Font.system(size: 10)
    static let mtMicro = Font.system(size: 9, weight: .medium)
    /// Large thin figures: countdowns, alarms, stats.
    static func mtNumber(_ size: CGFloat) -> Font { .system(size: size, weight: .thin) }
}

/// Same header on every page: small grey subtitle, large title, one action.
struct PageHeader<Trailing: View>: View {
    let subtitle: String
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(.mtCaption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryLabel)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.mtLargeTitle)
                    .tracking(-0.5)
                    .contentTransition(.interpolate)
            }
            Spacer(minLength: 8)
            trailing
        }
    }
}

extension PageHeader where Trailing == EmptyView {
    init(subtitle: String, title: String) {
        self.init(subtitle: subtitle, title: title) { EmptyView() }
    }
}

/// Round glass "+" used in page headers.
struct HeaderAddButton: View {
    let label: String
    let id: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 40, height: 40)
                .glassSurface(in: Circle(), interactive: true)
                .contentShape(Circle())
        }
        .buttonStyle(.pressScale)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}

/// Small glass pill for inline actions ("安排", "移到明天").
struct PillButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mtHeadline)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .glassSurface(in: Capsule(), tint: Palette.accent.opacity(0.08), interactive: true)
                .contentShape(Capsule())
        }
        .buttonStyle(.pressScale)
    }
}

/// The one selection marker used by the tab bar, week strip and switchers.
struct SelectionLens: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Palette.accent.opacity(0.12))
            .overlay(Capsule(style: .continuous).stroke(.white.opacity(0.75), lineWidth: 1))
    }
}

extension View {
    /// A content card: standard padding, full width, glass, 20pt corners.
    func card(padding: CGFloat = Metrics.cardPadding, radius: CGFloat = Metrics.card) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassSurface(in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Frosted fade behind a pinned page header; content scrolls under it.
struct HeaderFade: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.78), .init(color: .clear, location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// White scheme: a thin black edge around every glyph, icon, line and card,
/// so white-on-white stays readable. A shadow on a container is applied to
/// each child separately, so this outlines each element, not the page.
struct InkOutline: ViewModifier {
    func body(content: Content) -> some View {
        if Palette.monochrome {
            content
                .shadow(color: .black, radius: 0.4)
                .shadow(color: .black.opacity(0.85), radius: 0.6)
                .shadow(color: .black.opacity(0.25), radius: 1.6)
        } else {
            content
        }
    }
}
