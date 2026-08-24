# 画面構成

## ナビゲーション: ControlView

`ControlView`（`FocusAction/Views/ControlView.swift`）がルートで、`TabView` により3つのタブを
提供する。`.tabViewStyle(.sidebarAdaptable)` により iPadOS では自動的にサイドバー表示に切り替わる。

| タブ | View | アイコン |
|---|---|---|
| Timer | `TimerView` | `timer` |
| History | `HistoryView` | `chart.bar` |
| Settings | `SettingView` | `gearshape` |

## サイズクラスによる出し分け

`TimerView` と `HistoryView` はどちらも `@Environment(\.horizontalSizeClass)` を見て、
`.regular`（iPad 等）であれば `*ViewIPad`、それ以外（iPhone 等）であれば `*ViewIPhone` の
サブビューへ処理を委譲する共通パターンを採用している。

```swift
Group {
    if horizontalSizeClass == .regular {
        TimerViewIPad(viewModel: viewModel)
    } else {
        TimerViewIPhone(viewModel: viewModel)
    }
}
```

- `TimerView.swift` … 分岐のみを行うコンテナ。`TimerView+iPhone.swift` / `TimerView+iPad.swift` に
  実際のレイアウトがある。
- `HistoryView.swift` … 同様の分岐に加え、`@Query` によるデータ取得、削除確認アラート、
  `StatBox` / `SessionRow` などの共通コンポーネントを持つ。`HistoryView+iPhone.swift` /
  `HistoryView+iPad.swift` に実際のレイアウトがある。

## TimerView

- `@StateObject private var viewModel = TimerViewModel()` でタイマー状態を保持。
- `.task` で `viewModel.modelContext` に環境の `ModelContext` を注入し、通知の許可状態を確認・
  リクエストする。
- `.onChange(of: scenePhase)` で `viewModel.handleScenePhaseChange` を呼び、バックグラウンド／
  フォアグラウンド遷移時の経過時間補正をトリガーする。

## HistoryView

- `@Query(sort: \FocusSession.startDate, order: .reverse) private var allSessions: [FocusSession]`
  で全セッションを取得（フィルタは `FilterOption` を使ってビュー側で適用）。
- `FilterOption`（すべて／集中／休憩／完了済み）はそれぞれ `FocusSession` の `Predicate` ヘルパーに
  対応する。
- セッション削除は確認アラート（`showDeleteAlert`）を経由し、`deleteSession(_:)` で
  `modelContext.delete` → `save()`。
- 共通コンポーネント:
  - `StatBox` — アイコン・値・単位・タイトルを表示する統計用のカード。
  - `SessionRow` — 1件のセッションを表示する行。種別アイコン、時間範囲、完了バッジ、削除ボタン。

## SettingView

- 通知セクション: `NotificationManager.shared` を `@ObservedObject` で購読し、許可状態の表示・
  許可リクエスト・テスト通知送信（5秒後）を行う。
- アプリ情報セクション: `CFBundleShortVersionString` からバージョン表示、現在のカラースキーム表示。
- ダークモード自体の切り替えは提供せず、システム設定に追従する仕様（README にも明記）。

## Watch アプリ: WatchTimerView

`FocusAction for Watch Watch App/WatchTimerView.swift` が Watch 側の唯一の画面。

- 円形プログレスバー（`Circle().trim(from:to:)`）で残り時間を表示。
- 四隅に配置したボタン（左上: 集中モード、右上: 休憩モード、左下: リセット、右下: 再生/一時停止）。
- `.sensoryFeedback(.impact, trigger: feedbackTrigger)` … 各ボタン操作時に触覚フィードバック。
- `.sensoryFeedback(.success, trigger: viewModel.completionCount)` … タイマー完了時に成功フィードバック。
- iOS 版と同じ `TimerViewModel` を使うため、モード切替・リセット・開始/一時停止のロジックは共通。

## 今後実装予定（README より）

- 設定画面でのタイマー時間カスタマイズ、通知設定、サウンド設定
- 長い休憩モード（15分）の追加
- ウィジェット対応
