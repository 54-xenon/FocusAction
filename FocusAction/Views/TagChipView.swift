//
//  TagChipView.swift
//  FocusAction
//
//  絵文字＋背景色のバッジとタイトルでタグを表示する小さなView
//

import SwiftUI

struct TagChipView: View {
    let tag: Tag?
    var font: Font = .caption

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 20, height: 20)

                Text(tag?.emoji ?? Tag.defaultEmoji)
                    .font(.system(size: 12))
            }

            Text(tag?.title ?? "タグなし")
                .font(font)
                .fontWeight(.semibold)
                .foregroundStyle(tag == nil ? .secondary : .primary)
        }
    }

    private var badgeColor: Color {
        guard let tag else { return Color.gray.opacity(0.2) }
        return Color(hex: tag.colorHex)
    }
}
