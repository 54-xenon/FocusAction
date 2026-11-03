//
//  FocusActionTests.swift
//  FocusActionTests
//
//

import Foundation
import Testing
@testable import FocusAction

@MainActor
struct TimerStateTests {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - 初期状態

    @Test func 初期状態は集中モードで停止している() {
        let state = TimerState()
        #expect(state.mode == .focus)
        #expect(state.totalTime == 25 * 60)
        #expect(state.timeRemaining == 25 * 60)
        #expect(!state.isRunning)
        #expect(state.sessionStartDate == nil)
        #expect(!state.isCompleted)
        #expect(state.progress == 1)
        #expect(state.timeString == "25:00")
    }

    // MARK: - 開始・一時停止

    @Test func 開始すると新しいセッションになり終了時刻が決まる() {
        var state = TimerState()
        let isNewSession = state.start(now: t0)
        #expect(isNewSession)
        #expect(state.isRunning)
        #expect(state.sessionStartDate == t0)
        #expect(state.endDate == t0.addingTimeInterval(25 * 60))
    }

    @Test func 実行中に開始しても何も変わらない() {
        var state = TimerState()
        state.start(now: t0)
        let before = state
        let isNewSession = state.start(now: t0.addingTimeInterval(10))
        #expect(!isNewSession)
        #expect(state == before)
    }

    @Test func 一時停止すると経過分だけ残り時間が減って止まる() {
        var state = TimerState()
        state.start(now: t0)
        state.pause(now: t0.addingTimeInterval(100))
        #expect(!state.isRunning)
        #expect(state.timeRemaining == 25 * 60 - 100)
        #expect(state.endDate == nil)
        #expect(state.sessionStartDate == t0)
    }

    @Test func 再開は同じセッションの続きで一時停止中の時間は数えない() {
        var state = TimerState()
        state.start(now: t0)
        state.pause(now: t0.addingTimeInterval(100))
        let isNewSession = state.start(now: t0.addingTimeInterval(1000))
        #expect(!isNewSession)
        #expect(state.sessionStartDate == t0)
        #expect(state.endDate == t0.addingTimeInterval(1000 + 25 * 60 - 100))
    }

    @Test func 残り時間0のままでは開始できない() {
        var state = TimerState()
        state.apply(remote(running: true, remaining: 10, reference: t0), now: t0.addingTimeInterval(60))
        #expect(state.isCompleted)
        let isNewSession = state.start(now: t0.addingTimeInterval(61))
        #expect(!isNewSession)
        #expect(!state.isRunning)
    }

    // MARK: - tick・完了

    @Test func 終了前のtickは残り時間を更新するだけ() {
        var state = TimerState()
        state.start(now: t0)
        let completion = state.tick(now: t0.addingTimeInterval(60))
        #expect(completion == nil)
        #expect(state.isRunning)
        #expect(state.timeRemaining == 25 * 60 - 60)
        #expect(state.timeString == "24:00")
    }

    @Test func 停止中のtickは何もしない() {
        var state = TimerState()
        state.start(now: t0)
        state.pause(now: t0.addingTimeInterval(60))
        let before = state
        #expect(state.tick(now: t0.addingTimeInterval(10_000)) == nil)
        #expect(state == before)
    }

    @Test func 終了時刻を過ぎたtickで完了の記録を返す() {
        var state = TimerState()
        state.start(now: t0)
        let completion = state.tick(now: t0.addingTimeInterval(25 * 60 + 5))
        #expect(completion == TimerCompletion(mode: .focus, sessionStartDate: t0, duration: 25 * 60))
        #expect(!state.isRunning)
        #expect(state.timeRemaining == 0)
        #expect(state.sessionStartDate == nil)
        #expect(state.isCompleted)
    }

