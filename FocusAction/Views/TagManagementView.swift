//
//  TagManagementView.swift
//  FocusAction
//
//  設定画面から遷移するタグの一覧・作成・削除画面
//

import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    @State private var editingTag: Tag?
    @State private var showEditSheet = false

    var body: some View {
        List {
            if tags.isEmpty {
                Text("タグがまだありません")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tags) { tag in
                    Button(action: { editingTag = tag; showEditSheet = true }) {
                        TagChipView(tag: tag, font: .body)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: deleteTags)
            }
        }
        .navigationTitle("タグ")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { editingTag = nil; showEditSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TagEditView(tag: editingTag)
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("タグ削除エラー: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        TagManagementView()
    }
    .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
