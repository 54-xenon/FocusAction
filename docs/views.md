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
- 円の中（`timerCircle`）は残り時間の下に、状態に応じて表示を切り替える:
  - `viewModel.isIdle`（未開始 or リセット後）のときは `TagPickerMenu` を表示し、タイマー開始前に
    セッションへ付けるタグを選べる。選択結果は `viewModel.selectedTag` に入り、`timerCompleted()` →
    `saveSession(isCompleted:)` で `FocusSession.tag` として保存される。
  - 実行中／完了時は従来通り `viewModel.statusText`（「集中...」「休憩中...」「完了！」）を表示する。

## HistoryView

- `@Query(sort: \FocusSession.startDate, order: .reverse) private var allSessions: [FocusSession]`
  で全セッションを、`@Query(sort: \Tag.createdAt) private var allTags: [Tag]` で全タグを取得する。
- フィルタは `FilterOption`（すべて／集中／休憩／完了済み）と `selectedTagID`（タグ絞り込み）の
  組み合わせで、`FocusSession.predicate(filterOption:tagID:)`（`HistoryView.swift` で定義した
  `FocusSession` の extension）が1つの複合 `Predicate` を生成し、`HistoryViewIPhone` /
  `HistoryViewIPad` の `@Query` にそのまま渡される。
- タグの絞り込みチップ列（`tagFilterChips`）は各 `*ViewIPhone` / `*ViewIPad` 側にそれぞれ実装されている
  （`filterButtons` と同じく、iPhone/iPad で見た目を独立にチューニングできるようにする既存方針を踏襲）。
- セッション削除は確認アラート（`showDeleteAlert`）を経由し、`deleteSession(_:)` で
  `modelContext.delete` → `save()`。タグの付け替えも同様に `HistoryView.changeTag(of:to:)` で
  `session.tag = newTag` → `save()` する。
- 共通コンポーネント:
  - `StatBox` — アイコン・値・単位・タイトルを表示する統計用のカード。
  - `SessionRow` / `SessionRowIPad` — 1件のセッションを表示する行。種別アイコン、時間範囲、完了バッジ、
    削除ボタンに加え、`TagPickerMenu(selected: session.tag, onSelect: onTagChange)` でその場でタグを
    付け替えられる。

## SettingView

- 通知セクション: `NotificationManager.shared` を `@ObservedObject` で購読し、許可状態の表示・
  許可リクエスト・テスト通知送信（5秒後）を行う。
- タグセクション: `NavigationLink` で `TagManagementView` に遷移する入り口のみを持つ。
- アプリ情報セクション: `CFBundleShortVersionString` からバージョン表示、現在のカラースキーム表示。
- ダークモード自体の切り替えは提供せず、システム設定に追従する仕様（README にも明記）。

## タグ関連コンポーネント

タグ機能（タイトル・絵文字・背景色を持つ `Tag` をセッションに1つ紐付ける機能）を構成する部品群。

- `Color+Hex.swift` — `Tag.colorHex`（`#RRGGBB` の `String`）と SwiftUI `Color` を相互変換する
  extension。`Color.resolve(in:)` のみを使い `UIColor`（UIKit）に依存しないため、iOS/watchOS
  両方で共有できる。
- `TagChipView` — `Tag?` を受け取り、絵文字＋背景色の丸バッジとタイトルを表示する最小単位の部品。
  `tag == nil` のときは「タグなし」のグレー表示になる。iOS/watchOS共通。
- `TagPickerMenu`（iOS専用） — `@Query(sort: \Tag.createdAt)` で全タグを取得し、`Menu` として
  「タグなし」＋各タグを一覧表示する。ラベルには `TagChipView` を使う。`TimerView`（開始前選択）と
  `SessionRow` / `SessionRowIPad`（履歴での後付け編集）の両方から使い回している。
- `TagManagementView`（iOS専用） — `SettingView` から遷移するタグ一覧・作成・削除画面。
  `.onDelete` で削除すると、`FocusSession.tag` は `@Relationship(deleteRule: .nullify)` により
  自動的に `nil` へ戻る。
- `TagEditView`（iOS専用） — タグの新規作成・編集フォーム。タイトルの `TextField`、絵文字の
  `TextField`（入力を1文字目にクランプする簡易実装）、背景色の `ColorPicker` を持つ。プレビュー行に
  現在の入力内容を `TagChipView` でその場表示する。

## Watch アプリ: WatchTagListView / WatchTimerView

Watch 側は2画面の `NavigationStack` で構成される（ルート: `WatchTagListView`、push先:
`WatchTimerView`）。`TimerViewModel` は `WatchTagListView` が `@StateObject` として保持し、
`WatchTimerView` へは `@ObservedObject` で注入する（詳細は [アーキテクチャ概要](./architecture.md)
の「watchOS の画面フロー」を参照）。

### WatchTagListView（ルート）

- `@Query(sort: \Tag.createdAt) private var tags: [Tag]` と全セッションから、「タグなし」＋各タグの
  行を `List` 表示する。各行には `TagChipView` と、そのタグが付いた集中セッションの合計時間
  （`focusMinutes(for:)`、"○○分"表記）を表示する。
- 行をタップすると `NavigationLink` で `WatchTimerView(viewModel:initialTag:)` へ遷移する。
- `.onChange(of: scenePhase)` によるバックグラウンド復帰時の経過時間補正と、`.task` での
  `viewModel.modelContext` 注入は、（画面遷移してもルートとしてマウントされ続ける）このView側で行う。
- watchOS では新規タグ作成・編集はできない（iPhone側の `TagManagementView` / `TagEditView` でのみ
  可能）。CloudKit同期でiPhone側のタグが反映されるのを待つ形になる。

### WatchTimerView（push先）

- 円形プログレスバー（`Circle().trim(from:to:)`）で残り時間を表示。
- 四隅に配置したボタン（左上: 集中モード、右上: 休憩モード、左下: リセット、右下: 再生/一時停止）。
- `.sensoryFeedback(.impact, trigger: feedbackTrigger)` … 各ボタン操作時に触覚フィードバック。
- `.sensoryFeedback(.success, trigger: viewModel.completionCount)` … タイマー完了時に成功フィードバック。
- 円の中、残り時間の下には（iOS版のステータステキストの代わりに）常に
  `TagChipView(tag: viewModel.selectedTag, font: .caption2)` を表示する。画面が小さくタグと状態の
  両方を表示する余地がないため、watchOS では状態テキストより選択中タグの表示を優先している。
- `.task` で `viewModel.selectedTag = initialTag` をセットし、`WatchTagListView` から渡された
  タグを選択済みの状態にしてから表示する。
- iOS 版と同じ `TimerViewModel` を使うため、モード切替・リセット・開始/一時停止のロジックは共通。

## 今後実装予定（README より）

- 設定画面でのタイマー時間カスタマイズ、通知設定、サウンド設定
- 長い休憩モード（15分）の追加
- ウィジェット対応
