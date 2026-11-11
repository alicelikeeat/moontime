import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

typealias FocusContent = FocusActivityAttributes.ContentState

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenFocusView(context: context)
                .activityBackgroundTint(Palette.liveBackground.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if context.state.phase != .reminder {
                        HStack(spacing: 10) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Palette.liveAccent)
                                .frame(width: 36, height: 36)
                                .background(Palette.islandIconFill, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(context.state.isPaused ? "已暂停" : context.attributes.categoryName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Palette.focusSecondary)
                                Text(context.attributes.taskTitle)
                                    .font(.system(size: 16, weight: .bold))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase != .reminder {
                        FocusTimerText(state: context.state)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Palette.liveAccent)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.phase == .reminder {
                        ReminderContent(state: context.state)
                    } else {
                        VStack(spacing: 12) {
                            FocusProgressBar(state: context.state)
                            HStack(spacing: 8) {
                                Button(intent: ToggleFocusPauseIntent()) {
                                    PillLabel(context.state.isPaused ? "继续" : "暂停", filled: false)
                                }
                                Button(intent: ExtendFocusIntent()) {
                                    PillLabel("+15 分钟", filled: false)
                                }
                                Button(intent: CompleteFocusIntent()) {
                                    PillLabel("完成", filled: true)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                FocusRing(state: context.state)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                FocusTimerText(state: context.state)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.liveAccent)
                    .frame(maxWidth: 64)
            } minimal: {
                FocusRing(state: context.state)
                    .frame(width: 20, height: 20)
            }
            .keylineTint(Palette.liveAccent)
        }
    }
}

// MARK: Lock screen

struct LockScreenFocusView: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    private var state: FocusContent { context.state }

    var body: some View {
        if state.phase == .reminder {
            ReminderContent(state: state)
                .padding(16)
        } else {
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Palette.liveAccent, in: RoundedRectangle(cornerRadius: 8))
                        Text(state.isPaused ? "MoonTime · 已暂停" : "MoonTime · 专注中")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    if !state.isPaused {
                        Text("\(TimeFormat.clock(state.endsAt)) 结束")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(context.attributes.taskTitle)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    FocusTimerText(state: state)
                        .font(.system(size: 26, weight: .semibold))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120, alignment: .trailing)
                }
                FocusProgressBar(state: state)
                HStack(spacing: 10) {
                    Button(intent: ToggleFocusPauseIntent()) {
                        PillLabel(state.isPaused ? "继续" : "暂停", filled: false, size: 15)
                    }
                    Button(intent: CompleteFocusIntent()) {
                        PillLabel("完成", filled: true, size: 15)
                    }
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)
            .padding(16)
        }
    }
}

// MARK: Pieces

struct ReminderContent: View {
    let state: FocusContent

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.reminderIcon)
                    .frame(width: 44, height: 44)
                    .background(Palette.reminderIconFill, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(state.nextTitle ?? "下一项") 即将开始")
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.focusSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                Button(intent: SnoozeReminderIntent()) { PillLabel("推迟 10 分钟", filled: false) }
                Button(intent: DismissReminderIntent()) { PillLabel("好的", filled: true) }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }

    private var subtitle: String {
        guard let start = state.nextStart else { return "当前专注会自动保存" }
        return "\(TimeFormat.clock(start)) 开始 · 当前专注会自动保存"
    }
}

struct FocusTimerText: View {
    let state: FocusContent

    var body: some View {
        Group {
            if state.isPaused {
                Text(TimeFormat.countdown(state.pausedRemaining ?? 0))
            } else {
                Text(timerInterval: state.timerRange, countsDown: true)
            }
        }
        .monospacedDigit()
    }
}

struct FocusRing: View {
    let state: FocusContent

    var body: some View {
        Group {
            if state.isPaused {
                ProgressView(value: state.progress(at: .now))
            } else {
                ProgressView(timerInterval: state.timerRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.circular)
        .tint(Palette.liveAccent)
        .accessibilityLabel("专注进度")
    }
}

struct FocusProgressBar: View {
    let state: FocusContent

    var body: some View {
        Group {
            if state.isPaused {
                ProgressView(value: state.progress(at: .now))
            } else {
                ProgressView(timerInterval: state.timerRange, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(Palette.liveAccent)
    }
}

struct PillLabel: View {
    let text: String
    let filled: Bool
    let size: CGFloat

    init(_ text: String, filled: Bool, size: CGFloat = 14) {
        self.text = text
        self.filled = filled
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(filled ? Color(hex: 0x111318) : .white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(filled ? Color.white : Color.white.opacity(0.16), in: Capsule())
    }
}
