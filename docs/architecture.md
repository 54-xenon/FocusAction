# アーキテクチャ概要

## ターゲット構成

Xcode プロジェクトは3つの主要ターゲットで構成されています。

```
FocusAction.xcodeproj
├── FocusAction                          … iOS/iPadOS アプリ本体
├── FocusAction for Watch Watch App      … watchOS アプリ
├── FocusActionWidgetExtension           … Live Activity / Dynamic Island（iOS専用、アプリに埋め込み）
└── (各ターゲットに対応する Tests / UITests)
```

`TimerMode.swift`、`TimerState.swift`、`FocusSession.swift`、`Tag.swift`、`PersistenceController.swift`、
`TimerSyncManager.swift`、`TimerStore.swift`、`TimerEvent.swift`、`Color+Hex.swift`、`TagChipView.swift` は
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

## Live Activity / Dynamic Island（iOS専用）

- `FocusAction/LiveActivity/FocusActivityAttributes.swift` … `ActivityAttributes` 定義。アプリ本体と
  `FocusActionWidgetExtension` の両方に属する（`TimerMode.swift`・`Color+Hex.swift` もExtensionと共有）。
  Extension 側へのメンバーシップは "Exceptions for \"FocusAction\" folder in \"FocusActionWidgetExtension\" target" で管理。
- `FocusAction/LiveActivity/LiveActivityManager.swift` … `LiveActivityTimerEventHandler`（`TimerEventHandlers.swift`）から呼ばれ、タイマー開始で
  Activity を開始、一時停止/再開で更新、リセット・モード切替・完了で終了する。
- `FocusActionWidget/FocusLiveActivity.swift` … ロック画面と Dynamic Island（expanded / compact / minimal）のUI。
  `.supplementalActivityFamilies([.small])` により Apple Watch の Smart Stack にも表示される（`.small` 用レイアウトは `WatchView`）。
  プログレスバーは TimerView の円と同じ 20pt。カスタム描画では実行中に進捗が進まないため、標準の linear ProgressView を `scaleEffect` で太くしている。
  実行中は `Text(timerInterval:)` で終了時刻までシステムがカウントダウンするため、アプリがバックグラウンドでも表示が進む。
- アプリ側の Info.plist には `NSSupportsLiveActivities = YES` をビルド設定（`INFOPLIST_KEY_NSSupportsLiveActivities`）で付与している。

## ホーム画面 / ロック画面 Widget（iOS専用）

`FocusActionWidgetExtension` に「タイマー」と「履歴」の2種類の Widget がある。

- Widget は別プロセスのため SwiftData ストアを直接読まない。アプリが App Group
  （`group.com.keito.FocusAction`）の UserDefaults にスナップショットを書き込み、Widget はそれを読むだけ。
- `FocusAction/Widget/WidgetSharedData.swift` … 共有データ型（`TimerWidgetState` / `HistoryWidgetSummary`）と読み書き。
  アプリと Extension の両方に属する。
- `FocusAction/Widget/WidgetDataWriter.swift` … アプリ側で書き込み + `WidgetCenter.reloadTimelines` を呼ぶ。
  - タイマー: `WidgetTimerEventHandler` が `TimerStore` の開始/一時停止/リセット/モード切替/タグ変更イベントを受けたとき
  - 履歴: セッション保存（`.sessionSaved` イベント）・削除時、アプリ起動時とアクティブ復帰時（CloudKit で他端末の履歴が増えている場合に備える）
- `FocusActionWidget/TimerWidget.swift` … small / medium / ロック画面（circular・rectangular・inline）。
  終了予定時刻に「完了」表示へ切り替わるエントリを積むので、アプリが起動していなくても表示が進む。
- `FocusActionWidget/HistoryWidget.swift` … small / medium（直近7日間の棒グラフ）/ ロック画面（rectangular・inline）。
  集計は HistoryView の統計（今日/今週/合計）と同じ基準。日付が変わったら Widget 側で「今日」を0にリセットして表示する。
