# 通知

`FocusAction/Services/NotificationManager.swift`（iOS専用）が `UNUserNotificationCenter` を
ラップし、タイマー完了時刻に合わせたローカル通知を管理する。`@MainActor` の
`ObservableObject` シングルトン（`NotificationManager.shared`）として実装されている。

## 権限管理

- `@Published var isAuthorized: Bool` — 現在の通知許可状態。
- `checkAuthorization()` — `UNUserNotificationCenter.current().notificationSettings()` から
  現在の許可状態を取得して `isAuthorized` を更新。`init()` 内で自動的に一度実行される。
- `requestAuthorization()` — `.alert, .sound, .badge` を要求し、許可結果を返す。
  `TimerView` の `.task` 内、および `SettingView` の「通知を許可」ボタンから呼ばれる。

## タイマー完了通知

`scheduleTimerCompletionNotification(for mode:in:)`:

1. `cancelAllNotifications()` で既存の保留中通知をクリア（重複防止）。
2. モードに応じたタイトル・本文を設定（集中完了 / 休憩完了でメッセージを出し分け）。
3. `UNTimeIntervalNotificationTrigger(timeInterval:repeats: false)` で、残り時間後に1回だけ発火する
   通知をスケジュール。

呼び出し元:
- `TimerViewModel.toggleTimer()` — タイマー開始時（`sessionStartDate` が `nil` のとき、つまり
  新しいセッションの最初の開始時）にスケジュール。
- `TimerViewModel.handleScenePhaseChange(_:)` — バックグラウンドから復帰し、タイマーがまだ
  実行中であればスケジュールし直す（経過時間で補正した残り時間を使用）。

`cancelAllNotifications()` は、一時停止・リセット・モード切替・タイマー完了時に呼ばれ、
不要になった保留中の通知を確実に消す。

## バッジ

`clearBadge()` が `UNUserNotificationCenter.current().setBadgeCount(0)` を呼ぶ。
`TimerView` の `.task` 内で毎回クリアされる。

## テスト通知

`sendTestNotification()` — 5秒後に発火するテスト用通知。`SettingView` の「テスト通知を送信」
ボタンから呼び出せる（通知が許可されている場合のみ表示）。

## 注意点

- 通知関連のコードはすべて `#if os(iOS)` でガードされており、watchOS 側では動作しない
  （watchOS はシステムの通知連携に依存する設計にはなっていない）。
- ログ出力はすべて `#if DEBUG` 内。本番ビルドには含まれない。
