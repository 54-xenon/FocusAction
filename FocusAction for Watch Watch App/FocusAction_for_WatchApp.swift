//
//  FocusAction_for_WatchApp.swift
//  FocusAction for Watch Watch App
//
//

import SwiftUI
import SwiftData

@main
struct FocusAction_for_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTimerView()
        }
        .modelContainer(PersistenceController.sharedModelContainer)
    }
}
