//
//  TimerSyncManager.swift
//  FocusAction
//
//  iOS と Watch App の両方の Target に追加してください（TimerMode.swift と同様）
//
//  iPhone側で実行中のタイマー状態を WatchConnectivity 経由で Watch に伝える。
//  履歴データ(FocusSession)の同期は対象外（CloudKit側で別途対応）。
//

import Foundation
import WatchConnectivity

// MARK: - 送受信する状態のスナップショット

nonisolated struct TimerSyncState {
    let timerModeRawValue: String
    let totalTime: TimeInterval
    let timeRemaining: TimeInterval
    let isTimerRunning: Bool
    let sessionStartTimestamp: TimeInterval?
    /// このスナップショットを作成した時刻（受信側で経過時間を補正するために使う）
    let referenceTimestamp: TimeInterval

    var timerMode: TimerMode { TimerMode(rawValue: timerModeRawValue) ?? .focus }
    var sessionStartDate: Date? { sessionStartTimestamp.map(Date.init(timeIntervalSince1970:)) }
    var referenceDate: Date { Date(timeIntervalSince1970: referenceTimestamp) }

    init(
        timerModeRawValue: String,
        totalTime: TimeInterval,
        timeRemaining: TimeInterval,
        isTimerRunning: Bool,
        sessionStartTimestamp: TimeInterval?,
        referenceTimestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.timerModeRawValue = timerModeRawValue
        self.totalTime = totalTime
        self.timeRemaining = timeRemaining
        self.isTimerRunning = isTimerRunning
        self.sessionStartTimestamp = sessionStartTimestamp
        self.referenceTimestamp = referenceTimestamp
    }

    init?(dictionary: [String: Any]) {
        guard
            let timerModeRawValue = dictionary["timerMode"] as? String,
            let totalTime = dictionary["totalTime"] as? TimeInterval,
            let timeRemaining = dictionary["timeRemaining"] as? TimeInterval,
            let isTimerRunning = dictionary["isTimerRunning"] as? Bool,
            let referenceTimestamp = dictionary["referenceTimestamp"] as? TimeInterval
        else { return nil }

        self.timerModeRawValue = timerModeRawValue
        self.totalTime = totalTime
        self.timeRemaining = timeRemaining
        self.isTimerRunning = isTimerRunning
        self.sessionStartTimestamp = dictionary["sessionStartTimestamp"] as? TimeInterval
        self.referenceTimestamp = referenceTimestamp
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "timerMode": timerModeRawValue,
            "totalTime": totalTime,
            "timeRemaining": timeRemaining,
            "isTimerRunning": isTimerRunning,
            "referenceTimestamp": referenceTimestamp
        ]
        if let sessionStartTimestamp {
            dict["sessionStartTimestamp"] = sessionStartTimestamp
        }
        return dict
    }
}

// MARK: - WatchConnectivity ラッパー

@MainActor
final class TimerSyncManager: NSObject {
    static let shared = TimerSyncManager()

    private weak var viewModel: TimerViewModel?
    private let session: WCSession? = WCSession.isSupported() ? .default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    /// TimerViewModel の初期化時に呼び出す。watchOS 側では現在アプリを起動した瞬間に
    /// 直近の状態を反映するため、保持済みの applicationContext を即座に適用する。
    func start(with viewModel: TimerViewModel) {
        self.viewModel = viewModel
        #if os(watchOS)
        applyLatestContextIfAvailable()
        #endif
    }

    #if os(watchOS)
    private func applyLatestContextIfAvailable() {
        guard let session, let state = TimerSyncState(dictionary: session.receivedApplicationContext) else { return }
        #if DEBUG
        print("[TimerSync] Watchで直近の状態を適用: mode=\(state.timerModeRawValue) running=\(state.isTimerRunning) remaining=\(state.timeRemaining)")
        #endif
        viewModel?.applyRemoteState(state)
    }
    #endif

    #if os(iOS)
    /// タイマーの状態が変化するたびに呼び出す。updateApplicationContext は最新の内容で
    /// 上書きされるため、毎秒ではなく開始/一時停止/リセット/モード切替時のみ呼べば十分。
    func sendState(_ viewModel: TimerViewModel) {
        guard let session, session.isPaired, session.isWatchAppInstalled else { return }
        let state = TimerSyncState(
            timerModeRawValue: viewModel.timerMode.rawValue,
            totalTime: viewModel.totalTime,
            timeRemaining: viewModel.timeRemaining,
            isTimerRunning: viewModel.isTimerRunning,
            sessionStartTimestamp: viewModel.sessionStartDate?.timeIntervalSince1970
        )
        do {
            try session.updateApplicationContext(state.dictionary)
            #if DEBUG
            print("[TimerSync] Watchへ状態送信: mode=\(state.timerModeRawValue) running=\(state.isTimerRunning) remaining=\(state.timeRemaining)")
            #endif
        } catch {
            #if DEBUG
            print("Watchへのタイマー状態送信に失敗しました: \(error.localizedDescription)")
            #endif
        }
    }
    #endif
}

extension TimerSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if os(watchOS)
        Task { @MainActor in
            applyLatestContextIfAvailable()
        }
        #endif
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    #if os(watchOS)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let state = TimerSyncState(dictionary: applicationContext) else { return }
        #if DEBUG
        print("[TimerSync] Watchで新しい状態を受信: mode=\(state.timerModeRawValue) running=\(state.isTimerRunning) remaining=\(state.timeRemaining)")
        #endif
        Task { @MainActor in
            viewModel?.applyRemoteState(state)
        }
    }
    #endif
}
