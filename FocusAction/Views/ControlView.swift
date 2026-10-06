//
//  ControlView.swift
//  FocusAction
//
//

// Tabviewでページを切り替えるようにする
    // タイマー
    // 履歴
    // 設定

import SwiftUI


struct ControlView: View {
    var body: some View {
        TabView {
            // タイマ
            TimerView()
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }
            // 履歴
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "chart.bar")
                }
            // 設定
            SettingView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        // iPadOSでサイドバーを有効化するためのもの
        .tabViewStyle(.sidebarAdaptable)
    }
}
