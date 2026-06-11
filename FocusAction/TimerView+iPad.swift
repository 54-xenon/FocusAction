//
//  TimerView+iPad.swift
//  FocusAction
//
//  iPad専用のTimerView UI (将来的に2カラム対応)
//

import SwiftUI

struct TimerViewIPad: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: TimerViewModel

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            GeometryReader { geometry in
                Group {
                    if geometry.size.width > geometry.size.height && geometry.size.width > 800 {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
            }
        }
    }

    // MARK: - Layouts

    private var landscapeLayout: some View {
        HStack(spacing: 60) {
            VStack(spacing: 40) {
                Spacer()
                Text(viewModel.timerMode.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                timerCircle(size: 480)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 50) {
                Spacer()
                controlButtons(size: 90)
                modeSwitcher(isVertical: true)
                Spacer()
            }
            .frame(width: 450)
        }
        .padding(60)
    }

    private var portraitLayout: some View {
        VStack(spacing: 40) {
            Spacer()
            Text(viewModel.timerMode.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            timerCircle(size: 360)
            Spacer()
            controlButtons(size: 80)
            modeSwitcher(isVertical: false)
                .padding(.horizontal, 30)
            Spacer()
        }
        .padding(30)
    }

    // MARK: - Components

    private func timerCircle(size: CGFloat) -> some View {
        let lineWidth = size / 17
        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.timerMode.color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)

            VStack(spacing: size / 20) {
                Text(viewModel.timeString)
                    .font(.system(size: size / 6, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text(viewModel.statusText)
                    .font(.system(size: size / 24))
                    .foregroundStyle(.secondary)
            }
            .padding(size / 6)
        }
        .frame(width: size, height: size)
    }

    private func controlButtons(size: CGFloat) -> some View {
        HStack(spacing: 24) {
            Button(action: viewModel.toggleTimer) {
                Image(systemName: viewModel.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: size / 2.8))
                    .foregroundStyle(viewModel.timerMode.color)
                    .frame(width: size, height: size)
            }
            .glassEffect(.regular.tint(viewModel.timerMode.color.opacity(0.2)).interactive(), in: .circle)

            Button(action: viewModel.resetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: size / 2.8))
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            }
            .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
        }
    }

    private func modeSwitcher(isVertical: Bool) -> some View {
        Group {
            if isVertical {
                VStack(spacing: 16) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        Button(action: { viewModel.switchMode(to: mode) }) {
                            HStack(spacing: 16) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 28))
                                    .frame(width: 40)
                                Text(mode.rawValue)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundStyle(viewModel.timerMode == mode ? mode.color : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                        }
                        .glassEffect(
                            .regular.tint(viewModel.timerMode == mode ? mode.color.opacity(0.15) : .gray.opacity(0.05)).interactive(),
                            in: .rect(cornerRadius: 18)
                        )
                    }
                }
            } else {
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
    }
}
