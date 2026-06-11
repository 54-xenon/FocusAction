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
        }
        .task {
            viewModel.modelContext = modelContext
            if !viewModel.notificationManager.isAuthorized {
                await viewModel.notificationManager.requestAuthorization()
            }
            viewModel.notificationManager.clearBadge()
        }
    }
}

#Preview {
    TimerView()
}
