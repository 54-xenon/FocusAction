//
//  WidgetSharedData.swift
//  FocusAction
//
//  アプリと Widget の間で App Group の UserDefaults を介して共有するデータ（iOS専用）
//  iOSアプリ本体と FocusActionWidget Extension の両方の Target に追加してください
//

import Foundation

nonisolated enum WidgetSharedData {
    static let appGroupIdentifier = "group.com.keito.FocusAction"

    enum Kind {
        static let timer = "FocusActionTimerWidget"
        static let history = "FocusActionHistoryWidget"
    }

    private static let timerKey = "widget.timerState"
    private static let historyKey = "widget.historySummary"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Timer

    static func loadTimerState() -> TimerWidgetState {
        load(TimerWidgetState.self, forKey: timerKey) ?? .idle
    }

    static func saveTimerState(_ state: TimerWidgetState) {
        save(state, forKey: timerKey)
    }

    // MARK: - History

    static func loadHistorySummary() -> HistoryWidgetSummary {
        load(HistoryWidgetSummary.self, forKey: historyKey) ?? .empty
    }

    static func saveHistorySummary(_ summary: HistoryWidgetSummary) {
        save(summary, forKey: historyKey)
    }

    // MARK: - Private

    private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }
}

/// タイマー Widget に表示する状態のスナップショット
nonisolated struct TimerWidgetState: Codable, Hashable {
    var timerModeRawValue: String
    var isTimerRunning: Bool
    var timeRemaining: TimeInterval
    var totalTime: TimeInterval
    /// 実行中の終了予定時刻（Text(timerInterval:) でシステム側にカウントダウンさせる）
    var endDate: Date
    var tagTitle: String?
    var tagEmoji: String?
    var tagColorHex: String?

    var timerMode: TimerMode { TimerMode(rawValue: timerModeRawValue) ?? .focus }
    var startDate: Date { endDate.addingTimeInterval(-totalTime) }

    static let idle = TimerWidgetState(
        timerModeRawValue: TimerMode.focus.rawValue,
        isTimerRunning: false,
        timeRemaining: TimerMode.focus.duration,
        totalTime: TimerMode.focus.duration,
        endDate: .distantPast
    )
}

/// 履歴 Widget に表示する集計（HistoryView の統計と同じ基準）
nonisolated struct HistoryWidgetSummary: Codable, Hashable {
    struct DailyTotal: Codable, Hashable {
        var date: Date
        var minutes: Int
    }

    var todayMinutes: Int
    var todaySessionCount: Int
    var thisWeekMinutes: Int
    var completedSessionsCount: Int
    /// 今日を含む直近7日間の集中時間（古い順）
    var last7Days: [DailyTotal]
    var updatedAt: Date

    static let empty = HistoryWidgetSummary(
        todayMinutes: 0,
        todaySessionCount: 0,
        thisWeekMinutes: 0,
        completedSessionsCount: 0,
        last7Days: [],
        updatedAt: .distantPast
    )
}
