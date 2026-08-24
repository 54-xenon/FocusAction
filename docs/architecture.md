# アーキテクチャ概要

## ターゲット構成

Xcode プロジェクトは3つの主要ターゲットで構成されています。

```
FocusAction.xcodeproj
├── FocusAction                          … iOS/iPadOS アプリ本体
├── FocusAction for Watch Watch App      … watchOS アプリ
└── (各ターゲットに対応する Tests / UITests)
```

`TimerMode.swift`、`FocusSession.swift`、`PersistenceController.swift`、`TimerSyncManager.swift`、
`TimerViewModel.swift` は iOS と watchOS の両ターゲットに追加されている共通ファイルです。
各ファイル冒頭のコメントに「両方の Target に追加してください」という注記があるのはこのためで、
新規ファイル追加時は Target Membership の設定漏れに注意してください。

## ディレクトリ構成（iOS アプリ）

```
FocusAction/
├── App/
│   └── FocusActionApp.swift        … エントリポイント、ModelContainer の注入
├── Models/
│   ├── TimerMode.swift             … タイマーのモード定義（集中/休憩）※iOS/watchOS共通
│   └── FocusSession.swift          … SwiftData の永続化モデル（セッション履歴）※iOS/watchOS共通
├── ViewModels/
│   └── TimerViewModel.swift        … タイマーの状態管理・進行ロジック ※iOS/watchOS共通
├── Services/
│   ├── PersistenceController.swift … CloudKit対応 ModelContainer の構築 ※iOS/watchOS共通
│   ├── TimerSyncManager.swift      … WatchConnectivity によるiPhone-Watch間の状態同期 ※iOS/watchOS共通
│   └── NotificationManager.swift   … ローカル通知の管理（iOS専用）
└── Views/
    ├── ControlView.swift           … TabView によるルートナビゲーション
    ├── TimerView.swift / +iPhone / +iPad … タイマー画面（サイズクラスで出し分け）
    ├── HistoryView.swift / +iPhone / +iPad … 履歴画面（サイズクラスで出し分け）
    └── SettingView.swift           … 設定画面
```

## レイヤー設計

```
View (SwiftUI)
  └─ ObservableObject: TimerViewModel / NotificationManager
       └─ Services: TimerSyncManager, PersistenceController
            └─ SwiftData ModelContext ─┬─ ローカルストア
                                        └─ CloudKit（プライベートDB）
```

- **View 層**: `@StateObject` で `TimerViewModel` を保持し、`horizontalSizeClass` によって
  iPhone 向け／iPad 向けのサブビューを切り替える（例: `TimerView` → `TimerViewIPhone` / `TimerViewIPad`）。
- **ViewModel 層**: `TimerViewModel` がタイマーのカウントダウン、モード切替、バックグラウンド復帰時の
  経過時間補正、セッション保存、Watch への状態送信までを一手に担う。iOS と watchOS の両方で
  共有され、`#if os(iOS)` / `#if os(watchOS)` でプラットフォーム固有処理を分岐している。
- **Service 層**:
  - `PersistenceController` — SwiftData の `ModelContainer` を CloudKit 対応で構築し、失敗時は
    ローカルのみのストアにフォールバックする。
  - `TimerSyncManager` — iPhone 側で変化したタイマー状態を `WCSession.updateApplicationContext`
    で Watch に送信し、Watch 側はそれを受信してタイマー表示に反映する。
  - `NotificationManager` — タイマー完了時刻のローカル通知をスケジュール／キャンセルする（iOS専用）。

## 状態管理

- `@Published` プロパティを持つ `ObservableObject`（`TimerViewModel`, `NotificationManager`）を
  SwiftUI の `@StateObject` / `@ObservedObject` で購読する、標準的な MVVM 構成。
- タイマーの定期更新には Combine の `Timer.publish(every: 1, on: .main, in: .common)` を使用。
- グローバルな共有状態が必要なサービス（`PersistenceController`, `TimerSyncManager`,
  `NotificationManager`）はシングルトン（`static let shared` / `static let sharedModelContainer`）
  として実装されている。

## プラットフォーム分岐の方針

- 共通ロジックは `TimerViewModel` に置き、UI 依存部分やプラットフォーム専用 API（通知、
  WatchConnectivity の送受信方向など）は `#if os(iOS)` / `#if os(watchOS)` で切り分ける。
- 画面レイアウトはターゲットを分けず、iOS 側は `horizontalSizeClass`（iPhone/iPad）で、
  watchOS 側は専用ターゲットの `WatchTimerView` で対応する。
