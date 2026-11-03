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

呼び出し元は `FocusAction/Services/TimerEventHandlers.swift` の `NotificationTimerEventHandler`。
`TimerStore` が発行する `TimerEvent` を受けて通知を操作する。

- `.started`（開始・再開）— その時点の残り時間でスケジュール。一時停止で取り消した通知も、
  再開時に残り時間で入れ直される。
- `.paused` / `.reset` / `.modeSwitched` / `.completed` — `cancelAllNotifications()` で
  不要になった保留中の通知を確実に消す。

> 残り時間は終了時刻 `endDate` から計算する方式のため、バックグラウンドから復帰しても通知を
> スケジュールし直す必要はない（開始時に予約した通知の発火時刻がそのまま正しい）。

## バッジ

`clearBadge()` が `UNUserNotificationCenter.current().setBadgeCount(0)` を呼ぶ。
`TimerView` の `.task` 内で毎回クリアされる。

## テスト通知

`sendTestNotification()` — 5秒後に発火するテスト用通知。`SettingView` の「テスト通知を送信」
ボタンから呼び出せる（通知が許可されている場合のみ表示）。

## 注意点

- 通知関連のコードは iOS ターゲットにのみ属し、watchOS 側の `TimerStore` には
  `NotificationTimerEventHandler` を注入していないため動作しない
  （watchOS はシステムの通知連携に依存する設計にはなっていない）。
- ログ出力はすべて `#if DEBUG` 内。本番ビルドには含まれない。
