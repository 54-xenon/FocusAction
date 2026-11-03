//
//  LiveActivityManager.swift
//  FocusAction
//
//

import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<FocusActivityAttributes>?

    private init() {
        // 初期化
            // アプリ再起動時に前回の Live Activity が残っていれば片付ける
        for activity in Activity<FocusActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// タイマーの開始・一時停止・再開時に呼ぶ。Activity がなければ開始し、あれば更新する。
    func update(state timerState: TimerState, tag: Tag?) {
        let state = makeState(from: timerState, tag: tag)
        let content = ActivityContent(
            state: state,
            staleDate: state.isTimerRunning ? state.endDate : nil
        )

        if let activity {
            Task { await activity.update(content) }
            return
        }

        guard timerState.isRunning,
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            activity = try Activity.request(
                attributes: FocusActivityAttributes(),
                content: content
            )
        } catch {
            // 処理に失敗した場合は、コマンドラインに出力
            #if DEBUG
            print("Live Activity の開始に失敗しました: \(error.localizedDescription)")
            #endif
        }
    }

    /// リセット・モード切替・タイマー完了時に呼ぶ。
    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    private func makeState(from state: TimerState, tag: Tag?) -> FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            timerModeRawValue: state.mode.rawValue,
            isTimerRunning: state.isRunning,
            timeRemaining: state.timeRemaining,
            endDate: Date().addingTimeInterval(state.timeRemaining),
            totalTime: state.totalTime,
            tagTitle: tag?.title,
            tagEmoji: tag?.emoji,
            tagColorHex: tag?.colorHex
        )
    }
}