    @Test func 完了は一度だけ返る() {
        var state = TimerState()
        state.start(now: t0)
        #expect(state.tick(now: t0.addingTimeInterval(25 * 60)) != nil)
        #expect(state.tick(now: t0.addingTimeInterval(25 * 60 + 1)) == nil)
    }

    @Test func 一時停止を挟んでも完了時の時間は設定時間になる() {
        var state = TimerState()
        state.start(now: t0)
        state.pause(now: t0.addingTimeInterval(300))
        state.start(now: t0.addingTimeInterval(600))
        let completion = state.tick(now: t0.addingTimeInterval(600 + 25 * 60))
        #expect(completion == TimerCompletion(mode: .focus, sessionStartDate: t0, duration: 25 * 60))
    }

    @Test func 完了後の次のモードは集中と休憩が交互になる() {
        #expect(TimerMode.focus.next == .shortBreak)
        #expect(TimerMode.shortBreak.next == .focus)
    }

    // MARK: - リセット・モード切替

    @Test func リセットすると設定時間に戻りセッションも破棄される() {
        var state = TimerState()
        state.start(now: t0)
        state.reset()
        #expect(!state.isRunning)
        #expect(state.timeRemaining == 25 * 60)
        #expect(state.sessionStartDate == nil)
    }

    @Test func モード切替で時間が切り替わり停止する() {
        var state = TimerState()
        state.start(now: t0)
        state.switchMode(to: .shortBreak)
        #expect(state.mode == .shortBreak)
        #expect(state.totalTime == 5 * 60)
        #expect(state.timeRemaining == 5 * 60)
        #expect(!state.isRunning)
        #expect(state.sessionStartDate == nil)
    }

    // MARK: - 表示

    @Test func 残り時間の表示は秒を切り上げる() {
        var state = TimerState()
        state.start(now: t0)
        _ = state.tick(now: t0.addingTimeInterval(0.25))
        #expect(state.timeString == "25:00")
        _ = state.tick(now: t0.addingTimeInterval(1))
        #expect(state.timeString == "24:59")
    }

    @Test func 進捗は残り時間の割合() {
        var state = TimerState()
        state.start(now: t0)
        _ = state.tick(now: t0.addingTimeInterval(15 * 60))
        #expect(abs(state.progress - 0.4) < 0.0001)
    }

    // MARK: - Watch 同期

    @Test func 実行中の状態を受信すると送信からの経過分を差し引く() {
        var state = TimerState()
        state.apply(remote(running: true, remaining: 600, reference: t0, sessionStart: t0), now: t0.addingTimeInterval(2))
        #expect(state.isRunning)
        #expect(state.timeRemaining == 598)
        #expect(state.endDate == t0.addingTimeInterval(600))
        #expect(state.sessionStartDate == t0)
    }

    @Test func 受信時点で既に終わっていれば残り0で停止する() {
        var state = TimerState()
        state.apply(remote(running: true, remaining: 10, reference: t0), now: t0.addingTimeInterval(30))
        #expect(!state.isRunning)
        #expect(state.timeRemaining == 0)
    }

    @Test func 停止中の状態はそのまま反映する() {
        var state = TimerState()
        state.apply(remote(running: false, remaining: 123, reference: t0, mode: .shortBreak), now: t0.addingTimeInterval(500))
        #expect(state.mode == .shortBreak)
        #expect(state.totalTime == 5 * 60)
        #expect(!state.isRunning)
        #expect(state.timeRemaining == 123)
    }

    // MARK: - Helpers

    private func remote(
        running: Bool,
        remaining: TimeInterval,
        reference: Date,
        sessionStart: Date? = nil,
        mode: TimerMode = .focus
    ) -> TimerSyncState {
        TimerSyncState(
            timerModeRawValue: mode.rawValue,
            totalTime: mode.duration,
            timeRemaining: remaining,
            isTimerRunning: running,
            sessionStartTimestamp: sessionStart?.timeIntervalSince1970,
            referenceTimestamp: reference.timeIntervalSince1970
        )
    }
}
