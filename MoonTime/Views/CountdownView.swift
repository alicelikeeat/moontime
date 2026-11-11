import SwiftUI

struct CountdownView: View {
    @Environment(CountdownStore.self) private var countdowns
    @Environment(ChromeState.self) private var chrome
    var onAdd: () -> Void
    var onEdit: (Countdown) -> Void

    var body: some View {
        let featured = countdowns.featured
        let others = countdowns.sorted.filter { $0.id != featured?.id }

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(countdowns.items.count) 个日子")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.secondaryLabel)
                            .contentTransition(.numericText())
                        Text("倒数日").font(.system(size: 26, weight: .bold)).tracking(-0.4)
                    }
                    Spacer()
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .systemGlassButton(shape: Circle())
                    .accessibilityLabel("新建倒数日")
                    .accessibilityIdentifier("countdown.add")
                }
                .padding(.horizontal, 4)

                if let featured {
                    FeaturedCountdownCard(countdown: featured)
                        .onTapGesture { onEdit(featured) }
                        .contextMenu { menu(for: featured) }
                        .transition(.blurReplace)
                        .id(featured.id)
                }

                ForEach(others) { item in
                    CountdownRow(countdown: item)
                        .onTapGesture { onEdit(item) }
                        .contextMenu { menu(for: item) }
                        .glassPop()
                }

                if countdowns.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "hourglass").font(.system(size: 28, weight: .light))
                        Text("还没有倒数日").font(.system(size: 12))
                    }
                    .foregroundStyle(Palette.secondaryLabel)
                    .frame(maxWidth: .infinity, minHeight: 160)
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

    @ViewBuilder
    private func menu(for item: Countdown) -> some View {
        Button(item.pinned ? "取消置顶" : "置顶", systemImage: item.pinned ? "pin.slash" : "pin") {
            withAnimation(.bouncy(duration: 0.5)) { countdowns.togglePin(item.id) }
        }
        Button("编辑", systemImage: "pencil") { onEdit(item) }
        Button("删除", systemImage: "trash", role: .destructive) {
            withAnimation(.bouncy) { countdowns.delete(item.id) }
            chrome.show("已删除「\(item.title)」", symbol: "trash")
        }
    }
}

/// Large card for the pinned (or nearest) day.
private struct FeaturedCountdownCard: View {
    let countdown: Countdown

    var body: some View {
        let phrase = countdown.phrase()
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SymbolBadge(symbol: countdown.symbol, color: countdown.color, size: 28)
                Text(countdown.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                if countdown.pinned {
                    Label("置顶", systemImage: "pin.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(countdown.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(countdown.color.opacity(0.1), in: Capsule())
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(phrase.lead)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.secondaryLabel)
                Text(phrase.number)
                    .font(.system(size: 64, weight: .thin))
                    .monospacedDigit()
                    .tracking(-2)
                    .foregroundStyle(countdown.color)
                    .contentTransition(.numericText())
                Text(phrase.unit)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.secondaryLabel)
            }
            HStack {
                Text(TimeFormat.fullDate(countdown.target()))
                if countdown.repeatsYearly {
                    Text("· 每年")
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(Palette.secondaryLabel)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(in: RoundedRectangle(cornerRadius: 28), tint: countdown.color.opacity(0.08))
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("countdown.featured")
    }
}

private struct CountdownRow: View {
    let countdown: Countdown

    var body: some View {
        let phrase = countdown.phrase()
        HStack(spacing: 12) {
            SymbolBadge(symbol: countdown.symbol, color: countdown.color, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(countdown.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(TimeFormat.fullDate(countdown.target()) + (countdown.repeatsYearly ? " · 每年" : ""))
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.secondaryLabel)
            }
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(phrase.lead).font(.system(size: 9)).foregroundStyle(Palette.secondaryLabel)
                Text(phrase.number)
                    .font(.system(size: 22, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(countdown.days() < 0 ? Palette.secondaryLabel : countdown.color)
                    .contentTransition(.numericText())
                Text(phrase.unit).font(.system(size: 9)).foregroundStyle(Palette.secondaryLabel)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassSurface(in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct SymbolBadge: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }
}
