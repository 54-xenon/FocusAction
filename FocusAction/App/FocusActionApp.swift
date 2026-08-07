//
//  FocusActionApp.swift
//  FocusAction
//
//

// 必要なライブラリを読み込み
import SwiftUI
import SwiftData

@main
struct FocusActionApp: App {
    init() {
        #if DEBUG
        PersistenceController.logCloudKitAccountStatus()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ControlView()
        }
        .modelContainer(PersistenceController.sharedModelContainer)
    }
}
