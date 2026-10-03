//
//  FocusLiveActivity.swift
//  FocusActionWidget
//
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            LockScreenOrWatchView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.timerMode.title, systemImage: state.timerMode.icon)
                        .font(.headline)
                        .foregroundStyle(state.timerMode.color)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: state)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        TimerProgressBar(state: state)
                        HStack {
                            TagLabel(state: state)
                            Spacer()
                            if !state.isTimerRunning {
                                Label("一時停止中", systemImage: "pause.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: state.timerMode.icon)
                    .foregroundStyle(state.timerMode.color)
            } compactTrailing: {
                TimerText(state: state)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 48)
                    .foregroundStyle(state.timerMode.color)
            } minimal: {
                Image(systemName: state.isTimerRunning ? state.timerMode.icon : "pause.fill")
                    .foregroundStyle(state.timerMode.color)
            }
            .keylineTint(state.timerMode.color)
        }
        // Apple Watch の Smart Stack にも表示する
        .supplementalActivityFamilies([.small])
    }
}

/// iPhone のロック画面（.medium）と Apple Watch（.small）でレイアウトを出し分ける
private struct LockScreenOrWatchView: View {
    @Environment(\.activityFamily) private var activityFamily
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        switch activityFamily {
        case .small:
            WatchView(state: state)
        default:
            LockScreenView(state: state)
        }
    }
}

// MARK: - ロック画面

private struct LockScreenView: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(state.timerMode.title, systemImage: state.timerMode.icon)
                    .font(.headline)
                    .foregroundStyle(state.timerMode.color)
                Spacer()
                TimerText(state: state)
                    .font(.title.monospacedDigit().weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.white)
            }
            TimerProgressBar(state: state)
            HStack {
                TagLabel(state: state)
                Spacer()
                if !state.isTimerRunning {
                    Label("一時停止中", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding()
    }
}

// MARK: - Apple Watch（Smart Stack）

private struct WatchView: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: state.isTimerRunning ? state.timerMode.icon : "pause.fill")
                Text(state.timerMode.title)
                if let emoji = state.tagEmoji, state.tagTitle != nil {
                    Text(emoji)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(state.timerMode.color)

            TimerText(state: state)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)

            TimerProgressBar(state: state, thickness: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}

// MARK: - 共通部品

/// 実行中はシステムにカウントダウンさせ、一時停止中は残り時間を固定表示する
private struct TimerText: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        if state.isTimerRunning {
            Text(timerInterval: Date.now...max(Date.now, state.endDate), countsDown: true)
        } else {
            Text(Duration.seconds(state.timeRemaining), format: .time(pattern: .minuteSecond))
        }
    }
}

/// TimerView の円形プログレスバーと同じ太さ（20pt）の直線バー
private struct TimerProgressBar: View {
    let state: FocusActivityAttributes.ContentState
    var thickness: CGFloat = 20

    /// 標準の linear ProgressView のバーの高さ
    private let systemBarHeight: CGFloat = 4

    var body: some View {
        Group {
            if state.isTimerRunning {
                ProgressView(
                    timerInterval: state.startDate...max(state.startDate, state.endDate),
                    countsDown: true
                ) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: state.totalTime > 0 ? state.timeRemaining / state.totalTime : 0)
            }
        }
        .progressViewStyle(.linear)
        .tint(state.timerMode.color)
        // Live Activity ではカスタム描画だと実行中に進捗が進まないため、標準バーを縦に拡大して太くする
        .scaleEffect(x: 1, y: thickness / systemBarHeight)
        .frame(height: thickness)
        .clipShape(Capsule())
    }
}

private struct TagLabel: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        if let title = state.tagTitle {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: state.tagColorHex ?? "#3B82F6"))
                        .frame(width: 20, height: 20)
                    Text(state.tagEmoji ?? "🏷️")
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: FocusActivityAttributes()) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState(
        timerModeRawValue: TimerMode.focus.rawValue,
        isTimerRunning: true,
        timeRemaining: 20 * 60,
        endDate: .now.addingTimeInterval(20 * 60),
        totalTime: TimerMode.focus.duration,
        tagTitle: "勉強",
        tagEmoji: "📚",
        tagColorHex: "#F59E0B"
    )
    FocusActivityAttributes.ContentState(
        timerModeRawValue: TimerMode.shortBreak.rawValue,
        isTimerRunning: false,
        timeRemaining: 3 * 60,
        endDate: .now.addingTimeInterval(3 * 60),
        totalTime: TimerMode.shortBreak.duration,
        tagTitle: nil,
        tagEmoji: nil,
        tagColorHex: nil
    )
}
