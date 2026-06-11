//
//  TimerViewModel.swift
//  FocusAction
//
//  iOS と Watch App の両方の Target に追加してください（TimerMode.swift と同様）
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

    var modelContext: ModelContext?

    private var sessionStartDate: Date?
    private var backgroundDate: Date?
    private var timerCancellable: AnyCancellable?
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common)

    #if os(iOS)
    let notificationManager = NotificationManager.shared
    #endif

    init() {
        totalTime = TimerMode.focus.duration
        timeRemaining = TimerMode.focus.duration
    }

    // MARK: - Computed Properties

    var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining / totalTime)
    }

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var statusText: String {
        if isTimerRunning { return timerMode == .focus ? "集中..." : "休憩中..." }
        if timeRemaining <= 0 { return "完了！" }
        return "タップして開始"
    }

    // MARK: - Timer Control

    func toggleTimer() {
        withAnimation(.spring(response: 0.3)) {
            isTimerRunning.toggle()
        }

        if isTimerRunning {
            startTimerSubscription()
            if sessionStartDate == nil {
                sessionStartDate = Date()
                #if os(iOS)
                notificationManager.scheduleTimerCompletionNotification(for: timerMode, in: timeRemaining)
                #endif
            }
        } else {
            stopTimerSubscription()
            #if os(iOS)
            notificationManager.cancelAllNotifications()
            #endif
        }
    }

    func resetTimer() {
        withAnimation {
            stopTimerSubscription()
            isTimerRunning = false
            timeRemaining = totalTime
            sessionStartDate = nil
        }
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        #endif
    }

    func switchMode(to mode: TimerMode, animated: Bool = true) {
        guard mode != timerMode else { return }
        #if os(iOS)
        notificationManager.cancelAllNotifications()
        #endif
        stopTimerSubscription()

        let changes = {
            self.timerMode = mode
            self.totalTime = mode.duration
            self.timeRemaining = mode.duration
            self.isTimerRunning = false
            self.sessionStartDate = nil
        }

        if animated {
            withAnimation { changes() }
        } else {
            changes()
        }
    }

    // MARK: - Scene Phase (iOS / watchOS 共通)

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            if isTimerRunning { backgroundDate = Date() }
        case .active:
            guard let bgDate = backgroundDate else { return }
            backgroundDate = nil
            let elapsed = Date().timeIntervalSince(bgDate)
            timeRemaining = max(0, timeRemaining - elapsed)
            if timeRemaining <= 0 {
                timerCompleted()
            } else if isTimerRunning {
                #if os(iOS)
                notificationManager.scheduleTimerCompletionNotification(for: timerMode, in: timeRemaining)
                #endif
            }
        @unknown default:
            break
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
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            timerCompleted()
        }
    }

    private func timerCompleted() {
        stopTimerSubscription()
        isTimerRunning = false
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
        let tags = ["Watch"]
        #else
        let tags: [String] = []
        #endif
        let session = FocusSession(
            startDate: startDate,
            duration: elapsed,
            sessionType: timerMode == .focus ? .focus : .shortBreak,
            tags: tags,
            isCompleted: isCompleted
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
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