- 他端末で記録した履歴は、このiPhoneでアプリを開くまで Widget に反映されない。

## ディレクトリ構成（iOS アプリ）

```
FocusAction/
├── App/
│   └── FocusActionApp.swift        … エントリポイント。ModelContainer と TimerStore の生成・注入、scenePhase の監視
├── Models/
│   ├── TimerMode.swift             … タイマーのモード定義（集中/休憩）※iOS/watchOS共通
│   ├── TimerState.swift            … タイマーの状態と進行ロジック（副作用なし・単体テスト対象）※iOS/watchOS共通
│   ├── FocusSession.swift          … SwiftData の永続化モデル（セッション履歴）※iOS/watchOS共通
│   └── Tag.swift                   … SwiftData の永続化モデル（タグ: タイトル/絵文字/背景色）※iOS/watchOS共通
├── Stores/
│   ├── TimerStore.swift            … アプリ全体で1つのタイマー状態（@Observable）。TimerState の保持・tick・セッション保存・イベント発行 ※iOS/watchOS共通
│   └── TimerEvent.swift            … TimerEvent / TimerEventHandler プロトコル（副作用の注入口）※iOS/watchOS共通
├── Services/
│   ├── PersistenceController.swift … CloudKit対応 ModelContainer の構築 ※iOS/watchOS共通
│   ├── TimerSyncManager.swift      … WatchConnectivity によるiPhone-Watch間の状態同期 ※iOS/watchOS共通
│   ├── NotificationManager.swift   … ローカル通知の管理（iOS専用）
│   └── TimerEventHandlers.swift    … 通知・Live Activity・Watch送信・Widget の TimerEventHandler 実装（iOS専用）
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
├── FocusAction_for_WatchApp.swift  … エントリポイント。TimerStore を生成して配り、NavigationStackのルートに WatchTagListView を配置
├── WatchTagListView.swift          … 起動時のルート画面。タグ一覧＋タグ毎の集中時間合計を表示し、タップでWatchTimerViewへ遷移
└── WatchTimerView.swift            … タイマー画面。NavigationStackにpushされ、TimerStoreは environment から受け取る
```

## レイヤー設計

```
View (SwiftUI)
  └─ @Observable: TimerStore（App で1つ生成し .environment で配布）── TimerState（副作用なしのロジック）
       │  TimerEvent
       ├─ [TimerEventHandler]（iOS のみ注入）
       │    ├─ NotificationTimerEventHandler  → NotificationManager
       │    ├─ LiveActivityTimerEventHandler  → LiveActivityManager
       │    ├─ WatchSyncTimerEventHandler     → TimerSyncManager
       │    └─ WidgetTimerEventHandler        → WidgetDataWriter
       └─ SwiftData ModelContext ─┬─ ローカルストア
                                   └─ CloudKit（プライベートDB）
```

- **View 層**: `@Environment(TimerStore.self)` で `TimerStore` を受け取り、`horizontalSizeClass` によって
  iPhone 向け／iPad 向けのサブビューを切り替える（例: `TimerView` → `TimerViewIPhone` / `TimerViewIPad`）。
- **Store 層**: `TimerStore` が `TimerState`（Model）を保持し、タイマー購読とセッション保存を行う。
  状態が変わると `TimerEvent`（開始・一時停止・リセット・モード切替・完了・タグ変更・セッション保存）を
  発行し、通知・Live Activity・Widget 更新・Watch への状態送信は注入された `TimerEventHandler` が担う。
  カウントダウン、モード切替、バックグラウンド復帰時の経過時間補正などの計算は `TimerState` 側にある。
  `TimerState` は現在時刻を引数で、`TimerStore` は現在時刻を返す関数を init で受け取るため、
  どちらも `FocusActionTests` で単体テストしている。iOS と watchOS の両方で共有され、
  `#if os` による分岐は持たない（プラットフォームの違いは注入するハンドラと `isFromWatch` で表す）。
