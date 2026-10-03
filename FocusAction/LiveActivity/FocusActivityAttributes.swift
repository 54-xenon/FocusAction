//
//  FocusActivityAttributes.swift
//  FocusAction
//
//

import Foundation
import ActivityKit

nonisolated struct FocusActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var timerModeRawValue: String
        var isTimerRunning: Bool
        /// 一時停止中に表示する残り時間
        var timeRemaining: TimeInterval
        /// 実行中の終了予定時刻（Text(timerInterval:) でシステム側にカウントダウンさせる）
        var endDate: Date
        var totalTime: TimeInterval
        var tagTitle: String?
        var tagEmoji: String?
        var tagColorHex: String?

        var timerMode: TimerMode { TimerMode(rawValue: timerModeRawValue) ?? .focus }
        /// カウントダウン表示用の開始時刻（ProgressView(timerInterval:) 用）
        var startDate: Date { endDate.addingTimeInterval(-totalTime) }
    }
}
