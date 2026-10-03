# 2026-10-02〜03 Live Activity / Dynamic Island / Widget 対応

ブランチ: `feature/addFunction`

## 実施内容

1. Live Activity / Dynamic Island 対応（iOSのみ）
2. Live Activity・Dynamic Island のプログレスバーを TimerView の円と同じ太さ（20pt）に変更
3. Live Activity を Apple Watch の Smart Stack にも表示
4. アプリアイコンを Icon Composer の `FocusActionICON.icon` に設定
5. ホーム画面 / ロック画面ウィジェット（タイマー・履歴）を追加
6. README・docs の更新

## 追加・変更したファイル

| ファイル | 内容 |
|---|---|
| `FocusActionWidget/`（新ターゲット `FocusActionWidgetExtension`） | Widget Extension。`FocusLiveActivity.swift` / `TimerWidget.swift` / `HistoryWidget.swift` / `FocusActionWidgetBundle.swift` |
| `FocusAction/LiveActivity/FocusActivityAttributes.swift` | `ActivityAttributes` 定義。アプリと Extension の両方に属する |
| `FocusAction/LiveActivity/LiveActivityManager.swift` | Live Activity の開始・更新・終了 |
| `FocusAction/Widget/WidgetSharedData.swift` | App Group 経由で共有するデータ型と読み書き。アプリと Extension の両方に属する |
| `FocusAction/Widget/WidgetDataWriter.swift` | Widget 用データの書き込み + `reloadTimelines` |
| `FocusAction/ViewModels/TimerViewModel.swift` | 上記マネージャー/ライターの呼び出し（すべて `#if os(iOS)` 内） |
| `FocusAction/Views/TimerView.swift`, `HistoryView.swift` | 起動時・アクティブ復帰時・セッション削除時に履歴集計を更新 |
| `FocusAction/FocusAction.entitlements`, `FocusActionWidget/FocusActionWidget.entitlements` | App Group `group.com.keito.FocusAction` |
| `FocusAction.xcodeproj/project.pbxproj` | Extension ターゲット追加、`NSSupportsLiveActivities = YES`、App Icon 設定 |

## 決定事項と理由

- **Live Activity のライフサイクル**: タイマー開始で Activity 開始、一時停止/再開で更新、リセット・モード切替・完了で終了。
  実行中は `Text(timerInterval:)` / `ProgressView(timerInterval:)` を使い、アプリがバックグラウンドでもシステム側で表示を進める。
- **プログレスバーの太さ**: カスタム描画では Live Activity / Widget 上で実行中に進捗が進まないため、
  標準の linear `ProgressView` を `scaleEffect` で縦に拡大して 20pt にしている。トラックの色はシステム標準のまま。
- **Apple Watch 対応**: Watch 専用ターゲットは作らず、`.supplementalActivityFamilies([.small])` で
  iPhone の Live Activity を Smart Stack に出す。`.small` 用に `WatchView`（バーは 8pt）を用意。
- **Widget のデータ共有**: Widget は別プロセスで SwiftData ストアを直接読めない。ストアを App Group へ移すのは
  既存データ移行のリスクがあるため見送り、アプリが App Group の UserDefaults にスナップショット
  （`TimerWidgetState` / `HistoryWidgetSummary`）を書き込む方式にした。
  - トレードオフ: 他端末で記録した履歴は、このiPhoneでアプリを開くまで Widget に反映されない。
- **履歴 Widget の集計基準**: HistoryView の統計（今日/今週/合計）と同じ計算。日付が変わったら Widget 側で「今日」を0にリセットする。
- **曜日表示**: Extension は日本語ローカライズを持たず曜日が英語になったため、`ja_JP` の `DateFormatter` で明示的に表示。

## トラブル対応

- **アプリアイコンが設定できない**: iOS ターゲットの `ASSETCATALOG_COMPILER_APPICON_NAME` が空になっていた。
  `.icon` はプロジェクトに追加するだけでは使われず、App Icon 設定に拡張子なしの名前（`FocusActionICON`）を指定する必要がある。
  iOS / watchOS 両ターゲットに設定した。
- **シミュレータでのスクリーンショット**: `xcrun simctl io booted screenshot` が "Timeout waiting for screen surfaces" で失敗。
  一時的な UI テストから `XCUIScreen.main.screenshot()` を書き出す方法で確認した（`-parallel-testing-enabled NO` が必要。
  付けないとクローンのシミュレータで実行される）。
- **`MainActor` デフォルト分離**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` のため、`ActivityAttributes` や Widget 共有データ型は
  `nonisolated` を付けて定義している。

## 動作確認

- iOS アプリ（Extension 込み）と watchOS アプリのビルド成功。
- シミュレータで Dynamic Island の展開表示・コンパクト表示、太くしたプログレスバー、ホーム画面アイコン、
  履歴 Widget（中）、App Group へのデータ書き込みを確認。
- コンパクト表示、タイマー Widget、Apple Watch 表示を含む全体の動作はユーザーが確認済み。

## 今後の候補

- Widget タップ時にタイマー/履歴タブへ直接遷移する（URL スキーム or `widgetURL` + タブ選択）
- SwiftData ストアを App Group に移し、Widget が他端末の履歴も即時に反映できるようにする
- Widget / Live Activity からのタイマー操作（App Intents）
