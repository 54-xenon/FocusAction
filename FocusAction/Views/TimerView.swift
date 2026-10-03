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

    @StateObject private var viewModel = TimerViewModel()

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                TimerViewIPad(viewModel: viewModel)
            } else {
                TimerViewIPhone(viewModel: viewModel)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
            // CloudKit経由で他端末の履歴が増えている可能性があるので、アクティブ時にWidgetの集計も更新する
            if newPhase == .active {
                WidgetDataWriter.updateHistory(using: modelContext)
            }
        }
        .task {
            viewModel.modelContext = modelContext
            WidgetDataWriter.updateHistory(using: modelContext)
            WidgetDataWriter.updateTimer(with: viewModel)
            if !viewModel.notificationManager.isAuthorized {
                await viewModel.notificationManager.requestAuthorization()
            }
            viewModel.notificationManager.clearBadge()
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FocusSession.self, Tag.self], inMemory: true)
}
