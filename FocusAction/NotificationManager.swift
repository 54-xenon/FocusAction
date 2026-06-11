//
//  NotificationManager.swift
//  FocusAction
//

import Foundation
import UserNotifications
import Combine

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

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            #if DEBUG
            print(granted ? "通知の権限が許可されました" : "通知の権限が拒否されました")
            #endif
            return granted
        } catch {
            #if DEBUG
            print("通知権限リクエストエラー: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Notifications

    func scheduleTimerCompletionNotification(for mode: TimerMode, in timeInterval: TimeInterval) {
        cancelAllNotifications()

        let content = UNMutableNotificationContent()
        content.title = mode == .focus ? "🎉 集中タイム完了！" : "☕️ 休憩タイム完了！"
        content.body = mode == .focus
            ? "お疲れ様でした！休憩しましょう。"
            : "休憩完了！次の集中タイムを始めましょう。"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "timerCompletion", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                print("通知をスケジュールしました: \(timeInterval)秒後")
            }
            #endif
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #if DEBUG
        print("全ての通知をキャンセルしました")
        #endif
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Test Notification

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 テスト通知"
        content.body = "通知が正常に動作しています！"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("テスト通知エラー: \(error.localizedDescription)")
            } else {
                print("テスト通知を送信しました（5秒後）")
            }
            #endif
        }
    }
}
