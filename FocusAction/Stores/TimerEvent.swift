//
//  TimerEvent.swift
//  FocusAction
//
//  TimerStore が状態の変化を外部（通知・Live Activity・Watch同期・Widget など）に伝えるための定義。
//  iOS/watchOS共通。具体的な副作用は TimerEventHandler の実装として注入する。
//

import SwiftData

enum TimerEvent: Equatable {
    /// 開始・再開
    case started
    case paused
    case reset
    case modeSwitched
    /// タイマーが最後まで終わった（この直後に次のモードへの modeSwitched が続く）
    case completed(TimerCompletion)
    case tagChanged
    /// 完了したセッションを SwiftData に保存した
    case sessionSaved
}

/// イベント発生時点の状態。ハンドラはここから必要な値を読む。
struct TimerEventContext {
    let state: TimerState
    let tag: Tag?
    let modelContext: ModelContext?
}

protocol TimerEventHandler {
    func handle(_ event: TimerEvent, context: TimerEventContext)
}
