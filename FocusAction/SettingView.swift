//
//  SettingView.swift
//  FocusAction
//
//

import SwiftUI

struct SettingView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showTestAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                List {
                    // 通知設定セクション
                    Section {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            
                            Text("通知")
                                .font(.body)
                            
                            Spacer()
                            
                            Text(notificationManager.isAuthorized ? "許可" : "未許可")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !notificationManager.isAuthorized {
                            Button(action: {
                                Task {
                                    await notificationManager.requestAuthorization()
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("通知を許可")
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                            }
                        } else {
                            Button(action: {
                                notificationManager.sendTestNotification()
                                showTestAlert = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("テスト通知を送信（5秒後）")
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        Text("通知設定")
                    } footer: {
                        Text("タイマー完了時に通知を受け取るには、通知を許可してください。")
                    }
                    
                    // アプリ情報セクション
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            
                            Text("バージョン")
                            
                            Spacer()
                            
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 30)
                            
                            Text("ダークモード")
                            
                            Spacer()
                            
                            Text(colorScheme == .dark ? "ON" : "OFF")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("アプリ情報")
                    } footer: {
                        Text("ダークモードはシステム設定に従います。")
                    }
                    
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .alert("テスト通知", isPresented: $showTestAlert) {
                Button("OK") { }
            } message: {
                Text("5秒後に通知が届きます")
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingView()
}
