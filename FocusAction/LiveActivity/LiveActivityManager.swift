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
    func update(with viewModel: TimerViewModel) {
        let state = makeState(from: viewModel)
        let content = ActivityContent(
            state: state,
            staleDate: state.isTimerRunning ? state.endDate : nil
        )

        if let activity {
            Task { await activity.update(content) }
            return
        }

        guard viewModel.isTimerRunning,
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

    private func makeState(from viewModel: TimerViewModel) -> FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            timerModeRawValue: viewModel.timerMode.rawValue,
            isTimerRunning: viewModel.isTimerRunning,
            timeRemaining: viewModel.timeRemaining,
            endDate: Date().addingTimeInterval(viewModel.timeRemaining),
            totalTime: viewModel.totalTime,
            tagTitle: viewModel.selectedTag?.title,
            tagEmoji: viewModel.selectedTag?.emoji,
            tagColorHex: viewModel.selectedTag?.colorHex
        )
    }
}
