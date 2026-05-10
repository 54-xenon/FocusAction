//
//  ContentView.swift
//  FocusAction
//
//

// 必要なパッケージをあらかじめインポート
import SwiftUI
import Combine
import SwiftData

struct TimerView: View {

    // SwiftDataのモデルコンテキストを取得
    @Environment(\.modelContext) private var modelContext
    
    // State関数 -> Viewに対して状態をもたせる(UIに動きをつけることができる)
    @State private var isTimerRunning = false   // タイマーが動いているかどうか(bool: false -> 動いていない)
    @State private var timeRemaining: TimeInterval = 25 * 60 // 25分(残り時間)
    @State private var totalTime: TimeInterval = 25 * 60 // 総時間
    @State private var timerMode: TimerMode = .focus    // 現在のモード
    @State private var sessionStartDate: Date? = nil // セッション開始時刻を記録
    
    // CombineフレームワークのTimer.publishを使用(使えるようにインスタンス化)
        // -> 1秒ごとにイベントを発行、自動的に接続(タイマーは1秒ごとに進み、その都度状態を更新する必要があるため)
        // everyプロパティを1にすることで、1秒おきに設定している
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // UI部分 -> 実際に表示される文字や円形んプログレスバーを宣言的なコードで記述する
    var body: some View {
        ZStack {
            // 背景を白に
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // タイマーモード表示
                Text(timerMode.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                // 円形プログレスバー with Liquid Glass
                ZStack {
                    // 背景の円
                    Circle()
                        .stroke(
                            Color.gray.opacity(0.15),
                            lineWidth: 20
                        )
                    
                    // プログレスを示す円（青系）
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timerMode.color,
                            style: StrokeStyle(
                                lineWidth: 20,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    // 中央のタイマー表示 with Liquid Glass
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
                
                Spacer()
                
                // コントロールボタン
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        // 再生/一時停止ボタン
                        Button(action: toggleTimer) {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(timerMode.color)
                                .frame(width: 70, height: 70)
                        }
                        .glassEffect(.regular.tint(timerMode.color.opacity(0.2)).interactive(), in: .circle)
                        
                        // リセットボタン
                        Button(action: resetTimer) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                                .frame(width: 70, height: 70)
                        }
                        .glassEffect(.regular.tint(.gray.opacity(0.1)).interactive(), in: .circle)
                    }
                }
                
                // モード切り替えボタン
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(TimerMode.allCases, id: \.self) { mode in
                            Button(action: { switchMode(to: mode) }) {
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
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
        }
        // タイマー処理で、1秒ずず値を減らしている
        .onReceive(timer) { _ in
            // 0以上の値の時 -> 残り時間がある間はデクリメントメソッドを繰り返し行う
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                // 残り時間がゼロになるとタイマーを止める
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
            return "集中..."
        } else if timeRemaining == 0 {
            return "完了！"
        } else {
            return "タップして開始"
        }
    }
    
    // MARK: - Timer Functions
    
    private func toggleTimer() {
        withAnimation(.spring(response: 0.3)) {
            isTimerRunning.toggle()
            
            // タイマー開始時に開始時刻を記録
            if isTimerRunning && sessionStartDate == nil {
                sessionStartDate = Date()
            }
        }
    }
    
    private func resetTimer() {
        withAnimation {
            isTimerRunning = false
            timeRemaining = totalTime
            sessionStartDate = nil // 開始時刻もリセット
        }
    }
    
    private func switchMode(to mode: TimerMode) {
        guard mode != timerMode else { return }
        
        withAnimation {
            timerMode = mode
            totalTime = mode.duration
            timeRemaining = mode.duration
            isTimerRunning = false
            sessionStartDate = nil // モード切替時は開始時刻をリセット
        }
    }
    
    private func timerCompleted() {
        isTimerRunning = false
        
        // セッションをSwiftDataに保存
        saveSession(isCompleted: true)
        
        // 完了時の処理（通知、サウンドなど）
        
        
        // 自動的に次のモードへ切り替え
        withAnimation {
            switch timerMode {
            case .focus:
                switchMode(to: .shortBreak)
            case .shortBreak:
                switchMode(to: .focus)
            }
        }
    }
    
    // MARK: - Data Persistence
    
    /// セッションをSwiftDataに保存する
    private func saveSession(isCompleted: Bool) {
        guard let startDate = sessionStartDate else { return }
        
        // 実際に経過した時間を計算
        let elapsedTime = totalTime - timeRemaining
        
        // FocusSessionを作成
        let session = FocusSession(
            startDate: startDate,
            duration: elapsedTime,
            sessionType: timerMode == .focus ? .focus : .shortBreak,
            tags: [], // 必要に応じてタグを追加できる
            isCompleted: isCompleted
        )
        
        // モデルコンテキストに追加
        modelContext.insert(session)
        
        // 保存を試行
        do {
            try modelContext.save()
            print("✅ セッションを保存しました: \(session.formattedDuration)")
        } catch {
            print("❌ セッション保存エラー: \(error.localizedDescription)")
        }
        
        // 開始時刻をリセット
        sessionStartDate = nil
    }
}

// MARK: - Timer Mode Enum

enum TimerMode: String, CaseIterable {
    case focus = "集中"
    case shortBreak = "休憩"
    
    var duration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return .blue
        case .shortBreak: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        }
    }
    
    var title: String {
        switch self {
        case .focus: return "集中タイム"
        case .shortBreak: return "休憩タイム"
        }
    }
}

#Preview {
    TimerView()
        
}
