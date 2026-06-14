//
//  TimerView+iPad.swift
//  FocusAction
//
//  iPad専用のTimerView UI (将来的に2カラム対応)
//

import SwiftUI

struct TimerViewIPad: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height && geometry.size.width > 800
                let circleSize: CGFloat = isLandscape ? 440 : 360
                let buttonSize: CGFloat = isLandscape ? 90 : 80
                let titleFont: Font = isLandscape ? .largeTitle : .title
                let padding: CGFloat = isLandscape ? 60 : 30

                VStack(spacing: 40) {
//                    Spacer()
                    modeMenu(font: titleFont)
                    timerCircle(size: circleSize)
                    Spacer()
                    controlButtons(size: buttonSize)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(padding)
            }
        }
    }

    // MARK: - Components

    private func modeMenu(font: Font) -> some View {
        Menu {
            ForEach(TimerMode.allCases, id: \.self) { mode in
                Button(action: { viewModel.switchMode(to: mode) }) {
                    Label(mode.rawValue, systemImage: mode.icon)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(viewModel.timerMode.title)
                    .font(font)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

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
}
