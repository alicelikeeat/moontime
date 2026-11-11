import SwiftUI

/// Glass on the focus screen follows its background: light in the white scheme.
private var focusTone: GlassTone { Palette.focusIsDark ? .dark : .light }

struct FocusView: View {
    @Environment(DayStore.self) private var store
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            topBar
            if let focus = store.focus {
                ActiveFocusContent(focus: focus, onFinished: onClose)
            } else {
                emptyState
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AmbientBackground(dark: true))
        .foregroundStyle(Palette.focusForeground)
        .preferredColorScheme(Palette.focusIsDark ? .dark : .light)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.mtTitle)
                    .frame(width: 44, height: 44)
                    .glassSurface(in: Circle(), interactive: true, tone: focusTone)
            }
            .buttonStyle(.pressScale)
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
                .font(.system(size: 40))
                .foregroundStyle(Palette.moon)
            Text("还没有进行中的专注")
                .font(.system(size: 16, weight: .bold))
            if let block = store.suggestedFocusBlock() {
                Button {
                    store.startFocus(block)
                } label: {
                    Text("开始：\(block.title)")
                        .font(.mtTitle)
                        .foregroundStyle(Palette.onFocusAccent)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .glassSurface(in: Capsule(), tint: Palette.focusAccentFill, interactive: true, tone: focusTone)
                }
                .accessibilityIdentifier("focus.start")
                .buttonStyle(.pressScale)
            } else {
                Text("今天的时间块都完成了")
                    .font(.mtBody)
                    .foregroundStyle(Palette.focusSecondary)
            }
            Spacer()
        }
    }
}

private struct BadgeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.mtBody).foregroundStyle(Palette.moon)
            configuration.title.font(.mtHeadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassSurface(in: Capsule(), tone: focusTone)
    }
}

private struct ActiveFocusContent: View {
    @Environment(DayStore.self) private var store
    @Environment(ChromeState.self) private var chrome
    let focus: ActiveFocus
    var onFinished: () -> Void

    @Namespace private var glass
    @State private var statsMerged = true

