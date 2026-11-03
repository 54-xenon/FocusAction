//
//  FocusAction_for_WatchApp.swift
//  FocusAction for Watch Watch App
//
//

import SwiftUI
import SwiftData

@main
struct FocusAction_for_Watch_Watch_AppApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // タイマーはアプリ全体で1つ。iPhone から受信した状態もここに反映される
    @State private var timerStore = TimerStore(
        modelContext: PersistenceController.sharedModelContainer.mainContext,
        isFromWatch: true
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTagListView()
            }
            .environment(timerStore)
            .task {
                TimerSyncManager.shared.start(with: timerStore)
            }
        }
        .modelContainer(PersistenceController.sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            timerStore.handleScenePhaseChange(newPhase)
        }
    }
}
