//
//  TagPickerMenu.swift
//  FocusAction
//
//  「タグなし」＋登録済みタグの一覧から1つ選択するMenu
//

import SwiftUI
import SwiftData

struct TagPickerMenu: View {
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    let selected: Tag?
    var font: Font = .caption
    let onSelect: (Tag?) -> Void

    var body: some View {
        Menu {
            Button("タグなし") { onSelect(nil) }

            if !tags.isEmpty {
                Divider()
                ForEach(tags) { tag in
                    Button(action: { onSelect(tag) }) {
                        Label(tag.title, systemImage: selected?.id == tag.id ? "checkmark" : "")
                    }
                }
            }
        } label: {
            TagChipView(tag: selected, font: font)
        }
    }
}
