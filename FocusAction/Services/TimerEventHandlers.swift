//
//  TimerEventHandlers.swift
//  FocusAction
//
//  TimerStore のイベントを受けて、通知・Live Activity・Watch同期・Widget を更新する（iOS専用）
//

import Foundation

enum TimerEventHandlers {
    /// iOS アプリで TimerStore に注入するハンドラ一式
    static func live() -> [any TimerEventHandler] {
        [
            NotificationTimerEventHandler(),
            LiveActivityTimerEventHandler(),
            WatchSyncTimerEventHandler(),
            WidgetTimerEventHandler()
        ]
    }
}

/// タイマー完了時刻のローカル通知
struct NotificationTimerEventHandler: TimerEventHandler {
    var manager = NotificationManager.shared

    func handle(_ event: TimerEvent, context: TimerEventContext) {
        switch event {
        case .started:
            // 一時停止で取り消した通知を再開時にも残り時間で入れ直す
            manager.scheduleTimerCompletionNotification(for: context.state.mode, in: context.state.timeRemaining)
        case .paused, .reset, .modeSwitched, .completed:
            manager.cancelAllNotifications()
        case .tagChanged, .sessionSaved:
            break
        }
    }
}

/// ロック画面・Dynamic Island の Live Activity
struct LiveActivityTimerEventHandler: TimerEventHandler {
    var manager = LiveActivityManager.shared

    func handle(_ event: TimerEvent, context: TimerEventContext) {
        switch event {
        case .started, .paused:
            manager.update(state: context.state, tag: context.tag)
        case .reset, .modeSwitched:
            manager.end()
        case .completed, .tagChanged, .sessionSaved:
            break
        }
    }
}

/// Apple Watch へのタイマー状態の送信
struct WatchSyncTimerEventHandler: TimerEventHandler {
    var manager = TimerSyncManager.shared

    func handle(_ event: TimerEvent, context: TimerEventContext) {
        switch event {
        case .started, .paused, .reset, .modeSwitched:
            manager.sendState(context.state)
        case .completed, .tagChanged, .sessionSaved:
            break
        }
    }
}

/// ホーム画面・ロック画面の Widget
struct WidgetTimerEventHandler: TimerEventHandler {
    func handle(_ event: TimerEvent, context: TimerEventContext) {
        switch event {
        case .started, .paused, .reset, .modeSwitched, .tagChanged:
            WidgetDataWriter.updateTimer(state: context.state, tag: context.tag)
        case .sessionSaved:
            if let modelContext = context.modelContext {
                WidgetDataWriter.updateHistory(using: modelContext)
            }
        case .completed:
            break
        }
    }
}
