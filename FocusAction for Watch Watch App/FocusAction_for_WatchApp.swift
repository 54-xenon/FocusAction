//
//  FocusAction_for_WatchApp.swift
//  FocusAction for Watch Watch App
//
//  Created by とくおかけいと on 2026/05/14.
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
