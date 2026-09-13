# アーキテクチャ概要

## ターゲット構成

Xcode プロジェクトは3つの主要ターゲットで構成されています。

```
FocusAction.xcodeproj
├── FocusAction                          … iOS/iPadOS アプリ本体
├── FocusAction for Watch Watch App      … watchOS アプリ
└── (各ターゲットに対応する Tests / UITests)
```

`TimerMode.swift`、`FocusSession.swift`、`Tag.swift`、`PersistenceController.swift`、
`TimerSyncManager.swift`、`TimerViewModel.swift`、`Color+Hex.swift`、`TagChipView.swift` は
iOS と watchOS の両ターゲットに追加されている共通ファイルです。
各ファイル冒頭のコメントに「両方の Target に追加してください」という注記があるのはこのためで、
新規ファイル追加時は Target Membership の設定漏れに注意してください。

このプロジェクトは Xcode 16 の File System Synchronized Group を使っているため、`FocusAction/`
配下に置いたファイルは通常 iOS ターゲットにのみ自動で属する。watchOS ターゲットにも含めたい
ファイルは `project.pbxproj` の
`PBXFileSystemSynchronizedBuildFileExceptionSet`（"Exceptions for \"FocusAction\" folder in
"FocusAction for Watch Watch App" target"）の `membershipExceptions` に明示的に追加する必要がある。

> **落とし穴**: このリストはXcodeの独自plist形式（NeXTSTEP/OpenSTEP形式）で書かれており、
> ファイル名に `+` のような記号が含まれる場合は `"Views/Color+Hex.swift"` のように**クォートしないと
> プロジェクトファイルが壊れる**（`xcodebuild` が "damaged and cannot be opened due to a parse error"
> で失敗する）。テキストエディタで直接このリストを編集する際は要注意。

## ディレクトリ構成（iOS アプリ）

```
FocusAction/
├── App/
│   └── FocusActionApp.swift        … エントリポイント、ModelContainer の注入
├── Models/
│   ├── TimerMode.swift             … タイマーのモード定義（集中/休憩）※iOS/watchOS共通
│   ├── FocusSession.swift          … SwiftData の永続化モデル（セッション履歴）※iOS/watchOS共通
│   └── Tag.swift                   … SwiftData の永続化モデル（タグ: タイトル/絵文字/背景色）※iOS/watchOS共通
├── ViewModels/
│   └── TimerViewModel.swift        … タイマーの状態管理・進行ロジック・選択中タグの保持 ※iOS/watchOS共通
├── Services/
│   ├── PersistenceController.swift … CloudKit対応 ModelContainer の構築 ※iOS/watchOS共通
│   ├── TimerSyncManager.swift      … WatchConnectivity によるiPhone-Watch間の状態同期 ※iOS/watchOS共通
│   └── NotificationManager.swift   … ローカル通知の管理（iOS専用）
└── Views/
    ├── ControlView.swift           … TabView によるルートナビゲーション
    ├── TimerView.swift / +iPhone / +iPad … タイマー画面（サイズクラスで出し分け）
    ├── HistoryView.swift / +iPhone / +iPad … 履歴画面（サイズクラスで出し分け）
    ├── SettingView.swift           … 設定画面
    ├── Color+Hex.swift             … Tagの背景色(hex文字列)↔Colorの相互変換 ※iOS/watchOS共通・UIKit非依存
    ├── TagChipView.swift           … 絵文字＋背景色バッジ＋タイトルでタグを表示する部品 ※iOS/watchOS共通
    ├── TagPickerMenu.swift         … タグ選択Menu（iOS専用。TagChipViewをラップ）
    ├── TagManagementView.swift     … 設定画面から遷移するタグ一覧・作成・削除画面（iOS専用）
    └── TagEditView.swift           … タグの新規作成・編集フォーム（iOS専用）
```

watchOS アプリ側は以下の構成（`FocusAction for Watch Watch App/`）。

```
FocusAction for Watch Watch App/
├── FocusAction_for_WatchApp.swift  … エントリポイント。NavigationStackのルートに WatchTagListView を配置
├── WatchTagListView.swift          … 起動時のルート画面。タグ一覧＋タグ毎の集中時間合計を表示し、タップでWatchTimerViewへ遷移
└── WatchTimerView.swift            … タイマー画面。NavigationStackにpushされ、TimerViewModelは親から注入される
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
  watchOS 側は専用ターゲット内で `WatchTagListView`（ルート）→ `WatchTimerView`（push）という
  2画面のNavigationStackで対応する。

## watchOS の画面フロー

iOS 側はタイマー開始前に円の中の `TagPickerMenu` でタグを選べるが、watchOS は画面が小さくメニュー
UI を持ち込みにくいため、異なるフローを採用している。

1. アプリ起動時、ルートの `WatchTagListView` がタグ一覧（＋「タグなし」）をタグ毎の集中時間合計と
   ともに `List` 表示する。
2. 行をタップすると、その `Tag?` を渡しながら `WatchTimerView` へ `NavigationLink` で遷移する。
3. `WatchTimerView` は `.task` 内で `viewModel.selectedTag = initialTag` をセットしてからタイマーを
   開始できる状態になる。

`TimerViewModel` は `WatchTagListView` が `@StateObject` として保持し、`WatchTimerView` へは
`@ObservedObject` として注入する。これは `TimerSyncManager.shared.start(with:)` が
`TimerViewModel.init()` 内で呼ばれるため、画面を跨いでインスタンスが再生成されないようにする狙いが
ある（`WatchTagListView` はNavigationStackのルートとしてアプリのライフタイム中ずっとマウントされ
続けるため、ここに置けば従来通り単一インスタンスが保たれる）。watchOS ではタグの作成・編集はできず、
選択のみに限定している（絵文字入力や`ColorPicker`がwatchOSのSwiftUIには存在しないため）。
