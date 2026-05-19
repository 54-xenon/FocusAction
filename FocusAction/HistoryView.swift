//
//  HistoryView.swift
//  FocusAction
//
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    // SwiftDataから全てのセッションを取得（新しい順）
    @Query(sort: \FocusSession.startDate, order: .reverse)
    private var allSessions: [FocusSession]
    
    @State private var selectedFilter: FilterOption = .all
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: FocusSession?
    
    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 統計情報カード
                    statisticsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // フィルター
                    filterButtons
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // セッションリスト
                    if filteredSessions.isEmpty {
                        emptyStateView
                    } else {
                        sessionList
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .alert("セッションを削除", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                }
            } message: {
                Text("このセッションを削除してもよろしいですか？")
            }
        }
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // 今日の統計
                    StatBox(
                        title: "今日",
                        value: "\(todayTotalMinutes)",
                        unit: "分",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 50)
                    
                    // 今週の統計
                    StatBox(
                        title: "今週",
                        value: "\(thisWeekTotalMinutes)",
                        unit: "分",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 50)
                    
                    // 総セッション数
                    StatBox(
                        title: "合計",
                        value: "\(completedSessions.count)",
                        unit: "回",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 20)
        }
        .glassEffect(.regular.tint(.gray.opacity(0.05)), in: .rect(cornerRadius: 20))
    }
    
    // MARK: - Filter Buttons
    
    private var filterButtons: some View {
        HStack(spacing: 12) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Button(action: { selectedFilter = option }) {
                    Text(option.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedFilter == option ? .white : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == option ?
                            Color.blue : Color.gray.opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                    Section {
                        ForEach(groupedSessions[date] ?? []) { session in
                            SessionRow(session: session, onDelete: {
                                sessionToDelete = session
                                showDeleteAlert = true
                            })
                        }
                    } header: {
                        HStack {
                            Text(formatSectionDate(date))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(dailyTotal(for: date))分")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))
            Text("まだ履歴がありません")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("タイマーを使って集中セッションを始めましょう")
                .font(.subheadline)
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
    
    private func deleteSession(_ session: FocusSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            print("セッション削除エラー: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

/// 統計情報ボックス
struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// セッション行
struct SessionRow: View {
    let session: FocusSession
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(sessionColor)
            }
            
            // セッション情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.sessionType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if !session.isCompleted {
                        Text("未完了")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.7))
                            .clipShape(Capsule())
                    }
                }
                
                Text(session.formattedTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 時間表示
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedDuration)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var sessionColor: Color {
        switch session.sessionType {
        case .focus: return .blue
        case .shortBreak: return .green
        }
    }
}

// MARK: - Filter Options

enum FilterOption: String, CaseIterable {
    case all = "すべて"
    case focus = "集中"
    case shortBreak = "休憩"
    case completed = "完了済み"
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: FocusSession.self, inMemory: true)
}
