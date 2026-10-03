//
//  HistoryWidget.swift
//  FocusActionWidget
//
//  今日・今週の集中時間と直近7日間の推移を表示するホーム画面 / ロック画面 Widget
//

import WidgetKit
import SwiftUI
import Charts

struct HistoryWidgetEntry: TimelineEntry {
    let date: Date
    let summary: HistoryWidgetSummary
}

struct HistoryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HistoryWidgetEntry {
        HistoryWidgetEntry(date: .now, summary: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HistoryWidgetEntry) -> Void) {
        let summary = WidgetSharedData.loadHistorySummary()
        let isEmpty = summary.updatedAt == .distantPast
        completion(HistoryWidgetEntry(date: .now, summary: context.isPreview && isEmpty ? .preview : summary.adjusted(for: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HistoryWidgetEntry>) -> Void) {
        let summary = WidgetSharedData.loadHistorySummary()
        let now = Date.now
        let calendar = Calendar.current
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(3600)

        // 日付が変わったら「今日」をリセットした表示に切り替える
        let entries = [
            HistoryWidgetEntry(date: now, summary: summary.adjusted(for: now)),
            HistoryWidgetEntry(date: nextMidnight, summary: summary.adjusted(for: nextMidnight))
        ]
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}

struct HistoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSharedData.Kind.history, provider: HistoryWidgetProvider()) { entry in
            HistoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("履歴")
        .description("今日・今週の集中時間と直近7日間の推移を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - 日付またぎの補正

private extension HistoryWidgetSummary {
    /// 集計した日から日付が変わっていた場合、今日/今週の値と7日間の並びを表示日に合わせる
    func adjusted(for date: Date) -> HistoryWidgetSummary {
        let calendar = Calendar.current
        guard updatedAt != .distantPast, !calendar.isDate(updatedAt, inSameDayAs: date) else { return self }

        let today = calendar.startOfDay(for: date)
        let minutesByDay = Dictionary(last7Days.map { (calendar.startOfDay(for: $0.date), $0.minutes) }, uniquingKeysWith: +)
        let days = (0..<7).compactMap { offset -> DailyTotal? in
            guard let day = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            return DailyTotal(date: day, minutes: minutesByDay[day] ?? 0)
        }

        var result = self
        result.todayMinutes = 0
        result.todaySessionCount = 0
        if !calendar.isDate(updatedAt, equalTo: date, toGranularity: .weekOfYear) {
            result.thisWeekMinutes = 0
        }
        result.last7Days = days
        return result
    }

    static let preview: HistoryWidgetSummary = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let minutes = [50, 75, 25, 100, 0, 125, 75]
        return HistoryWidgetSummary(
            todayMinutes: 75,
            todaySessionCount: 3,
            thisWeekMinutes: 375,
            completedSessionsCount: 42,
            last7Days: minutes.enumerated().map { index, value in
                DailyTotal(date: calendar.date(byAdding: .day, value: index - 6, to: today) ?? today, minutes: value)
            },
            updatedAt: .now
        )
    }()
}

// MARK: - Views

private struct HistoryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HistoryWidgetEntry

    private var summary: HistoryWidgetSummary { entry.summary }

    var body: some View {
        switch family {
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            Label("今日 \(summary.todayMinutes)分・今週 \(summary.thisWeekMinutes)分", systemImage: "chart.bar")
        case .systemMedium:
            medium
        default:
            small
        }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("今日", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
            minutesText(summary.todayMinutes, size: 36)
            Text("\(summary.todaySessionCount)セッション")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.green)
                Text("今週 \(summary.thisWeekMinutes)分")
                    .fontWeight(.semibold)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                statRow(title: "今日", value: summary.todayMinutes, unit: "分", icon: "calendar", color: .blue)
                statRow(title: "今週", value: summary.thisWeekMinutes, unit: "分", icon: "chart.line.uptrend.xyaxis", color: .green)
                statRow(title: "合計", value: summary.completedSessionsCount, unit: "回", icon: "flame.fill", color: .orange)
            }
            .frame(width: 110, alignment: .leading)

            WeeklyChart(days: summary.last7Days)
        }
    }

    private func statRow(title: String, value: Int, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title3.weight(.bold).monospacedDigit())
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func minutesText(_ minutes: Int, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(minutes)")
                .font(.system(size: size, weight: .bold).monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("分")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Lock Screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("今日の集中", systemImage: "brain.head.profile")
                .font(.headline)
                .widgetAccentable()
            Text("\(summary.todayMinutes)分・\(summary.todaySessionCount)回")
                .font(.title3.weight(.semibold).monospacedDigit())
            Text("今週 \(summary.thisWeekMinutes)分")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeeklyChart: View {
    let days: [HistoryWidgetSummary.DailyTotal]

    // Extension は日本語ローカライズを持たないため、曜日は明示的に日本語で表示する
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "E"
        return f
    }()

    var body: some View {
        if days.isEmpty {
            Text("まだ記録がありません")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(days, id: \.date) { day in
                BarMark(
                    x: .value("日付", day.date, unit: .day),
                    y: .value("分", day.minutes)
                )
                .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Color.blue : Color.blue.opacity(0.4))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(Self.weekdayFormatter.string(from: date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    HistoryWidget()
} timeline: {
    HistoryWidgetEntry(date: .now, summary: .preview)
}

#Preview("Medium", as: .systemMedium) {
    HistoryWidget()
} timeline: {
    HistoryWidgetEntry(date: .now, summary: .preview)
    HistoryWidgetEntry(date: .now, summary: .empty)
}
