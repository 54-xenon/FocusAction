//
//  FocusActionApp.swift
//  FocusAction
//
//


import SwiftUI
import SwiftData

@main
struct FocusActionApp: App {
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
        }
        .modelContainer(PersistenceController.sharedModelContainer)
    }
}
