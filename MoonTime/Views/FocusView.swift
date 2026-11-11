import SwiftUI

struct FocusView: View {
    @Environment(DayStore.self) private var store
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            topBar
            if let focus = store.focus {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ActiveFocusContent(focus: focus, now: context.date)
                }
            } else {
                emptyState
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AmbientBackground(dark: true))
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .glassSurface(in: Circle(), interactive: true, tone: .dark)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回今天")

            Spacer()

            if let focus = store.focus {
                Label(focus.state.isPaused ? "已暂停" : "专注中", systemImage: "moon.fill")
                    .labelStyle(BadgeLabelStyle())
            }

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundStyle(Palette.moon)
            Text("还没有进行中的专注")
                .font(.system(size: 20, weight: .bold))
            if let block = store.suggestedFocusBlock() {
                Button {
                    store.startFocus(block)
                } label: {
                    Text("开始：\(block.title)")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .glassSurface(in: Capsule(), tint: Palette.focusAccent, interactive: true, tone: .dark)
                }
                .accessibilityIdentifier("focus.start")
                .buttonStyle(.plain)
            } else {
                Text("今天的时间块都完成了")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.focusSecondary)
            }
            Spacer()
        }
    }
}

private struct BadgeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 13)).foregroundStyle(Palette.moon)
            configuration.title.font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassSurface(in: Capsule(), tone: .dark)
    }
}

private struct ActiveFocusContent: View {
    @Environment(DayStore.self) private var store
    let focus: ActiveFocus
    let now: Date

    private var state: FocusActivityAttributes.ContentState { focus.state }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(focus.category.name)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Palette.focusSecondary)
                Text(focus.title)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            ring

            HStack(spacing: 10) {
                stat(value: "\(TimeFormat.minutes(state.elapsed(at: now))) 分", label: "已专注")
                stat(value: TimeFormat.duration(state.total), label: "计划")
                stat(value: "\(focus.pauseCount) 次", label: "暂停")
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button(action: store.togglePause) {
                    Label(state.isPaused ? "继续" : "暂停", systemImage: state.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .glassSurface(in: Capsule(), interactive: true, tone: .dark)
                }
                Button(action: { store.completeFocus() }) {
                    Label("完成", systemImage: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .glassSurface(in: Capsule(), tint: Palette.focusAccent, interactive: true, tone: .dark)
                }
            }
            .buttonStyle(.plain)

            if let nextTitle = state.nextTitle, let nextStart = state.nextStart {
                nextUp(title: nextTitle, start: nextStart)
            }
        }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 14)
            Circle()
                .trim(from: 0, to: state.progress(at: now))
                .stroke(Palette.focusAccent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(TimeFormat.countdown(state.remaining(at: now)))
                    .font(.system(size: 56, weight: .light))
                    .monospacedDigit()
                    .tracking(-1)
                Text("剩余 · \(TimeFormat.clock(state.isPaused ? now.addingTimeInterval(state.remaining(at: now)) : state.endsAt)) 结束")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.focusSecondary)
            }
        }
        .frame(width: 280, height: 280)
        .accessibilityElement(children: .combine)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold))
            Text(label).font(.system(size: 12)).foregroundStyle(Palette.focusSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .glassSurface(in: RoundedRectangle(cornerRadius: 16), tone: .dark)
    }

    private func nextUp(title: String, start: Date) -> some View {
        let next = store.focus.flatMap { store.block(withID: $0.blockID) }.flatMap { store.nextBlock(after: $0) }
        let durationText = next.map { " · \(TimeFormat.duration($0.duration))" } ?? ""
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.phase == .reminder ? "5 分钟后开始" : "接下来")
                        .font(.system(size: 12))
                        .foregroundStyle(state.phase == .reminder ? Palette.reminderIcon : Palette.focusSecondary)
                    Text("\(TimeFormat.clock(start)) \(title)\(durationText)")
                        .font(.system(size: 15, weight: .semibold))
                }
                Spacer()
                if state.phase != .reminder, state.remindAt != nil {
                    Text("提前 5 分钟提醒").font(.system(size: 13)).foregroundStyle(Palette.focusSecondary)
                }
            }
            if state.phase == .reminder {
                HStack(spacing: 8) {
                    Button("推迟 10 分钟", action: store.snoozeReminder)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .glassSurface(in: Capsule(), interactive: true, tone: .dark)
                    Button("好的", action: store.dismissReminder)
                        .foregroundStyle(Color(hex: 0x111318))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .glassSurface(in: Capsule(), tint: .white.opacity(0.9), interactive: true, tone: .dark)
                }
                .font(.system(size: 14, weight: .semibold))
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassSurface(in: RoundedRectangle(cornerRadius: 18), tone: .dark)
    }
}
