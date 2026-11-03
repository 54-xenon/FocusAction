//
//  FocusActionApp.swift
//  FocusAction
//
//


import SwiftUI
import SwiftData

@main
struct FocusActionApp: App {
    @Environment(\.scenePhase) private var scenePhase

    // タイマーはアプリ全体で1つ。どのタブを開いていても状態が保たれる
    @State private var timerStore = TimerStore(
        modelContext: PersistenceController.sharedModelContainer.mainContext,
        eventHandlers: TimerEventHandlers.live()
    )

    // DBの初期化
    init() {
        #if DEBUG
        PersistenceController.logCloudKitAccountStatus()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            // UIの読み込み
            ControlView()
                .environment(timerStore)
        }
        .modelContainer(PersistenceController.sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            timerStore.handleScenePhaseChange(newPhase)
        }
    }
}
