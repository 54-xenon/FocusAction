//
//  ControlView.swift
//  FocusAction
//
//

// Tabviewでページを切り替えるようにする
    // Timer
    // History
    // Settings

import SwiftUI


struct ControlView: View {
    var body: some View {
        TabView {
            // Timer
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            // History
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
            // settings
            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // iPadOSでサイドバーを有効化するため
        .tabViewStyle(.sidebarAdaptable)
    }
}
