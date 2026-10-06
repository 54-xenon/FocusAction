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
    @Published var isTimerRunning = false
    @Published var timeRemaining: TimeInterval
    @Published var totalTime: TimeInterval
    @Published var timerMode: TimerMode = .focus
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

    private(set) var sessionStartDate: Date?
    /// 実行中のタイマーが終了する時刻。残り時間は毎回「endDate − 現在時刻」で求めるため、
    /// バックグラウンド中にTimerが止まっても復帰時に正しい残り時間になる。
    private var endDate: Date?
    private var timerCancellable: AnyCancellable?
    // 表示の秒の切り替わりが遅れないよう、1秒より細かい間隔で残り時間を更新する
    private let timerPublisher = Timer.publish(every: 0.25, on: .main, in: .common)

    #if os(iOS)
    let notificationManager = NotificationManager.shared
    let liveActivityManager = LiveActivityManager.shared
    #endif

    init() {
        totalTime = TimerMode.focus.duration
        timeRemaining = TimerMode.focus.duration
        TimerSyncManager.shared.start(with: self)
    }

    // MARK: - Computed Properties

    var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining / totalTime)
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
        !isTimerRunning && timeRemaining <= 0
    }

    // MARK: - Timer Control

    func toggleTimer() {
        withAnimation(.spring(response: 0.3)) {
            isTimerRunning.toggle()
        }

        if isTimerRunning {
            endDate = Date().addingTimeInterval(timeRemaining)
            startTimerSubscription()
            if sessionStartDate == nil {
                sessionStartDate = Date()
                #if os(iOS)
                notificationManager.scheduleTimerCompletionNotification(for: timerMode, in: timeRemaining)
                #endif
            }
        } else {
            updateTimeRemaining()
            endDate = nil
            stopTimerSubscription()
            #if os(iOS)
            notificationManager.cancelAllNotifications()
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
            isTimerRunning = false
            timeRemaining = totalTime
            endDate = nil
            sessionStartDate = nil
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

        let changes = {
            self.timerMode = mode
            self.totalTime = mode.duration
            self.timeRemaining = mode.duration
            self.isTimerRunning = false
            self.endDate = nil
            self.sessionStartDate = nil
        }

        if animated {
            withAnimation { changes() }
        } else {
            changes()
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
    func applyRemoteState(_ state: TimerSyncState) {
        stopTimerSubscription()

        timerMode = state.timerMode
        totalTime = state.totalTime
        sessionStartDate = state.sessionStartDate

        if state.isTimerRunning {
            let elapsedSinceReference = Date().timeIntervalSince(state.referenceDate)
            let adjustedRemaining = max(0, state.timeRemaining - elapsedSinceReference)
            if adjustedRemaining <= 0 {
                isTimerRunning = false
                timeRemaining = 0
                endDate = nil
            } else {
                timeRemaining = adjustedRemaining
                endDate = state.referenceDate.addingTimeInterval(state.timeRemaining)
                isTimerRunning = true
                startTimerSubscription()
            }
        } else {
            isTimerRunning = false
            timeRemaining = state.timeRemaining
            endDate = nil
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
        updateTimeRemaining()
        if timeRemaining <= 0 {
            timerCompleted()
        }
    }

    private func updateTimeRemaining() {
        guard let endDate else { return }
        timeRemaining = max(0, endDate.timeIntervalSinceNow)
    }

    private func timerCompleted() {
        stopTimerSubscription()
        isTimerRunning = false
        endDate = nil
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        #endif
        completionCount += 1
        saveSession(isCompleted: true)
        let nextMode: TimerMode = timerMode == .focus ? .shortBreak : .focus
        switchMode(to: nextMode, animated: false)
    }

    private func saveSession(isCompleted: Bool) {
        guard let modelContext, let startDate = sessionStartDate else { return }
        let elapsed = totalTime - timeRemaining
        #if os(watchOS)
        let isFromWatch = true
        #else
        let isFromWatch = false
        #endif
        let session = FocusSession(
            startDate: startDate,
            duration: elapsed,
            sessionType: timerMode == .focus ? .focus : .shortBreak,
            tag: selectedTag,
            isFromWatch: isFromWatch,
            isCompleted: isCompleted
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
        sessionStartDate = nil
    }
}
