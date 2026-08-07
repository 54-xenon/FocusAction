//
//  FocusSession.swift
//  FocusAction
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var startDate: Date
    var duration: TimeInterval
    var sessionTypeRawValue: String
    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRawValue) ?? .focus }
        set { sessionTypeRawValue = newValue.rawValue }
    }
    var tags: [String]
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        duration: TimeInterval = 0,
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

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }

    var formattedDateLong: String {
        FocusSession.longDateFormatter.string(from: startDate)
    }

    var formattedTime: String {
        FocusSession.timeFormatter.string(from: startDate)
    }

    var formattedTimeRange: String {
        let endDate = startDate.addingTimeInterval(duration)
        return "\(FocusSession.timeFormatter.string(from: startDate)) - \(FocusSession.timeFormatter.string(from: endDate))"
    }

    // MARK: - Cached DateFormatters

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
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

// MARK: - Predicate Helpers

extension FocusSession {
    static func predicate(for tag: String) -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.tags.contains(tag)
        }
    }

    static func predicate(from startDate: Date, to endDate: Date) -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
    }

    static func completedSessionsPredicate() -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.isCompleted == true
        }
    }

    static func focusSessionsPredicate() -> Predicate<FocusSession> {
        #Predicate<FocusSession> { session in
            session.sessionTypeRawValue == "集中"
        }
    }

    static func predicate(for sessionType: SessionType) -> Predicate<FocusSession> {
        let rawValue = sessionType.rawValue
        return #Predicate<FocusSession> { session in
            session.sessionTypeRawValue == rawValue
        }
    }
}
