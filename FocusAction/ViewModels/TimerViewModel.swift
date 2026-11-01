//
//  TimerViewModel.swift
//  FocusAction
//
//



import SwiftUI
import Combine
import SwiftData

@MainActor
final class TimerViewModel: ObservableObject {
    /// タイマーの状態と進行ロジック本体（副作用なし）。ここでは通知や同期などの副作用だけを扱う。
    @Published private(set) var state = TimerState()
    // タイマー完了時にインクリメント（Watch 側の触覚フィードバック用）
    @Published var completionCount = 0
    // タイマー開始前にiOS側で選択されたタグ（watchOSでは常にnil）
    @Published var selectedTag: Tag? {
        didSet {
            #if os(iOS)
            WidgetDataWriter.updateTimer(with: self)
            #endif
        }
    }

    var modelContext: ModelContext?

    private var timerCancellable: AnyCancellable?
    // 表示の秒の切り替わりが遅れないよう、1秒より細かい間隔で残り時間を更新する
    private let timerPublisher = Timer.publish(every: 0.25, on: .main, in: .common)

    #if os(iOS)
    let notificationManager = NotificationManager.shared
    let liveActivityManager = LiveActivityManager.shared
    #endif

    init() {
        TimerSyncManager.shared.start(with: self)
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
        let now = Date()
        if state.isRunning {
            withAnimation(.spring(response: 0.3)) {
                state.pause(now: now)
            }
            stopTimerSubscription()
            #if os(iOS)
            notificationManager.cancelAllNotifications()
            #endif
        } else {
            var isNewSession = false
            withAnimation(.spring(response: 0.3)) {
                isNewSession = state.start(now: now)
            }
            guard state.isRunning else { return }
            startTimerSubscription()
            #if os(iOS)
            if isNewSession {
                notificationManager.scheduleTimerCompletionNotification(for: timerMode, in: timeRemaining)
            }
            #endif
        }
        #if os(iOS)
        liveActivityManager.update(with: self)
        TimerSyncManager.shared.sendState(self)
        WidgetDataWriter.updateTimer(with: self)
        #endif
    }

    func resetTimer() {
        withAnimation {
            stopTimerSubscription()
            state.reset()
        }
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        liveActivityManager.end()
        TimerSyncManager.shared.sendState(self)
        WidgetDataWriter.updateTimer(with: self)
        #endif
    }

    func switchMode(to mode: TimerMode, animated: Bool = true) {
        guard mode != timerMode else { return }
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        liveActivityManager.end()
        #endif
        stopTimerSubscription()

        if animated {
            withAnimation { state.switchMode(to: mode) }
        } else {
            state.switchMode(to: mode)
        }
        #if os(iOS)
        TimerSyncManager.shared.sendState(self)
        WidgetDataWriter.updateTimer(with: self)
        #endif
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
        stopTimerSubscription()
        state.apply(remote, now: Date())
        if state.isRunning {
            startTimerSubscription()
        }
    }

    // MARK: - Private

    private func startTimerSubscription() {
        timerCancellable = timerPublisher
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimerSubscription() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard let completion = state.tick(now: Date()) else { return }
        timerCompleted(completion)
    }

    private func timerCompleted(_ completion: TimerCompletion) {
        stopTimerSubscription()
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        #endif
        completionCount += 1
        saveSession(completion)
        switchMode(to: completion.mode.next, animated: false)
    }

    private func saveSession(_ completion: TimerCompletion) {
        guard let modelContext, let startDate = completion.sessionStartDate else { return }
        #if os(watchOS)
        let isFromWatch = true
        #else
        let isFromWatch = false
        #endif
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
            #if os(iOS)
            WidgetDataWriter.updateHistory(using: modelContext)
            #endif
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
