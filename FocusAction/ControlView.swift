//
//  ControlView.swift
//  FocusAction
//
//  Created by とくおかけいと on 2026/05/06.
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
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            // settings
            SettingView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
