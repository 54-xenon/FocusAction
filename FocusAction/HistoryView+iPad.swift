//
//  HistoryView+iPad.swift
//  FocusAction
//
//  iPad専用のHistoryView UI (将来的に2カラム・グラフ表示対応)
//

import SwiftUI
import SwiftData

struct HistoryViewIPad: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let allSessions: [FocusSession]
    let selectedFilter: FilterOption
    let onFilterChange: (FilterOption) -> Void
    let onDeleteSession: (FocusSession) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Group {
                        if geometry.size.width > 800 {
                            // 横向きフルスクリーン: 2カラムレイアウト
                            landscapeLayout
                        } else {
                            // 縦向き/マルチウィンドウ: 1カラムレイアウト
                            portraitLayout
                        }
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Layouts
    
    // 横向きフルスクリーン用レイアウト
    private var landscapeLayout: some View {
        HStack(spacing: 30) {
            // 左側: 統計情報とフィルター
            VStack(spacing: 24) {
                statisticsCard
                filterButtons(isVertical: true)
                
                // 将来的にグラフを追加する予定のスペース
                Spacer()
            }
            .frame(width: 400)
            .padding(.leading, 30)
            
            // 右側: セッションリスト
            VStack(spacing: 0) {
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionList
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 30)
        }
        .padding(.top, 20)
    }
    
    // 縦向き/マルチウィンドウ用レイアウト
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    statisticsCard
                        .padding(.horizontal, 20)
                    
                    filterButtons(isVertical: false)
                        .padding(.horizontal, 20)
                    
                    if filteredSessions.isEmpty {
                        emptyStateView
                            .frame(height: 400)
                    } else {
                        sessionListContent
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 24) {
                // 今日の統計（大きく表示）
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("今日の集中時間")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(todayTotalMinutes)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("分")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Divider()
                
                // その他の統計
                VStack(spacing: 16) {
                    HStack {
                        StatBoxIPad(
                            title: "今週",
                            value: "\(thisWeekTotalMinutes)",
                            unit: "分",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                        
                        StatBoxIPad(
                            title: "合計",
                            value: "\(completedSessions.count)",
                            unit: "回",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                }
            }
            .padding(24)
        }
        .glassEffect(.regular.tint(.gray.opacity(0.05)), in: .rect(cornerRadius: 24))
    }
    
    // MARK: - Filter Buttons
    
    private func filterButtons(isVertical: Bool) -> some View {
        Group {
            if isVertical {
                // 縦並び（横向きフルスクリーン）
                VStack(spacing: 12) {
                    filterButtonsContent
                }
            } else {
                // 横スクロール（縦向き/マルチウィンドウ）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        filterButtonsContent
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var filterButtonsContent: some View {
        ForEach(FilterOption.allCases, id: \.self) { option in
            Button(action: { onFilterChange(option) }) {
                HStack {
                    Text(option.rawValue)
                        .font(.body)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundStyle(selectedFilter == option ? .primary : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(minWidth: 120)
                .background(
                    selectedFilter == option ?
                    Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Session List
    
    // 横向きフルスクリーン用のスクロール可能リスト
    private var sessionList: some View {
        ScrollView {
            sessionListContent
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }
    
    // セッションリストの共通コンテンツ
    private var sessionListContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedSessions[date] ?? []) { session in
                        SessionRowIPad(session: session, onDelete: {
                            onDeleteSession(session)
                        })
                    }
                } header: {
                    HStack {
                        Text(formatSectionDate(date))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(dailyTotal(for: date))分")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.3))
            Text("まだ履歴がありません")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("タイマーを使って集中セッションを始めましょう")
                .font(.title3)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [FocusSession] {
        switch selectedFilter {
        case .all:
            return allSessions
        case .focus:
            return allSessions.filter { $0.sessionType == .focus }
        case .shortBreak:
            return allSessions.filter { $0.sessionType == .shortBreak }
        case .completed:
            return allSessions.filter { $0.isCompleted }
        }
    }
    
    private var completedSessions: [FocusSession] {
        allSessions.filter { $0.isCompleted }
    }
    
    private var groupedSessions: [Date: [FocusSession]] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.startDate)
        }
    }
    
    private var todayTotalMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allSessions
            .filter { Calendar.current.startOfDay(for: $0.startDate) == today }
            .filter { $0.sessionType == .focus }
            .reduce(0) { $0 + $1.durationInMinutes }
    }
    
    private var thisWeekTotalMinutes: Int {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return 0
        }
        return allSessions
            .filter { $0.startDate >= weekStart }
            .filter { $0.sessionType == .focus }
            .reduce(0) { $0 + $1.durationInMinutes }
    }
    
    private func dailyTotal(for date: Date) -> Int {
        groupedSessions[date]?
            .filter { $0.sessionType == .focus }
            .reduce(0) { $0 + $1.durationInMinutes } ?? 0
    }
    
    // MARK: - Helper Functions
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 (E)"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: date)
        }
    }
}

// MARK: - iPad専用コンポーネント

struct StatBoxIPad: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SessionRowIPad: View {
    let session: FocusSession
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // アイコン
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(sessionColor)
            }
            
            // セッション情報
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.sessionType.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if !session.isCompleted {
                        Text("未完了")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.7))
                            .clipShape(Capsule())
                    }
                }
                
                Text(session.formattedTimeRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 時間表示
            VStack(alignment: .trailing, spacing: 8) {
                Text(session.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Button(action: onDelete) {
                    Label("削除", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var sessionColor: Color {
        switch session.sessionType {
        case .focus: return .blue
        case .shortBreak: return .green
        }
    }
}
