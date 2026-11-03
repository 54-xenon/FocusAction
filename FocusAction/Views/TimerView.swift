//
//  TimerView.swift
//  FocusAction
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    @Environment(TimerStore.self) private var timerStore

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                TimerViewIPad()
            } else {
                TimerViewIPhone()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // CloudKit経由で他端末の履歴が増えている可能性があるので、アクティブ時にWidgetの集計も更新する
            if newPhase == .active {
                WidgetDataWriter.updateHistory(using: modelContext)
            }
        }
        .task {
            WidgetDataWriter.updateHistory(using: modelContext)
            WidgetDataWriter.updateTimer(state: timerStore.state, tag: timerStore.selectedTag)
            let notificationManager = NotificationManager.shared
            if !notificationManager.isAuthorized {
                await notificationManager.requestAuthorization()
            }
            notificationManager.clearBadge()
        }
    }
}

#Preview {
    TimerView()
        .environment(TimerStore())
        .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
