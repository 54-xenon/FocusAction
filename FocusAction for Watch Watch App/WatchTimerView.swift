//
//  WatchTimerView.swift
//  FocusAction Watch App
//
//  Apple Watch専用のタイマーView
//

import SwiftUI
import SwiftData

struct WatchTimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    let initialTag: Tag?

    @State private var feedbackTrigger = 0

    var body: some View {
        ZStack {
            // メインの円形プログレスとタイマー表示
            VStack(spacing: 8) {
                Text(viewModel.timerMode.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(viewModel.timerMode.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.progress)

                    VStack(spacing: 2) {
                        Text(viewModel.timeString)
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        TagChipView(tag: viewModel.selectedTag, font: .caption2)
                    }
                }
                .frame(width: 150, height: 150)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        Circle()
                            .fill(viewModel.timerMode == mode ? mode.color : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 4)
            }

            // 四隅のボタン（Appleデザインガイドライン準拠）
            VStack {
                HStack {
                    Button {
                        viewModel.switchMode(to: .focus)
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: TimerMode.focus.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(viewModel.timerMode == .focus ? TimerMode.focus.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)

                    Spacer()

                    Button {
                        viewModel.switchMode(to: .shortBreak)
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: TimerMode.shortBreak.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(viewModel.timerMode == .shortBreak ? TimerMode.shortBreak.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                }

                Spacer()

                HStack {
                    Button {
                        viewModel.resetTimer()
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)

                    Spacer()

                    Button {
                        viewModel.toggleTimer()
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .background(viewModel.timerMode.color)
                    .clipShape(Circle())
                }
            }
            .padding(8)
        }
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
        .sensoryFeedback(.success, trigger: viewModel.completionCount)
        .task {
            viewModel.selectedTag = initialTag
        }
    }
}

#Preview {
    WatchTimerView(viewModel: TimerViewModel(), initialTag: nil)
}