    private var state: FocusActivityAttributes.ContentState { focus.state }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(focus.category.name)
                    .font(.mtCaption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Palette.focusSecondary)
                Text(focus.title)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.2)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            ring

            GlassGroup(spacing: 10) {
                HStack(spacing: 10) {
                    // Only this card ticks, every 15 s.
                    TimelineView(.periodic(from: .now, by: 15)) { context in
                        stat(value: "\(TimeFormat.minutes(state.elapsed(at: context.date))) 分", label: "已专注")
                    }
                    stat(value: TimeFormat.duration(state.total), label: "计划")
                    stat(value: "\(focus.pauseCount) 次", label: "暂停")
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.bouncy(duration: 0.7, extraBounce: 0.1)) { statsMerged = false }
            }

            Spacer(minLength: 0)

            // Running: pause and finish are one fused pill of glass.
            // Paused: they split apart and a +15 button pops out between them.
            GlassGroup(spacing: 8) {
                HStack(spacing: state.isPaused ? 12 : 2) {
                    Button(action: store.togglePause) {
                        Label(state.isPaused ? "继续" : "暂停", systemImage: state.isPaused ? "play.fill" : "pause.fill")
                            .font(.mtTitle)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .glassSurface(in: Capsule(), interactive: true, tone: focusTone)
                            .glassUnion(state.isPaused ? "pause" : "controls", in: glass)
                            .glassID("pause", in: glass)
                    }
                    .accessibilityIdentifier("focus.pause")

                    if state.isPaused {
                        Button(action: store.extendFocus) {
                            Text("+15")
                                .font(.mtTitle)
                                .frame(width: 64, height: 50)
                                .glassSurface(in: Capsule(), interactive: true, tone: focusTone)
                                .glassID("extend", in: glass)
                        }
                        .accessibilityLabel("延长 15 分钟")
                        .glassPop()
                    }

                    Button(action: finish) {
                        Label("完成", systemImage: "checkmark")
                            .font(.mtTitle)
                            .foregroundStyle(Palette.onFocusAccent)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .glassSurface(in: Capsule(), tint: Palette.focusAccentFill, interactive: true, tone: focusTone)
                            .glassUnion(state.isPaused ? "finish" : "controls", in: glass)
                            .glassID("finish", in: glass)
                    }
                    .accessibilityIdentifier("focus.finish")
                }
                .buttonStyle(.pressScale)
            }
            .animation(.bouncy(duration: 0.55, extraBounce: 0.12), value: state.isPaused)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: state.isPaused)

            if let nextTitle = state.nextTitle, let nextStart = state.nextStart {
                nextUp(title: nextTitle, start: nextStart)
            }
        }
    }

    private func finish() {
        let minutes = TimeFormat.minutes(state.elapsed(at: .now))
        let title = focus.title
        store.completeFocus()
        chrome.show("完成：\(title) · 专注 \(minutes) 分钟")
        onFinished()
    }

    private var ring: some View {
        ZStack {
            // Breathing glow: a radial gradient (cheap) instead of a live blur.
            Circle()
                .fill(RadialGradient(
                    colors: [Palette.focusAccent.opacity(state.isPaused ? 0 : 0.28), .clear],
                    center: .center, startRadius: 80, endRadius: 175
                ))
                .frame(width: 350, height: 350)
                .phaseAnimator([false, true]) { glow, inhale in
                    glow.scaleEffect(inhale ? 1.06 : 0.94).opacity(inhale ? 1 : 0.65)
                } animation: { _ in .easeInOut(duration: 2.6) }
                .animation(.smooth(duration: 0.6), value: state.isPaused)
                .allowsHitTesting(false)
            Circle().stroke(Palette.focusTrack, lineWidth: 8)
            Color.clear
                .glassSurface(in: Circle(), tone: focusTone)
                .padding(22)
            // Only the progress arc and the digits redraw each second.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                FocusDialFace(state: state, now: context.date)
            }
        }
        .frame(width: 248, height: 248)
        .accessibilityElement(children: .combine)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.mtTitle)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label).font(.mtCaption).foregroundStyle(Palette.focusSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous), tone: focusTone)
        .glassUnion(statsMerged ? "stats" : "stat.\(label)", in: glass)
    }

    private func nextUp(title: String, start: Date) -> some View {
        let next = store.focus.flatMap { store.block(withID: $0.blockID) }.flatMap { store.nextBlock(after: $0) }
        let durationText = next.map { " · \(TimeFormat.duration($0.duration))" } ?? ""
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.phase == .reminder ? "5 分钟后开始" : "接下来")
                        .font(.mtCaption)
                        .foregroundStyle(state.phase == .reminder ? Palette.reminderIcon : Palette.focusSecondary)
                    Text("\(TimeFormat.clock(start)) \(title)\(durationText)")
                        .font(.mtHeadline)
                }
                Spacer()
                if state.phase != .reminder, state.remindAt != nil {
                    Text("提前 5 分钟提醒").font(.mtBody).foregroundStyle(Palette.focusSecondary)
                }
            }
            if state.phase == .reminder {
                HStack(spacing: 8) {
                    Button("推迟 10 分钟", action: store.snoozeReminder)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .glassSurface(in: Capsule(), interactive: true, tone: focusTone)
                    Button("好的", action: store.dismissReminder)
                        .foregroundStyle(Color(hex: 0x111318))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .glassSurface(in: Capsule(), tint: .white.opacity(0.9), interactive: true, tone: focusTone)
                }
                .font(.mtHeadline)
                .buttonStyle(.pressScale)
                .glassPop()
            }
        }
        .animation(.bouncy(duration: 0.5), value: state.phase)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassSurface(in: RoundedRectangle(cornerRadius: Metrics.card, style: .continuous), tone: focusTone)
    }
}

/// The parts of the focus dial that change every second.
private struct FocusDialFace: View {
    let state: FocusActivityAttributes.ContentState
    let now: Date

    var body: some View {
        let remaining = state.remaining(at: now)
        let progress = state.progress(at: now)
        ZStack {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.focusAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            VStack(spacing: 4) {
                Text(TimeFormat.countdown(remaining))
                    .font(.system(size: 46, weight: .thin))
                    .monospacedDigit()
                    .tracking(-1.5)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy(duration: 0.35), value: Int(remaining))
                Text("剩余 · \(TimeFormat.clock(state.isPaused ? now.addingTimeInterval(remaining) : state.endsAt)) 结束")
                    .font(.mtBody)
                    .foregroundStyle(Palette.focusSecondary)
            }
        }
    }
}
