//
//  TimerStore.swift
//  FocusAction
//
//  アプリ全体で1つだけ持つタイマーの状態。App で生成して .environment で配る。iOS/watchOS共通
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class TimerStore {
    /// タイマーの状態と進行ロジック本体（副作用なし）
    private(set) var state = TimerState()
    // タイマー完了時にインクリメント（Watch 側の触覚フィードバック用）
    private(set) var completionCount = 0
    // iOSでは円の中のタグ選択、watchOSではタグ一覧で選んだタグ
    var selectedTag: Tag? {
        didSet { send(.tagChanged) }
    }

    /// 通知・Live Activity・Watch同期・Widget などの副作用。iOS では TimerEventHandlers.live() を注入する。
    @ObservationIgnored private let eventHandlers: [any TimerEventHandler]
    @ObservationIgnored private let modelContext: ModelContext?
    @ObservationIgnored private let isFromWatch: Bool
    @ObservationIgnored private let now: () -> Date

    @ObservationIgnored private var tickTask: Task<Void, Never>?

    /// - Parameters:
    ///   - modelContext: 完了したセッションの保存先（nil なら保存しない）
    ///   - eventHandlers: 状態の変化を受け取る副作用の一覧
    ///   - isFromWatch: 保存するセッションを Watch で記録したものとして扱うか
    ///   - now: 現在時刻（テストで差し替える）
    init(
        modelContext: ModelContext? = nil,
        eventHandlers: [any TimerEventHandler] = [],
        isFromWatch: Bool = false,
        now: @escaping () -> Date = Date.init
    ) {
        self.modelContext = modelContext
        self.eventHandlers = eventHandlers
        self.isFromWatch = isFromWatch
        self.now = now
    }

    // MARK: - Computed Properties

    var isTimerRunning: Bool { state.isRunning }
    var timeRemaining: TimeInterval { state.timeRemaining }
    var totalTime: TimeInterval { state.totalTime }
    var timerMode: TimerMode { state.mode }
    var sessionStartDate: Date? { state.sessionStartDate }
    var progress: CGFloat { CGFloat(state.progress) }
    var timeString: String { state.timeString }
    var isCompleted: Bool { state.isCompleted }

    // MARK: - Timer Control

    func toggleTimer() {
        if state.isRunning {
            withAnimation(.spring(response: 0.3)) {
                state.pause(now: now())
            }
            stopTicking()
            send(.paused)
        } else {
            withAnimation(.spring(response: 0.3)) {
                _ = state.start(now: now())
            }
            guard state.isRunning else { return }
            startTicking()
            send(.started)
        }
    }

    func resetTimer() {
        withAnimation {
            stopTicking()
            state.reset()
        }
        send(.reset)
    }

    func switchMode(to mode: TimerMode, animated: Bool = true) {
        guard mode != timerMode else { return }
        stopTicking()

        if animated {
            withAnimation { state.switchMode(to: mode) }
        } else {
            state.switchMode(to: mode)
        }
        send(.modeSwitched)
    }

    // MARK: - Scene Phase (iOS / watchOS 共通)

    func handleScenePhaseChange(_ phase: ScenePhase) {
        // 残り時間は endDate から求めるので、バックグラウンド移行時に記録しておくものはない。
        // 復帰時に表示をすぐ最新にし、バックグラウンド中に終了していれば完了処理を行う。
        guard phase == .active, isTimerRunning else { return }
        tick()
    }

    // MARK: - Watch Sync

    /// iPhone から WatchConnectivity 経由で届いた最新のタイマー状態を反映する。
    func applyRemoteState(_ remote: TimerSyncState) {
        stopTicking()
        state.apply(remote, now: now())
        if state.isRunning {
            startTicking()
        }
    }

    // MARK: - Private

    private func send(_ event: TimerEvent) {
        let context = TimerEventContext(state: state, tag: selectedTag, modelContext: modelContext)
        for handler in eventHandlers {
            handler.handle(event, context: context)
        }
    }

    // 表示の秒の切り替わりが遅れないよう、1秒より細かい間隔で残り時間を更新する
    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                self?.tick()
            }
        }
    }

    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func tick() {
        guard let completion = state.tick(now: now()) else { return }
        timerCompleted(completion)
    }

    private func timerCompleted(_ completion: TimerCompletion) {
        stopTicking()
        completionCount += 1
        send(.completed(completion))
        saveSession(completion)
        switchMode(to: completion.mode.next, animated: false)
    }

    private func saveSession(_ completion: TimerCompletion) {
        guard let modelContext, let startDate = completion.sessionStartDate else { return }
        let session = FocusSession(
            startDate: startDate,
            duration: completion.duration,
            sessionType: completion.mode == .focus ? .focus : .shortBreak,
            tag: selectedTag,
            isFromWatch: isFromWatch,
            isCompleted: true
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
            send(.sessionSaved)
            #if DEBUG
            print("セッションを保存しました: \(session.formattedDuration)")
            #endif
        } catch {
            #if DEBUG
            print("セッション保存エラー: \(error.localizedDescription)")
            #endif
        }
    }
}
