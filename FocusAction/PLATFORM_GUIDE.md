# iPad & Apple Watch 対応ガイド

## 📱 iPad対応

### 実装した内容

1. **`horizontalSizeClass`の使用**
   - `@Environment(\.horizontalSizeClass)`でデバイスの画面サイズクラスを取得
   - iPadの場合は`.regular`、iPhoneの場合は`.compact`になる

2. **レスポンシブデザイン**
   - タイマーの円形プログレスバー: 320pt → 420pt（iPad）
   - フォントサイズ: 自動的に拡大
   - ボタンサイズ: 70pt → 80pt（iPad）
   - パディング: 20pt → 40pt（iPad）

3. **自動調整される要素**
   ```swift
   private var isLargeDevice: Bool {
       horizontalSizeClass == .regular
   }
   
   private var timerCircleSize: CGFloat {
       isLargeDevice ? 420 : 320
   }
   ```

### 追加設定（Xcodeで必要な作業）

#### 1. デプロイメントターゲットの設定
1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターでプロジェクトファイルを選択
3. **TARGETS** → **FocusAction** を選択
4. **General** タブ
5. **Deployment Info** → **Devices** で **"iPhone & iPad"** を選択

#### 2. iPadの向きの設定
- **Deployment Info** → **Device Orientation**で以下をチェック：
  - ✅ Portrait（縦向き）
  - ✅ Landscape Left（横向き左）
  - ✅ Landscape Right（横向き右）
  - ✅ Upside Down（逆さ - iPadのみ）

#### 3. Info.plistの設定（必要に応じて）
```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
</array>
```

#### 4. Split ViewとSlide Over対応
現在の実装は自動的に対応していますが、さらに最適化したい場合：

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass

var isCompactLayout: Bool {
    horizontalSizeClass == .compact || verticalSizeClass == .compact
}
```

---

## ⌚️ Apple Watch対応

### 新規作成したファイル

1. **`WatchTimerView.swift`**
   - Watch専用のシンプルなUIレイアウト
   - 小さな画面に最適化されたコントロール
   - WatchKit専用の触覚フィードバック（`WKInterfaceDevice`）

2. **`FocusActionWatchApp.swift`**
   - Watch App用のエントリーポイント
   - iOS版とは独立したアプリ

### Xcodeでの設定手順

#### 1. Watch App Targetの追加

1. **プロジェクトファイルを選択**
2. 画面下部の **"+"** ボタンをクリック（または Editor → Add Target）
3. **watchOS** タブを選択
4. **"Watch App"** を選択して **Next**
5. 設定：
   - **Product Name**: `FocusAction Watch App`
   - **Bundle Identifier**: `com.yourcompany.FocusAction.watchkitapp`
   - **Team**: あなたの開発チーム
   - **Watch Dependency**: 「Watch App for watchOS」を選択
   - **Include Notification Scene**: チェックを外してもOK
6. **Finish** をクリック
7. **Activate "FocusAction Watch App" scheme?** → **Activate**

#### 2. ファイルの配置

作成した以下のファイルをWatch App Targetに追加：

**Watch App専用ファイル:**
- `WatchTimerView.swift`
- `FocusActionWatchApp.swift`

**共有ファイル（両方のTargetに追加）:**
1. プロジェクトナビゲーターでファイルを選択
2. 右パネルの **Target Membership** セクション
3. iOSとwatchOS両方のTargetにチェック

共有すべきファイル:
- `TimerMode` enum（`TimerView.swift`から分離推奨）
- その他の共通モデル

#### 3. TimerModeを共有ファイルに分離（推奨）

`TimerMode.swift`を新規作成して、iOS/watchOS両方で使えるようにする：

```swift
//
//  TimerMode.swift
//  FocusAction
//
//  iOS/watchOS共通のモデル
//

