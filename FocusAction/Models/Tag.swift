//
//  Tag.swift
//  FocusAction
//
//  iOS/watchOS共通のモデル
//

import Foundation
import SwiftData

@Model
final class Tag {
    static let defaultEmoji = "🏷️"
    static let defaultColorHex = "#3B82F6"

    var id: UUID = UUID()
    var title: String = ""
    var emoji: String = Tag.defaultEmoji
    var colorHex: String = Tag.defaultColorHex
    var createdAt: Date = Date()

    /// CloudKit同期にはリレーションの逆方向(inverse)が必須。FocusSession.tag の対になる側。
    @Relationship(deleteRule: .nullify, inverse: \FocusSession.tag)
    var sessions: [FocusSession]? = []

    init(
        id: UUID = UUID(),
        title: String = "",
        emoji: String = Tag.defaultEmoji,
        colorHex: String = Tag.defaultColorHex,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
