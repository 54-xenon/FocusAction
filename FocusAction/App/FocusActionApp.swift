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
    var body: some Scene {
        WindowGroup {
            ControlView() 
        }
        .modelContainer(for: FocusSession.self)
    }
}
