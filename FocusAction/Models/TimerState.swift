//
//  TimerState.swift
//  FocusAction
//
//  タイマーの状態と進行ロジック（副作用なし）。iOS/watchOS共通のモデル
//  現在時刻は引数で受け取るため、単体テストで時間を自由に進められる。
//

import Foundation

/// タイマーが最後まで終わったときの記録。TimerViewModel はこれを元にセッションを保存する。
struct TimerCompletion: Equatable {
    let mode: TimerMode
    /// セッション開始時刻（Watch で途中から受信した場合など、不明なら nil）
    let sessionStartDate: Date?
    let duration: TimeInterval
}

struct TimerState: Equatable {
    private(set) var mode: TimerMode
    private(set) var totalTime: TimeInterval
    private(set) var timeRemaining: TimeInterval
    private(set) var sessionStartDate: Date?
    /// 実行中のタイマーが終了する時刻。残り時間は毎回「endDate − 現在時刻」で求めるため、
    /// バックグラウンド中にTimerが止まっても復帰時に正しい残り時間になる。
    private(set) var endDate: Date?

    init(mode: TimerMode = .focus) {
        self.mode = mode
        totalTime = mode.duration
        timeRemaining = mode.duration
    }

    // MARK: - Computed Properties

    var isRunning: Bool { endDate != nil }

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }

    var timeString: String {
        // 残り時間は小数を含むため切り上げて表示する（開始直後に1秒減って見えないように）
        let displaySeconds = Int(timeRemaining.rounded(.up))
        let minutes = displaySeconds / 60
        let seconds = displaySeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // タイマーが最後まで終わった状態か（円の中にタグ選択の代わりに「完了！」を表示する）
    var isCompleted: Bool {
        !isRunning && timeRemaining <= 0
    }

    // MARK: - Control

    /// タイマーを開始（再開）する。新しいセッションが始まった場合は true を返す。
    @discardableResult
    mutating func start(now: Date) -> Bool {
        guard !isRunning, timeRemaining > 0 else { return false }
        endDate = now.addingTimeInterval(timeRemaining)
        guard sessionStartDate == nil else { return false }
        sessionStartDate = now
        return true
    }

    mutating func pause(now: Date) {
        guard isRunning else { return }
        updateTimeRemaining(now: now)
        endDate = nil
    }

    mutating func reset() {
        timeRemaining = totalTime
        endDate = nil
        sessionStartDate = nil
    }

    mutating func switchMode(to newMode: TimerMode) {
        mode = newMode
        totalTime = newMode.duration
        timeRemaining = newMode.duration
        endDate = nil
        sessionStartDate = nil
    }

    /// 残り時間を現在時刻に合わせて更新する。ちょうど終了した場合は完了の記録を返す。
    /// モードの切り替えは呼び出し側（副作用を伴うため）が行う。
    mutating func tick(now: Date) -> TimerCompletion? {
        guard isRunning else { return nil }
        updateTimeRemaining(now: now)
        guard timeRemaining <= 0 else { return nil }

        let completion = TimerCompletion(
            mode: mode,
            sessionStartDate: sessionStartDate,
            duration: totalTime - timeRemaining
        )
        endDate = nil
        sessionStartDate = nil
        return completion
    }

    /// iPhone から WatchConnectivity 経由で届いた最新のタイマー状態を反映する。
    mutating func apply(_ remote: TimerSyncState, now: Date) {
        mode = remote.timerMode
        totalTime = remote.totalTime
        sessionStartDate = remote.sessionStartDate

        guard remote.isTimerRunning else {
            timeRemaining = remote.timeRemaining
            endDate = nil
            return
        }

        let remoteEndDate = remote.referenceDate.addingTimeInterval(remote.timeRemaining)
        let adjustedRemaining = max(0, remoteEndDate.timeIntervalSince(now))
        if adjustedRemaining <= 0 {
            timeRemaining = 0
            endDate = nil
        } else {
            timeRemaining = adjustedRemaining
            endDate = remoteEndDate
        }
    }

    // MARK: - Private

    private mutating func updateTimeRemaining(now: Date) {
        guard let endDate else { return }
        timeRemaining = max(0, endDate.timeIntervalSince(now))
    }
}

extension TimerMode {
    /// タイマー完了後に自動で切り替わる次のモード
    var next: TimerMode {
        switch self {
        case .focus: return .shortBreak
        case .shortBreak: return .focus
        }
    }
}