- **Service 層**:
  - `PersistenceController` — SwiftData の `ModelContainer` を CloudKit 対応で構築し、失敗時は
    ローカルのみのストアにフォールバックする。
  - `TimerSyncManager` — iPhone 側で変化したタイマー状態を `WCSession.updateApplicationContext`
    で Watch に送信し、Watch 側はそれを受信してタイマー表示に反映する。
  - `NotificationManager` — タイマー完了時刻のローカル通知をスケジュール／キャンセルする（iOS専用）。

## 状態管理

- タイマーはアプリ全体の状態なので、`@Observable` の `TimerStore` を App が `@State` で1つだけ生成し、
  `.environment` で配る。View は `@Environment(TimerStore.self)` で読む。タブの切り替えや、折りたたみ端末の
  開閉による Compact ⇄ Regular のレイアウト切り替えで View が作り直されても、タイマーの状態は保たれる。
- 保存先の `ModelContext` は、ルートの `.modelContainer` が環境に入れるものと同じ
  `PersistenceController.sharedModelContainer.mainContext` を `TimerStore` の init で渡す。
- フォアグラウンド復帰時の再計算は App の `.onChange(of: scenePhase)` から `TimerStore.handleScenePhaseChange` を呼ぶ。
- 履歴・タグの一覧は View が SwiftData の `@Query` で直接取得する（Store を挟まない）。
- タイマーの定期更新は `Task` のループ（`Task.sleep(for: .milliseconds(250))`）で行う。
- `NotificationManager` は `ObservableObject` のまま、`SettingView` が `@ObservedObject` で購読している。
- グローバルな共有状態が必要なサービス（`PersistenceController`, `TimerSyncManager`,
  `NotificationManager`）はシングルトン（`static let shared` / `static let sharedModelContainer`）
  として実装されている。

## プラットフォーム分岐の方針

- 共通ロジックは `TimerState` / `TimerStore` に置き、プラットフォーム専用 API（通知、
  Live Activity、Widget、Watch への送信）は `TimerEventHandler` として iOS ターゲットに実装する。
  iOS の App は `TimerStore(modelContext:eventHandlers: TimerEventHandlers.live())`、watchOS の App は
  `TimerStore(modelContext:isFromWatch: true)`（ハンドラなし）で生成する。
- WatchConnectivity の送受信方向など、`TimerSyncManager` 内部の分岐は `#if os(iOS)` / `#if os(watchOS)` で切り分ける。
- 画面レイアウトはターゲットを分けず、iOS 側は `horizontalSizeClass`（iPhone/iPad）で、
  watchOS 側は専用ターゲット内で `WatchTagListView`（ルート）→ `WatchTimerView`（push）という
  2画面のNavigationStackで対応する。

## watchOS の画面フロー

iOS 側は円の中の `TagPickerMenu` でタグを選べる（開始前だけでなく実行中も変更できる）が、watchOS は画面が小さくメニュー
UI を持ち込みにくいため、異なるフローを採用している。

1. アプリ起動時、ルートの `WatchTagListView` がタグ一覧（＋「タグなし」）をタグ毎の集中時間合計と
   ともに `List` 表示する。
2. 行をタップすると、その `Tag?` を渡しながら `WatchTimerView` へ `NavigationLink` で遷移する。
3. `WatchTimerView` は `.task` 内で `timerStore.selectedTag = initialTag` をセットしてからタイマーを
   開始できる状態になる。

`TimerStore` は watchOS の App が `@State` で1つだけ生成し、`.environment` で配る。
`TimerSyncManager.shared.start(with:)` もルートの `.task` で呼ぶため、iPhone からの状態を受信する
インスタンスは画面遷移をまたいでも変わらない。watchOS ではタグの作成・編集はできず、
選択のみに限定している（絵文字入力や`ColorPicker`がwatchOSのSwiftUIには存在しないため）。
