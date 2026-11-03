//
//  WatchTimerView.swift
//  FocusAction Watch App
//
//  Apple Watch専用のタイマーView
//

import SwiftUI
import SwiftData

struct WatchTimerView: View {
    @Environment(TimerStore.self) private var timerStore
    let initialTag: Tag?

    @State private var feedbackTrigger = 0

    var body: some View {
        ZStack {
            // メインの円形プログレスとタイマー表示
            VStack(spacing: 8) {
                Text(timerStore.timerMode.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: timerStore.progress)
                        .stroke(timerStore.timerMode.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerStore.progress)

                    VStack(spacing: 2) {
                        Text(timerStore.timeString)
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        TagChipView(tag: timerStore.selectedTag, font: .caption2)
                    }
                }
                .frame(width: 150, height: 150)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        Circle()
                            .fill(timerStore.timerMode == mode ? mode.color : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 4)
            }

            // 四隅のボタン（Appleデザインガイドライン準拠）
            VStack {
                HStack {
                    Button {
                        timerStore.switchMode(to: .focus)
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: TimerMode.focus.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(timerStore.timerMode == .focus ? TimerMode.focus.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)

                    Spacer()

                    Button {
                        timerStore.switchMode(to: .shortBreak)
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: TimerMode.shortBreak.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(timerStore.timerMode == .shortBreak ? TimerMode.shortBreak.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                }

                Spacer()

                HStack {
                    Button {
                        timerStore.resetTimer()
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
                        timerStore.toggleTimer()
                        feedbackTrigger += 1
                    } label: {
                        Image(systemName: timerStore.isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .background(timerStore.timerMode.color)
                    .clipShape(Circle())
                }
            }
            .padding(8)
        }
        .sensoryFeedback(.impact, trigger: feedbackTrigger)
        .sensoryFeedback(.success, trigger: timerStore.completionCount)
        .task {
            timerStore.selectedTag = initialTag
        }
    }
}

#Preview {
    WatchTimerView(initialTag: nil)
        .environment(TimerStore(isFromWatch: true))
}
