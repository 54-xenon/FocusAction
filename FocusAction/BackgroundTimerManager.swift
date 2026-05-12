//
//  BackgroundTimerManager.swift
//  FocusAction
//
//

import Foundation
import UIKit
import Combine

/// バックグラウンドでのタイマー管理を行うクラス
@MainActor
class BackgroundTimerManager: ObservableObject {
    @Published var backgroundDate: Date?
    
    private var notificationObservers: [NSObjectProtocol] = []
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // アプリがバックグラウンドに入る時
        let willResignActive = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.didEnterBackground()
            }
        }
        
        // アプリがフォアグラウンドに戻る時
        let didBecomeActive = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.didEnterForeground()
            }
        }
        
        notificationObservers = [willResignActive, didBecomeActive]
    }
    
    private func removeObservers() {
        Task { @MainActor in
            notificationObservers.forEach { observer in
                NotificationCenter.default.removeObserver(observer)
            }
            notificationObservers.removeAll()
        }
    }
    
    // MARK: - Background Handling
    
    /// バックグラウンドに入った時刻を記録
    private func didEnterBackground() {
        backgroundDate = Date()
        print("📱 バックグラウンドに入りました: \(backgroundDate!)")
    }
    
    /// フォアグラウンドに戻った時の経過時間を計算
    private func didEnterForeground() {
        guard let backgroundDate = backgroundDate else { return }
        
        let elapsed = Date().timeIntervalSince(backgroundDate)
        print("📱 フォアグラウンドに戻りました。経過時間: \(Int(elapsed))秒")
        
        // 経過時間を通知（Viewで受け取る）
        NotificationCenter.default.post(
            name: .timerShouldUpdate,
            object: nil,
            userInfo: ["elapsed": elapsed]
        )
        
        self.backgroundDate = nil
    }
    
    /// 経過時間を取得
    func getElapsedTime() -> TimeInterval {
        guard let backgroundDate = backgroundDate else { return 0 }
        return Date().timeIntervalSince(backgroundDate)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let timerShouldUpdate = Notification.Name("timerShouldUpdate")
}
