//
//  HistoryView.swift
//  FocusAction
//
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    
    // SwiftDataから全てのセッションを取得（新しい順）
    @Query(sort: \FocusSession.startDate, order: .reverse)
    private var allSessions: [FocusSession]
    
    @State private var selectedFilter: FilterOption = .all
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: FocusSession?
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad用UI
                HistoryViewIPad(
                    allSessions: allSessions,
                    selectedFilter: selectedFilter,
                    onFilterChange: { filter in
                        selectedFilter = filter
                    },
                    onDeleteSession: { session in
                        sessionToDelete = session
                        showDeleteAlert = true
                    }
                )
            } else {
                // iPhone用UI
                HistoryViewIPhone(
                    allSessions: allSessions,
                    selectedFilter: selectedFilter,
                    onFilterChange: { filter in
                        selectedFilter = filter
                    },
                    onDeleteSession: { session in
                        sessionToDelete = session
                        showDeleteAlert = true
                    }
                )
            }
        }
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
    
    // MARK: - Helper Functions
    
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
