//
//  WidgetDataWriter.swift
//  FocusAction
//
//  アプリ側の状態を App Group に書き込み、Widget のタイムラインを更新する（iOS専用）
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetDataWriter {
    /// タイマーの開始・一時停止・リセット・モード切替時に呼ぶ
    static func updateTimer(with viewModel: TimerViewModel) {
        let state = TimerWidgetState(
            timerModeRawValue: viewModel.timerMode.rawValue,
            isTimerRunning: viewModel.isTimerRunning,
            timeRemaining: viewModel.timeRemaining,
            totalTime: viewModel.totalTime,
            endDate: Date().addingTimeInterval(viewModel.timeRemaining),
            tagTitle: viewModel.selectedTag?.title,
            tagEmoji: viewModel.selectedTag?.emoji,
            tagColorHex: viewModel.selectedTag?.colorHex
        )
        WidgetSharedData.saveTimerState(state)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedData.Kind.timer)
    }

    /// セッションの保存・削除時やアプリがアクティブになった時に呼ぶ
    static func updateHistory(using modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }
        let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) ?? today

        let sessions: [FocusSession]
        do {
            sessions = try modelContext.fetch(FetchDescriptor<FocusSession>())
        } catch {
            #if DEBUG
            print("Widget用の履歴取得エラー: \(error.localizedDescription)")
            #endif
            return
        }

        let focusSessions = sessions.filter { $0.sessionType == .focus }
        let todaySessions = focusSessions.filter { calendar.startOfDay(for: $0.startDate) == today }
        let last7Days = (0..<7).compactMap { offset -> HistoryWidgetSummary.DailyTotal? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: sevenDaysAgo) else { return nil }
            let minutes = focusSessions
                .filter { calendar.startOfDay(for: $0.startDate) == date }
                .reduce(0) { $0 + $1.durationInMinutes }
            return .init(date: date, minutes: minutes)
        }

        let summary = HistoryWidgetSummary(
            todayMinutes: todaySessions.reduce(0) { $0 + $1.durationInMinutes },
            todaySessionCount: todaySessions.count,
            thisWeekMinutes: focusSessions
                .filter { $0.startDate >= weekStart }
                .reduce(0) { $0 + $1.durationInMinutes },
            completedSessionsCount: sessions.filter { $0.isCompleted }.count,
            last7Days: last7Days,
            updatedAt: now
        )
        WidgetSharedData.saveHistorySummary(summary)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedData.Kind.history)
    }
}
