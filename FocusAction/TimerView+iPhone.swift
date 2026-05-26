//
//  TimerView+iPhone.swift
//  FocusAction
//
//  iPhone専用のTimerView UI
//

import SwiftUI
import SwiftData

struct TimerViewIPhone: View {
    @Environment(\.colorScheme) var colorScheme
    
    // 親から渡されるバインディング
    @Binding var isTimerRunning: Bool
    @Binding var timeRemaining: TimeInterval
    @Binding var timerMode: TimerMode
    
    let progress: CGFloat
    let timeString: String
    let statusText: String
    
    let onToggleTimer: () -> Void
    let onResetTimer: () -> Void
    let onSwitchMode: (TimerMode) -> Void
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // タイマーモード表示
                Text(timerMode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // 円形プログレスバー
                timerCircle
                
                Spacer()
                
                // コントロールボタン
                controlButtons
                
                // モード切り替えボタン
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
            // 背景の円
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 20)
            
            // プログレスを示す円
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerMode.color,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // 中央のタイマー表示
            VStack(spacing: 16) {
                Text(timeString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(60)
        }
        .frame(width: 320, height: 320)
    }
    
    private var controlButtons: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 20) {
                // 再生/一時停止ボタン
                Button(action: onToggleTimer) {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(timerMode.color)
                        .frame(width: 70, height: 70)
                }
                .glassEffect(.regular.tint(timerMode.color.opacity(0.2)).interactive(), in: .circle)
                
                // リセットボタン
                Button(action: onResetTimer) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, height: 70)
                }
                .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
            }
        }
    }
    
    private var modeSwitcher: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Button(action: { onSwitchMode(mode) }) {
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 24))
                            Text(mode.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(timerMode == mode ? mode.color : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .glassEffect(
                        .regular.tint(timerMode == mode ? mode.color.opacity(0.15) : .gray.opacity(0.05)).interactive(),
                        in: .rect(cornerRadius: 20)
                    )
                }
            }
        }
    }
}
