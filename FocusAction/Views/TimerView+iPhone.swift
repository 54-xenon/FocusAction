//
//  TimerView+iPhone.swift
//  FocusAction
//
//

import SwiftUI

struct TimerViewIPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(TimerStore.self) private var timerStore

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            VStack(spacing: 40) {

                // モード表示(集中 or 休憩)
                modeMenu

                // 円形のプログレスバー
                timerCircle

                Spacer()

                // コントロールボタン(再生/停止、リセット)
                controlButtons

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Components

    private var modeMenu: some View {
        Menu {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button(action: { timerStore.switchMode(to: mode) }) {
                    Label(mode.rawValue, systemImage: mode.icon)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(timerStore.timerMode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 20)

            Circle()
                .trim(from: 0, to: timerStore.progress)
                .stroke(
                    timerStore.timerMode.color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerStore.progress)

            VStack(spacing: 16) {
                Text(timerStore.timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if timerStore.isCompleted {
                    Text("完了！")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    TagPickerMenu(selected: timerStore.selectedTag, font: .subheadline) {
                        timerStore.selectedTag = $0
                    }
                }
            }
            .padding(60)
        }
        .frame(width: 320, height: 320)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button(action: timerStore.toggleTimer) {
                Image(systemName: timerStore.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(timerStore.timerMode.color)
                    .frame(width: 70, height: 70)
            }
            .glassEffect(.regular.tint(timerStore.timerMode.color.opacity(0.2)).interactive(), in: .circle)

            Button(action: timerStore.resetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, height: 70)
            }
            .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
        }
    }
}
