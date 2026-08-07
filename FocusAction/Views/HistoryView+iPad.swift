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

    // フィルタ済みリスト（SwiftData側でフィルタ）
    @Query private var filteredSessions: [FocusSession]

    // 統計用（フィルタなし全件、親から受け取る）
    let allSessions: [FocusSession]
    let selectedFilter: FilterOption
    let onFilterChange: (FilterOption) -> Void
    let onDeleteSession: (FocusSession) -> Void

    init(
        allSessions: [FocusSession],
        selectedFilter: FilterOption,
        onFilterChange: @escaping (FilterOption) -> Void,
        onDeleteSession: @escaping (FocusSession) -> Void
    ) {
        self.allSessions = allSessions
        self.selectedFilter = selectedFilter
        self.onFilterChange = onFilterChange
        self.onDeleteSession = onDeleteSession
        _filteredSessions = Query(
            filter: selectedFilter.predicate,
            sort: \FocusSession.startDate,
            order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    Group {
                        if geometry.size.width > 800 {
                            landscapeLayout
                        } else {
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

    private var landscapeLayout: some View {
        HStack(spacing: 30) {
            VStack(spacing: 24) {
                statisticsCard
                filterButtons(isVertical: true)
                Spacer()
            }
            .frame(width: 400)
            .padding(.leading, 30)

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
        VStack(spacing: 24) {
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
                        value: "\(completedSessionsCount)",
                        unit: "回",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
            }
        }
        .padding(24)
        .glassEffect(.regular.tint(.gray.opacity(0.05)), in: .rect(cornerRadius: 24))
    }

    // MARK: - Filter Buttons

    private func filterButtons(isVertical: Bool) -> some View {
        Group {
            if isVertical {
                VStack(spacing: 12) {
                    filterButtonsContent
                }
            } else {
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

    private var sessionList: some View {
        ScrollView {
            sessionListContent
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }

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

    private var completedSessionsCount: Int {
        allSessions.filter { $0.isCompleted }.count
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
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) else { return 0 }
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

    // MARK: - Date Formatting

    private static let sectionDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日 (E)"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今日" }
        if calendar.isDateInYesterday(date) { return "昨日" }
        return Self.sectionDateFormatter.string(from: date)
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
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(sessionColor)
            }

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
