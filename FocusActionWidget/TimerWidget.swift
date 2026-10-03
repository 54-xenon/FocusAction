//
//  TimerWidget.swift
//  FocusActionWidget
//
//  現在のタイマー状態を表示するホーム画面 / ロック画面 Widget
//

import WidgetKit
import SwiftUI

struct TimerWidgetEntry: TimelineEntry {
    let date: Date
    let state: TimerWidgetState
    /// 実行中だったタイマーが終了予定時刻を過ぎた状態
    var isFinished = false
}

struct TimerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerWidgetEntry {
        TimerWidgetEntry(date: .now, state: .idle)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerWidgetEntry) -> Void) {
        completion(TimerWidgetEntry(date: .now, state: WidgetSharedData.loadTimerState()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerWidgetEntry>) -> Void) {
        let state = WidgetSharedData.loadTimerState()
        let now = Date.now

        var entries: [TimerWidgetEntry] = []
        if state.isTimerRunning && state.endDate > now {
            entries.append(TimerWidgetEntry(date: now, state: state))
            // 終了予定時刻に「完了」表示へ切り替える（アプリが起動していなくても進むように）
            entries.append(TimerWidgetEntry(date: state.endDate, state: state, isFinished: true))
        } else {
            entries.append(TimerWidgetEntry(date: now, state: state, isFinished: state.isTimerRunning))
        }
        // 状態が変わるとアプリ側から reloadTimelines するので、こちらからは更新しない
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct TimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSharedData.Kind.timer, provider: TimerWidgetProvider()) { entry in
            TimerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("タイマー")
        .description("現在のポモドーロタイマーの残り時間を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Views

private struct TimerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimerWidgetEntry

    private var state: TimerWidgetState { entry.state }
    private var mode: TimerMode { state.timerMode }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            Label {
                if entry.isFinished {
                    Text("\(mode.title) 完了")
                } else {
                    TimerWidgetText(entry: entry)
                }
            } icon: {
                Image(systemName: mode.icon)
            }
        case .systemMedium:
            medium
        default:
            small
        }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 0)
            timeLabel
                .font(.system(size: 34, weight: .semibold).monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            TimerWidgetProgressBar(entry: entry, thickness: 8)
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            TimerWidgetRing(entry: entry, lineWidth: 10)
                .frame(width: 110, height: 110)
                .overlay {
                    Image(systemName: mode.icon)
                        .font(.title)
                        .foregroundStyle(mode.color)
                }
            VStack(alignment: .leading, spacing: 8) {
                header
                timeLabel
                    .font(.system(size: 40, weight: .semibold).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                TagRow(state: state)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Label(mode.title, systemImage: mode.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(mode.color)
            Spacer(minLength: 0)
            Text(statusText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var timeLabel: some View {
        if entry.isFinished {
            Text("完了！")
        } else {
            TimerWidgetText(entry: entry)
        }
    }

    private var statusText: String {
        if entry.isFinished { return "完了" }
        if state.isTimerRunning { return "実行中" }
        return state.timeRemaining < state.totalTime ? "一時停止" : "待機中"
    }

    // MARK: Lock Screen

    private var circular: some View {
        TimerWidgetRing(entry: entry, lineWidth: 5)
            .overlay {
                Image(systemName: entry.isFinished ? "checkmark" : mode.icon)
                    .font(.title3)
            }
            .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(mode.title, systemImage: mode.icon)
                .font(.headline)
                .widgetAccentable()
            timeLabel
                .font(.title2.monospacedDigit().weight(.semibold))
            TimerWidgetProgressBar(entry: entry, thickness: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 実行中はシステムにカウントダウンさせ、停止中は残り時間を固定表示する
private struct TimerWidgetText: View {
    let entry: TimerWidgetEntry

    var body: some View {
        let state = entry.state
        if state.isTimerRunning {
            Text(timerInterval: entry.date...max(entry.date, state.endDate), countsDown: true)
        } else {
            Text(Duration.seconds(state.timeRemaining), format: .time(pattern: .minuteSecond))
        }
    }
}

private struct TimerWidgetProgressBar: View {
    let entry: TimerWidgetEntry
    var thickness: CGFloat

    /// 標準の linear ProgressView のバーの高さ
    private let systemBarHeight: CGFloat = 4

    var body: some View {
        let state = entry.state
        Group {
            if state.isTimerRunning && !entry.isFinished {
                ProgressView(
                    timerInterval: state.startDate...max(state.startDate, state.endDate),
                    countsDown: true
                ) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: entry.isFinished ? 0 : remainingFraction(state))
            }
        }
        .progressViewStyle(.linear)
        .tint(state.timerMode.color)
        // Widget ではカスタム描画だと実行中に進捗が進まないため、標準バーを縦に拡大して太くする
        .scaleEffect(x: 1, y: thickness / systemBarHeight)
        .frame(height: thickness)
        .clipShape(Capsule())
    }
}

private struct TimerWidgetRing: View {
    let entry: TimerWidgetEntry
    var lineWidth: CGFloat

    var body: some View {
        let state = entry.state
        if state.isTimerRunning && !entry.isFinished {
            ProgressView(
                timerInterval: state.startDate...max(state.startDate, state.endDate),
                countsDown: true
            ) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(state.timerMode.color)
        } else {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: entry.isFinished ? 0 : remainingFraction(state))
                    .stroke(state.timerMode.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .padding(lineWidth / 2)
        }
    }
}

private struct TagRow: View {
    let state: TimerWidgetState

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

private func remainingFraction(_ state: TimerWidgetState) -> Double {
    state.totalTime > 0 ? state.timeRemaining / state.totalTime : 0
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerWidgetEntry(date: .now, state: .idle)
    TimerWidgetEntry(date: .now, state: TimerWidgetState(
        timerModeRawValue: TimerMode.focus.rawValue,
        isTimerRunning: true,
        timeRemaining: 18 * 60,
        totalTime: TimerMode.focus.duration,
        endDate: .now.addingTimeInterval(18 * 60),
        tagTitle: "勉強",
        tagEmoji: "📚",
        tagColorHex: "#F59E0B"
    ))
}

#Preview("Medium", as: .systemMedium) {
    TimerWidget()
} timeline: {
    TimerWidgetEntry(date: .now, state: TimerWidgetState(
        timerModeRawValue: TimerMode.shortBreak.rawValue,
        isTimerRunning: false,
        timeRemaining: 3 * 60,
        totalTime: TimerMode.shortBreak.duration,
        endDate: .now
    ))
}
