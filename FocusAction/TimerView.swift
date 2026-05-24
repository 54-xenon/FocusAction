//
//  ContentView.swift
//  FocusAction
//
//

// 必要なパッケージをあらかじめインポート
import SwiftUI
import Combine
import SwiftData

struct TimerView: View {

    // SwiftDataのモデルコンテキストを取得
    @Environment(\.modelContext) private var modelContext
    
    // State関数 -> Viewに対して状態をもたせる(UIに動きをつけることができる)
    @State private var isTimerRunning = false   // タイマーが動いているかどうか(bool: false -> 動いていない)
    @State private var timeRemaining: TimeInterval = 25 * 60 // 25分(残り時間)
    @State private var totalTime: TimeInterval = 25 * 60 // 総時間
    @State private var timerMode: TimerMode = .focus    // 現在のモード
    @State private var sessionStartDate: Date? = nil // セッション開始時刻を記録
    
    // 通知とバックグラウンド管理
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var backgroundManager = BackgroundTimerManager()
    
    // CombineフレームワークのTimer.publishを使用(使えるようにインスタンス化)
        // -> 1秒ごとにイベントを発行、自動的に接続(タイマーは1秒ごとに進み、その都度状態を更新する必要があるため)
        // everyプロパティを1にすることで、1秒おきに設定している
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UI部分 -> デバイスタイプに応じて適切なUIを表示
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad用UI
                TimerViewIPad(
                    isTimerRunning: $isTimerRunning,
                    timeRemaining: $timeRemaining,
                    timerMode: $timerMode,
                    progress: progress,
                    timeString: timeString,
                    statusText: statusText,
                    onToggleTimer: toggleTimer,
                    onResetTimer: resetTimer,
                    onSwitchMode: { mode in switchMode(to: mode, animated: true) }
                )
            } else {
                // iPhone用UI
                TimerViewIPhone(
                    isTimerRunning: $isTimerRunning,
                    timeRemaining: $timeRemaining,
                    timerMode: $timerMode,
                    progress: progress,
                    timeString: timeString,
                    statusText: statusText,
                    onToggleTimer: toggleTimer,
                    onResetTimer: resetTimer,
                    onSwitchMode: { mode in switchMode(to: mode, animated: true) }
                )
            }
        }
        // タイマー処理で、1秒ずず値を減らしている
        .onReceive(timer) { _ in
            // 0以上の値の時 -> 残り時間がある間はデクリメントメソッドを繰り返し行う
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if isTimerRunning && timeRemaining <= 0 {
                // 残り時間がゼロになるとタイマーを止める
                timerCompleted()
            }
        }
        // バックグラウンドから戻った時の処理
        .onReceive(NotificationCenter.default.publisher(for: .timerShouldUpdate)) { notification in
            handleBackgroundReturn(notification: notification)
        }
        // 表示時に通知権限をリクエスト
        .task {
            if !notificationManager.isAuthorized {
                await notificationManager.requestAuthorization()
            }
            // バッジをクリア
            notificationManager.clearBadge()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining / totalTime)
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var statusText: String {
        if isTimerRunning {
            return timerMode == .focus ? "集中..." : "休憩中..."
        } else if timeRemaining <= 0 {
            return "完了！"
        } else {
            return "タップして開始"
        }
    }
    
    // MARK: - Timer Functions
    
    private func toggleTimer() {
        withAnimation(.spring(response: 0.3)) {
            isTimerRunning.toggle()
            
            // タイマー開始時に開始時刻を記録
            if isTimerRunning && sessionStartDate == nil {
                sessionStartDate = Date()
                
                // 通知をスケジュール
                notificationManager.scheduleTimerCompletionNotification(
                    for: timerMode,
                    in: timeRemaining
                )
            } else if !isTimerRunning {
                // タイマー停止時は通知をキャンセル
                notificationManager.cancelAllNotifications()
            }
        }
    }
    
    private func resetTimer() {
        withAnimation {
            isTimerRunning = false
            timeRemaining = totalTime
            sessionStartDate = nil // 開始時刻もリセット
            
            // 通知をキャンセル
            notificationManager.cancelAllNotifications()
        }
    }
    
    private func switchMode(to mode: TimerMode, animated: Bool = true) {
        print("switchMode呼び出し: \(timerMode.rawValue) → \(mode.rawValue)")
        
        guard mode != timerMode else {
            return
        }
        
        // 通知をキャンセル
        notificationManager.cancelAllNotifications()
        
        // アニメーションの有無を制御
        let changes = {
            self.timerMode = mode
            self.totalTime = mode.duration
            self.timeRemaining = mode.duration
            self.isTimerRunning = false
            self.sessionStartDate = nil
        }
        
        if animated {
            withAnimation {
                changes()
            }
        } else {
            changes()
        }
        
    }
    
    private func timerCompleted() {
        print("timerCompleted() 開始: モード = \(timerMode.rawValue), timeRemaining = \(timeRemaining)")
        
        // タイマーを停止
        isTimerRunning = false
        
        // 通知をキャンセル
        notificationManager.cancelAllNotifications()
        
        // セッションを保存
        saveSession(isCompleted: true)
        
        // 次のモードを決定
        let nextMode: TimerMode = (timerMode == .focus) ? .shortBreak : .focus
        
        // モード切り替え（アニメーションなしで即座に実行）
        DispatchQueue.main.async {
            self.switchMode(to: nextMode, animated: false)
        }
    }
    
    /// バックグラウンドから戻った時の処理
    private func handleBackgroundReturn(notification: Notification) {
        guard let elapsed = notification.userInfo?["elapsed"] as? TimeInterval,
              isTimerRunning else {
            return
        }
        
        // 経過時間分をタイマーから減算
        timeRemaining = max(0, timeRemaining - elapsed)
        
        // タイマーが完了していたらイベントを発火
        if timeRemaining <= 0 {
            timerCompleted()
        } else {
            // 残り時間で通知を再スケジュール
            notificationManager.scheduleTimerCompletionNotification(
                for: timerMode,
                in: timeRemaining
            )
        }
    }
    
    // MARK: - Data Persistence
    
    /// セッションをSwiftDataに保存する
    private func saveSession(isCompleted: Bool) {
        guard let startDate = sessionStartDate else {
            return
        }
        
        // 実際に経過した時間を計算
        let elapsedTime = totalTime - timeRemaining
        
        
        // FocusSessionを作成
        let session = FocusSession(
            startDate: startDate,
            duration: elapsedTime,
            sessionType: timerMode == .focus ? .focus : .shortBreak,
            tags: [], // 必要に応じてタグを追加できる
            isCompleted: isCompleted
        )
        
        // モデルコンテキストに追加
        modelContext.insert(session)
        
        // 保存を試行
        do {
            try modelContext.save()
            print("セッションを保存しました: \(session.formattedDuration)")
        } catch {
            print("セッション保存エラー: \(error.localizedDescription)")
        }
        
        // 開始時刻をリセット
        sessionStartDate = nil
    }
}

#Preview {
    TimerView()
}
