//
//  WatchTagListView.swift
//  FocusAction Watch App
//
//  起動時に表示するタグ一覧。タップするとそのタグを選択した状態でタイマー画面に遷移する。
//  タグの作成・編集はiPhone側のみで行い、Watchでは選択のみを行う。
//

import SwiftUI
import SwiftData

struct WatchTagListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = TimerViewModel()

    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @Query(sort: \FocusSession.startDate, order: .reverse) private var allSessions: [FocusSession]

    var body: some View {
        List {
            NavigationLink {
                WatchTimerView(viewModel: viewModel, initialTag: nil)
            } label: {
                row(tag: nil)
            }

            if !tags.isEmpty {
                ForEach(tags) { tag in
                    NavigationLink {
                        WatchTimerView(viewModel: viewModel, initialTag: tag)
                    } label: {
                        row(tag: tag)
                    }
                }
            }
        }
        .navigationTitle("タグ")
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
        .task {
            viewModel.modelContext = modelContext
        }
    }

    private func row(tag: Tag?) -> some View {
        HStack {
            TagChipView(tag: tag, font: .caption)
            Spacer()
            Text("\(focusMinutes(for: tag))分")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func focusMinutes(for tag: Tag?) -> Int {
        allSessions
            .filter { $0.sessionType == .focus && $0.tag?.id == tag?.id }
            .reduce(0) { $0 + $1.durationInMinutes }
    }
}

#Preview {
    NavigationStack {
        WatchTagListView()
    }
    .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
