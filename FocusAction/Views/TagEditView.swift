//
//  TagEditView.swift
//  FocusAction
//
//  タグの新規作成・編集フォーム
//

import SwiftUI
import SwiftData

struct TagEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tag: Tag?

    @State private var title: String
    @State private var emoji: String
    @State private var color: Color

    init(tag: Tag?) {
        self.tag = tag
        _title = State(initialValue: tag?.title ?? "")
        _emoji = State(initialValue: tag?.emoji ?? Tag.defaultEmoji)
        _color = State(initialValue: Color(hex: tag?.colorHex ?? Tag.defaultColorHex))
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("プレビュー")
                        Spacer()
                        TagChipView(tag: previewTag, font: .body)
                    }
                }

                Section("タイトル") {
                    TextField("例: 仕事、勉強", text: $title)
                }

                Section("絵文字") {
                    TextField("絵文字を1つ入力", text: $emoji)
                        .onChange(of: emoji) { _, newValue in
                            if let last = newValue.last {
                                emoji = String(last)
                            }
                        }
                }

                Section("背景色") {
                    ColorPicker("絵文字の背景色", selection: $color, supportsOpacity: false)
                }
            }
            .navigationTitle(tag == nil ? "タグを作成" : "タグを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    private var previewTag: Tag {
        Tag(title: title.isEmpty ? "タイトル" : title, emoji: emoji, colorHex: color.toHexString())
    }

    private func save() {
        let colorHex = color.toHexString()
        if let tag {
            tag.title = title
            tag.emoji = emoji
            tag.colorHex = colorHex
        } else {
            let newTag = Tag(title: title, emoji: emoji, colorHex: colorHex)
            modelContext.insert(newTag)
        }
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("タグ保存エラー: \(error.localizedDescription)")
            #endif
        }
        dismiss()
    }
}

#Preview {
    TagEditView(tag: nil)
        .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
