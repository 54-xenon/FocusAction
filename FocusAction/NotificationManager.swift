//
//  NotificationManager.swift
//  FocusAction
//
//

import Foundation
import UserNotifications
import Combine

/// 通知を管理するクラス
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        Task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Authorization
    
    /// 通知の権限をリクエスト
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            
            isAuthorized = granted
            
            if granted {
                print("通知の権限が許可されました")
            } else {
                print("通知の権限が拒否されました")
            }
            
            return granted
        } catch {
            print("通知権限リクエストエラー: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 現在の権限状態を確認
    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Schedule Notifications
    
    /// タイマー完了通知をスケジュール
    func scheduleTimerCompletionNotification(for mode: TimerMode, in timeInterval: TimeInterval) {
        // 既存の通知をキャンセル
        cancelAllNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = mode == .focus ? "🎉 集中タイム完了！" : "☕️ 休憩タイム完了！"
        content.body = mode == .focus 
            ? "お疲れ様でした！休憩しましょう。" 
            : "休憩完了！次の集中タイムを始めましょう。"
        content.sound = .default
        content.badge = 1
        
        // トリガーを作成（指定秒数後）
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // リクエストを作成
        let request = UNNotificationRequest(
            identifier: "timerCompletion",
            content: content,
            trigger: trigger
        )
        
        // 通知をスケジュール
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                print("通知をスケジュールしました: \(timeInterval)秒後")
            }
        }
    }
    
    /// 全ての通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("全ての通知をキャンセルしました")
    }
    
    /// バッジをクリア
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Test Notification
    
    /// テスト通知を送信（5秒後）
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 テスト通知"
        content.body = "通知が正常に動作しています！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "testNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("テスト通知エラー: \(error.localizedDescription)")
            } else {
                print("テスト通知を送信しました（5秒後）")
            }
        }
    }
}
