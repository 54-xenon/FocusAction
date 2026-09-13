//
//  HistoryView.swift
//  FocusAction
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // 統計表示用（フィルタなし全件）
    @Query(sort: \FocusSession.startDate, order: .reverse)
    private var allSessions: [FocusSession]

    @Query(sort: \Tag.createdAt)
    private var allTags: [Tag]

    @State private var selectedFilter: FilterOption = .all
    @State private var selectedTagID: UUID?
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: FocusSession?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HistoryViewIPad(
                    allSessions: allSessions,
                    allTags: allTags,
                    selectedFilter: selectedFilter,
                    selectedTagID: selectedTagID,
                    onFilterChange: { selectedFilter = $0 },
                    onTagFilterChange: { selectedTagID = $0 },
                    onDeleteSession: { sessionToDelete = $0; showDeleteAlert = true },
                    onTagChange: { session, tag in changeTag(of: session, to: tag) }
                )
            } else {
                HistoryViewIPhone(
                    allSessions: allSessions,
                    allTags: allTags,
                    selectedFilter: selectedFilter,
                    selectedTagID: selectedTagID,
                    onFilterChange: { selectedFilter = $0 },
                    onTagFilterChange: { selectedTagID = $0 },
                    onDeleteSession: { sessionToDelete = $0; showDeleteAlert = true },
                    onTagChange: { session, tag in changeTag(of: session, to: tag) }
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

    private func deleteSession(_ session: FocusSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("セッション削除エラー: \(error.localizedDescription)")
            #endif
        }
    }

    private func changeTag(of session: FocusSession, to tag: Tag?) {
        session.tag = tag
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("タグ変更エラー: \(error.localizedDescription)")
            #endif
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
    let onTagChange: (Tag?) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(sessionColor)
            }

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

                TagPickerMenu(selected: session.tag, onSelect: onTagChange)
            }

            Spacer()

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

extension FocusSession {
    // SwiftData の @Query に渡す、種別/完了状態/タグの複合Predicate
    static func predicate(filterOption: FilterOption, tagID: UUID?) -> Predicate<FocusSession> {
        let requireCompletedOnly = filterOption == .completed
        let sessionTypeRawValue: String? = {
            switch filterOption {
            case .focus: return SessionType.focus.rawValue
            case .shortBreak: return SessionType.shortBreak.rawValue
            default: return nil
            }
        }()
        return #Predicate<FocusSession> { session in
            (sessionTypeRawValue == nil || session.sessionTypeRawValue == sessionTypeRawValue!) &&
            (!requireCompletedOnly || session.isCompleted == true) &&
            (tagID == nil || session.tag?.id == tagID)
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
