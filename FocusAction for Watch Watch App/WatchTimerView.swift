//
//  WatchTimerView.swift
//  FocusAction Watch App
//
//  Apple Watch専用のタイマーView
//

import SwiftUI
import SwiftData
import Combine

struct WatchTimerView: View {
    
    // SwiftDataのモデルコンテキストを取得
    @Environment(\.modelContext) private var modelContext
    
    @State private var isTimerRunning = false
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var totalTime: TimeInterval = 25 * 60
    @State private var timerMode: TimerMode = .focus
    @State private var sessionStartDate: Date? = nil  // セッション開始時刻を記録
    @State private var feedbackTrigger = 0  // 触覚フィードバック用
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            // モードインジケーター
            Text(timerMode.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 円形プログレスゲージ（Watch専用）
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerMode.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text(statusText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            
            // コントロールボタン
            HStack(spacing: 16) {
                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(timerMode.color)
                
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
            }
            
            // モード切り替え
            HStack(spacing: 8) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Button {
                        switchMode(to: mode)
                    } label: {
                        Image(systemName: mode.icon)
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(timerMode == mode ? mode.color : .gray)
                }
            }
        }
        .padding()
        .sensoryFeedback(.impact, trigger: feedbackTrigger)  // watchOS 10+の触覚フィードバック
        .onReceive(timer) { _ in
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if isTimerRunning && timeRemaining <= 0 {
                timerCompleted()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining / totalTime)
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var statusText: String {
        if isTimerRunning {
            return timerMode == .focus ? "集中中" : "休憩中"
        } else if timeRemaining <= 0 {
            return "完了"
        } else {
            return "準備完了"
        }
    }
    
    // MARK: - Timer Functions
    
    private func toggleTimer() {
        withAnimation {
            isTimerRunning.toggle()
        }
        
        // タイマー開始時に開始時刻を記録
        if isTimerRunning && sessionStartDate == nil {
            sessionStartDate = Date()
        }
        
        feedbackTrigger += 1  // 触覚フィードバックをトリガー
    }
    
    private func resetTimer() {
        withAnimation {
            isTimerRunning = false
            timeRemaining = totalTime
            sessionStartDate = nil  // 開始時刻もリセット
        }
        feedbackTrigger += 1
    }
    
    private func switchMode(to mode: TimerMode) {
        guard mode != timerMode else { return }
        
        withAnimation {
            timerMode = mode
            totalTime = mode.duration
            timeRemaining = mode.duration
            isTimerRunning = false
            sessionStartDate = nil  // 開始時刻もリセット
        }
        feedbackTrigger += 1
    }
    
    private func timerCompleted() {
        isTimerRunning = false
        feedbackTrigger += 1  // 触覚フィードバック
        
        // セッションを保存
        saveSession(isCompleted: true)
        
        // 次のモードに切り替え
        let nextMode: TimerMode = (timerMode == .focus) ? .shortBreak : .focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switchMode(to: nextMode)
        }
    }
    
    // MARK: - Data Persistence
    
    /// セッションをSwiftDataに保存する
    private func saveSession(isCompleted: Bool) {
        guard let startDate = sessionStartDate else {
            print("⚠️ [Watch] sessionStartDateがnilのため保存をスキップ")
            return
        }
        
        // 実際に経過した時間を計算
        let elapsedTime = totalTime - timeRemaining
        
        print("💾 [Watch] セッション保存: タイプ=\(timerMode.rawValue), 経過時間=\(elapsedTime)秒")
        
        // FocusSessionを作成
        let session = FocusSession(
            startDate: startDate,
            duration: elapsedTime,
            sessionType: timerMode == .focus ? .focus : .shortBreak,
            tags: ["Watch"],  // Watchから記録したことがわかるようにタグを追加
            isCompleted: isCompleted
        )
        
        // モデルコンテキストに追加
        modelContext.insert(session)
        
        // 保存を試行
        do {
            try modelContext.save()
            print("✅ [Watch] セッションを保存しました: \(session.formattedDuration)")
        } catch {
            print("❌ [Watch] セッション保存エラー: \(error.localizedDescription)")
        }
        
        // 開始時刻をリセット
        sessionStartDate = nil
    }
}

#Preview {
    WatchTimerView()
}