import SwiftUI

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
```

このファイルの **Target Membership** で両方にチェックを入れる。

#### 4. Watch Schemeの設定

1. Xcode上部のスキーム選択メニューから **"FocusAction Watch App"** を選択
2. 横に表示されるデバイス選択から **Apple Watch Series X（XX mm）** を選択
3. または実機のApple Watchを接続して選択

#### 5. Assets（アイコン等）の設定

Watch App用のAssets.xcassetsを使用：
- **Watch App Icon**: 複数サイズが必要（Xcodeが自動でテンプレート作成）
- 推奨: 1024x1024の元画像を用意してApp Icon Generatorを使用

#### 6. Capabilitiesの設定（必要に応じて）

**iOSアプリ:**
- Background Modes → Background fetch（バックグラウンドでのタイマー更新用）

**Watch App:**
- Background Modes → Remote notifications（必要な場合）

#### 7. Watch Connectivityの実装（iOS ↔ Watch連携）

iOS版とWatch版でデータを同期したい場合は`WatchConnectivity`フレームワークを使用：

```swift
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // タイマー状態を送信
    func sendTimerState(mode: TimerMode, timeRemaining: TimeInterval, isRunning: Bool) {
        guard WCSession.default.isReachable else { return }
        
        let data: [String: Any] = [
            "mode": mode.rawValue,
            "timeRemaining": timeRemaining,
            "isRunning": isRunning
        ]
        
        WCSession.default.sendMessage(data, replyHandler: nil)
    }
    
    // デリゲートメソッド
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch Connectivity activated: \(activationState.rawValue)")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // メッセージ受信時の処理
        DispatchQueue.main.async {
            // UIを更新
        }
    }
}
```

---

## 🧪 テスト方法

### iPad
1. **Simulatorでテスト:**
   - スキームで「iPad Pro (12.9-inch)」などを選択
   - 実行してレイアウトを確認
   - デバイスの回転（⌘ + ← / →）をテスト

2. **Split ViewとSlide Overのテスト:**
   - Simulatorで別のアプリを起動
   - Split View状態でレイアウトを確認

### Apple Watch
1. **Simulatorでテスト:**
   - スキームで「FocusAction Watch App」を選択
   - デバイスで「Apple Watch Series 9 (45mm)」等を選択
   - 実行して動作確認

2. **実機でテスト:**
   - iPhoneとApple Watchをペアリング
   - Xcodeで実機を選択
   - Apple Watchにインストールして実行

---

## 📦 ビルド構成

最終的なプロジェクト構成:

```
FocusAction/
├── iOS App/
│   ├── FocusActionApp.swift
│   ├── ControlView.swift
│   ├── TimerView.swift (iPad対応済み)
│   ├── HistoryView.swift
│   ├── SettingView.swift
│   └── その他のiOS専用ファイル
│
├── Watch App/
│   ├── FocusActionWatchApp.swift
│   ├── WatchTimerView.swift
│   └── Assets.xcassets (Watch用)
│
└── Shared/ (推奨)
    ├── TimerMode.swift
    ├── FocusSession.swift (SwiftData)
    └── NotificationManager.swift (必要に応じて)
```

---

## 🎯 次のステップ

### 必須の設定
1. ✅ XcodeでWatch App Targetを追加
2. ✅ `TimerMode`を共有ファイルに分離
3. ✅ Target Membershipを正しく設定
4. ✅ Watch App用のアイコンを追加

### オプション機能
- [ ] Watch Connectivity実装（iOS ↔ Watch同期）
- [ ] Complication対応（Watch文字盤への表示）
- [ ] Live Activity（Dynamic Island対応）
- [ ] WidgetKit（ホーム画面ウィジェット）

---

## 🐛 よくある問題と解決方法

### iPad対応
**問題:** レイアウトが崩れる
- **解決:** `horizontalSizeClass`と`verticalSizeClass`の両方を確認
- Split View時は`horizontalSizeClass`が`.compact`になる場合がある

### Watch対応
**問題:** ビルドエラー「Module not found」
- **解決:** Target Membershipが正しく設定されているか確認
- Watch用とiOS用でインポートするフレームワークが異なる場合がある

**問題:** Watch Simulatorが起動しない
- **解決:** Xcode → Window → Devices and Simulators → Simulatorsでペアを再作成

---

## 📖 参考情報

### Apple公式ドキュメント
- [Supporting Multiple Windows on iPad](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/supporting_multiple_windows_on_ipad)
- [Building a watchOS App](https://developer.apple.com/documentation/watchos-apps)
- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)

### Size Classes
| Device | Orientation | Horizontal | Vertical |
|--------|-------------|------------|----------|
| iPhone | Portrait    | Compact    | Regular  |
| iPhone | Landscape   | Compact/Regular* | Compact |
| iPad   | Portrait    | Regular    | Regular  |
| iPad   | Landscape   | Regular    | Regular  |

*Plus/Max models: Regular

---

**作成日**: 2026-05-14  
**対応バージョン**: iOS 18+, watchOS 11+, Swift 6
