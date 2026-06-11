//
//  HistoryView+iPhone.swift
//  FocusAction
//
//  iPhone専用のHistoryView UI
//

import SwiftUI
import SwiftData

struct HistoryViewIPhone: View {
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

                VStack(spacing: 0) {
                    statisticsCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    filterButtons
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                    if filteredSessions.isEmpty {
                        emptyStateView
                    } else {
                        sessionList
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatBox(
                    title: "今日",
                    value: "\(todayTotalMinutes)",
                    unit: "分",
                    icon: "calendar",
                    color: .blue
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    title: "今週",
                    value: "\(thisWeekTotalMinutes)",
                    unit: "分",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )

                Divider()
                    .frame(height: 50)

                StatBox(
                    title: "合計",
                    value: "\(completedSessionsCount)",
                    unit: "回",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 20)
        .glassEffect(.regular.tint(.gray.opacity(0.05)), in: .rect(cornerRadius: 20))
    }

    // MARK: - Filter Buttons

    private var filterButtons: some View {
        HStack(spacing: 12) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Button(action: { onFilterChange(option) }) {
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
                                onDeleteSession(session)
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

    // DateFormatter は生成コストが高いので static でキャッシュ
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
