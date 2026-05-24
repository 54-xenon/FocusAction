//
//  TimerView+iPad.swift
//  FocusAction
//
//  iPad専用のTimerView UI (将来的に2カラム対応)
//

import SwiftUI
import SwiftData

struct TimerViewIPad: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
    
    // レイアウト判定：横向きフルスクリーン or 縦向き/マルチウィンドウ
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                Group {
                    // 横向き判定: 幅が高さより大きく、かつ800px以上
                    if geometry.size.width > geometry.size.height && geometry.size.width > 800 {
                        // 横向きフルスクリーン: 2カラムレイアウト
                        landscapeLayout
                    } else {
                        // 縦向き/マルチウィンドウ: 1カラムレイアウト（iPhoneと同じ）
                        portraitLayout
                    }
                }
            }
        }
    }
    
    // MARK: - Layouts
    
    // 横向きフルスクリーン用レイアウト
    private var landscapeLayout: some View {
        HStack(spacing: 60) {
            // 左側: タイマーエリア
            VStack(spacing: 40) {
                Spacer()
                
                Text(timerMode.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                timerCircle(size: 480)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // 右側: コントロールとモード切り替え
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
    
    // 縦向き/マルチウィンドウ用レイアウト
    private var portraitLayout: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text(timerMode.title)
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
            // 背景の円
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
            
            // プログレスを示す円
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerMode.color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // 中央のタイマー表示
            VStack(spacing: size / 20) {
                Text(timeString)
                    .font(.system(size: size / 6, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text(statusText)
                    .font(.system(size: size / 24))
                    .foregroundStyle(.secondary)
            }
            .padding(size / 6)
        }
        .frame(width: size, height: size)
    }
    
    private func controlButtons(size: CGFloat) -> some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 24) {
                // 再生/一時停止ボタン
                Button(action: onToggleTimer) {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: size / 2.8))
                        .foregroundStyle(timerMode.color)
                        .frame(width: size, height: size)
                }
                .glassEffect(.regular.tint(timerMode.color.opacity(0.2)).interactive(), in: .circle)
                
                // リセットボタン
                Button(action: onResetTimer) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: size / 2.8))
                        .foregroundStyle(.secondary)
                        .frame(width: size, height: size)
                }
                .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
            }
        }
    }
    
    private func modeSwitcher(isVertical: Bool) -> some View {
        GlassEffectContainer(spacing: 12) {
            Group {
                if isVertical {
                    // 横向きフルスクリーン: ボタンを縦に並べる
                    VStack(spacing: 16) {
                        ForEach(TimerMode.allCases, id: \.self) { mode in
                            Button(action: { onSwitchMode(mode) }) {
                                HStack(spacing: 16) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 28))
                                        .frame(width: 40)
                                    
                                    Text(mode.rawValue)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                                .foregroundStyle(timerMode == mode ? mode.color : .secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                            }
                            .glassEffect(
                                .regular.tint(timerMode == mode ? mode.color.opacity(0.15) : .gray.opacity(0.05)).interactive(),
                                in: .rect(cornerRadius: 18)
                            )
                        }
                    }
                } else {
                    // 縦向き/マルチウィンドウ: ボタンを横に並べる（iPhoneと同じ）
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
    }
}
