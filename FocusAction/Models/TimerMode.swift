//
//  TimerMode.swift
//  FocusAction
//
//  iOS/watchOS共通のモデル
//  このファイルは両方のTargetに追加してください
//

import SwiftUI

enum TimerMode: String, CaseIterable {
    case focus = "集中"
    case shortBreak = "休憩"
    
    var duration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return .blue
        case .shortBreak: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        }
    }
    
    var title: String {
        switch self {
        case .focus: return "集中タイム"
        case .shortBreak: return "休憩タイム"
        }
    }
}
