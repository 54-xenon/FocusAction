//
//  TimerView+iPhone.swift
//  FocusAction
//
//  iPhone専用のTimerView UI
//

import SwiftUI

struct TimerViewIPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text(viewModel.timerMode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                timerCircle

                Spacer()

                controlButtons

                modeSwitcher
                    .padding(.horizontal, 20)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Components

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 20)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.timerMode.color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)

            VStack(spacing: 16) {
                Text(viewModel.timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(viewModel.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(60)
        }
        .frame(width: 320, height: 320)
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button(action: viewModel.toggleTimer) {
                Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(viewModel.timerMode.color)
                    .frame(width: 70, height: 70)
            }
            .glassEffect(.regular.tint(viewModel.timerMode.color.opacity(0.2)).interactive(), in: .circle)

            Button(action: viewModel.resetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, height: 70)
            }
            .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 12) {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button(action: { viewModel.switchMode(to: mode) }) {
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 24))
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.timerMode == mode ? mode.color : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .glassEffect(
                    .regular.tint(viewModel.timerMode == mode ? mode.color.opacity(0.15) : .gray.opacity(0.05)).interactive(),
                    in: .rect(cornerRadius: 20)
                )
            }
        }
    }
}
