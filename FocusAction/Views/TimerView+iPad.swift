//
//  TimerView+iPad.swift
//  FocusAction
//
//

import SwiftUI

struct TimerViewIPad: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(TimerStore.self) private var timerStore

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height && geometry.size.width > 800
                let minDimension = min(geometry.size.width, geometry.size.height)
                let circleSize = minDimension * 0.45
                let buttonSize = minDimension * 0.08
                let spacing = minDimension * 0.04
                let titleFont: Font = isLandscape ? .largeTitle : .title
                let padding: CGFloat = isLandscape ? 60 : 30

                VStack(spacing: spacing) {
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
                Button(action: { timerStore.switchMode(to: mode) }) {
                    Label(mode.rawValue, systemImage: mode.icon)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(timerStore.timerMode.title)
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
                .trim(from: 0, to: timerStore.progress)
                .stroke(
                    timerStore.timerMode.color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerStore.progress)

            VStack(spacing: size / 20) {
                Text(timerStore.timeString)
                    .font(.system(size: size / 6, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if timerStore.isCompleted {
                    Text("完了！")
                        .font(.system(size: size / 24))
                        .foregroundStyle(.secondary)
                } else {
                    TagPickerMenu(selected: timerStore.selectedTag, font: .system(size: size / 24)) {
                        timerStore.selectedTag = $0
                    }
                }
            }
            .padding(size / 6)
        }
        .frame(width: size, height: size)
    }

    private func controlButtons(size: CGFloat) -> some View {
        HStack(spacing: 24) {
            Button(action: timerStore.toggleTimer) {
                Image(systemName: timerStore.isTimerRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: size / 2.8))
                    .foregroundStyle(timerStore.timerMode.color)
                    .frame(width: size, height: size)
            }
            .glassEffect(.regular.tint(timerStore.timerMode.color.opacity(0.2)).interactive(), in: .circle)

            Button(action: timerStore.resetTimer) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: size / 2.8))
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            }
            .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
        }
    }
}
