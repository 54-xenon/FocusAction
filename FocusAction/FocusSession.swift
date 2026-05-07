//
//  FocusSession.swift
//  FocusAction
//
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    /// セッションの一意識別子
    var id: UUID
    
    /// 集中を開始した日時
    var startDate: Date
    
    /// 集中した時間（秒単位）- 計算プロパティでも良いが、明示的に保存
    var duration: TimeInterval
    
    /// セッションのタイプ（集中 or 休憩）- rawValueで保存
    var sessionTypeRawValue: String
    
    /// セッションのタイプ（計算プロパティ）
    var sessionType: SessionType {
        get {
            SessionType(rawValue: sessionTypeRawValue) ?? .focus
        }
        set {
            sessionTypeRawValue = newValue.rawValue
        }
    }
    
    /// タグのリスト（複数設定可能）
    var tags: [String]
    
    /// セッションが完了したかどうか（途中でキャンセルされた場合はfalse）
    var isCompleted: Bool
    
    /// 作成日時（ソート用）
    var createdAt: Date
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        duration: TimeInterval,
        sessionType: SessionType = .focus,
        tags: [String] = [],
        isCompleted: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.duration = duration
        self.sessionTypeRawValue = sessionType.rawValue
        self.tags = tags
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// 集中した時間を分単位で取得
    var durationInMinutes: Int {
        Int(duration / 60)
    }
    
    /// 集中した時間を時間と分で取得（例: "1時間25分"）
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    
    /// 日付を "yyyy年MM月dd日" 形式で取得
    var formattedDateLong: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: startDate)
    }
    
    /// 時刻を "HH:mm" 形式で取得
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startDate)
    }
    
    /// 開始時刻と終了時刻を "HH:mm - HH:mm" 形式で取得
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let endDate = startDate.addingTimeInterval(duration)
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Session Type Enum

enum SessionType: String, Codable, CaseIterable {
    case focus = "集中"
    case shortBreak = "休憩"
    
    var color: String {
        switch self {
        case .focus: return "blue"
        case .shortBreak: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Helper Extensions

extension FocusSession {
    /// 特定のタグでフィルタリングするための静的メソッド
    static func predicate(for tag: String) -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.tags.contains(tag)
        }
    }
    
    /// 特定の日付範囲でフィルタリングするための静的メソッド
    static func predicate(from startDate: Date, to endDate: Date) -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }
    
    /// 完了したセッションのみを取得するための静的メソッド
    static func completedSessionsPredicate() -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.isCompleted == true
        }
    }

    /// 集中セッションのみを取得するための静的メソッド
    static func focusSessionsPredicate() -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.sessionTypeRawValue == "集中"
        }
    }
    
    /// 特定のセッションタイプでフィルタリングするための静的メソッド
    static func predicate(for sessionType: SessionType) -> Predicate<FocusSession> {
        let rawValue = sessionType.rawValue
        return #Predicate<FocusSession> { session in
            session.sessionTypeRawValue == rawValue
        }
    }
}


