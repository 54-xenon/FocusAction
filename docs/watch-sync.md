# Watch 連携（WatchConnectivity）

`FocusAction/Services/TimerSyncManager.swift`（iOS/watchOS 共通ファイル）が、iPhone と Apple Watch
間でタイマーの**実行状態**をリアルタイムに近い形で同期する。

> 対象は「今どのモードで、あと何秒残っていて、動いているか」といったタイマーの実行状態のみ。
> `FocusSession` の履歴データはこの仕組みの対象外で、CloudKit 経由で別途同期される。

## 同期される状態: TimerSyncState

```swift
struct TimerSyncState {
    let timerModeRawValue: String       // .focus / .shortBreak
    let totalTime: TimeInterval
    let timeRemaining: TimeInterval
    let isTimerRunning: Bool
    let sessionStartTimestamp: TimeInterval?
    let referenceTimestamp: TimeInterval // このスナップショットを作った時刻
}
```

`referenceTimestamp` が重要で、送信側と受信側の間にタイムラグがあっても、受信側で
「スナップショット作成時刻からの経過時間」を計算して残り時間を補正できるようにしている
（`applyRemoteState` 内の `elapsedSinceReference` の計算）。

## 送信（iOS → Watch）

`TimerSyncManager.sendState(_:)`（`#if os(iOS)` のみ）が、ペア設定済みかつ Watch アプリがインストール
済みの場合に `WCSession.updateApplicationContext(_:)` で状態を送信する。

呼び出しタイミングは `TimerViewModel` の以下のメソッド内:
- `toggleTimer()`（開始／一時停止）
- `resetTimer()`
- `switchMode(to:)`（モード切替、タイマー完了時の自動切替を含む）

`updateApplicationContext` は最新の内容で上書きされる性質があるため、**毎秒ではなく状態が
変化したタイミングでのみ**呼び出せば十分、という設計判断がコメントに明記されている。

## 受信（Watch 側）

- `TimerSyncManager.start(with:)` が `TimerViewModel` 初期化時に呼ばれ、watchOS では
  `applyLatestContextIfAvailable()` で起動直後に直近の `applicationContext` を即座に反映する。
- `WCSessionDelegate.session(_:didReceiveApplicationContext:)`（`#if os(watchOS)`）で新しい状態を
  受信するたびに `TimerViewModel.applyRemoteState(_:)` を呼ぶ。
- セッションのアクティベーション完了時（`activationDidCompleteWith:`）にも、watchOS 側では
  直近のコンテキストを再適用する。

## TimerViewModel.applyRemoteState(_:)

受信した `TimerSyncState` を Watch 側の `TimerViewModel` に反映するロジック。

1. 実行中のタイマー購読を一旦停止。
2. `timerMode` / `totalTime` / `sessionStartDate` を同期。
3. `isTimerRunning == true` の場合、`referenceDate` からの経過時間を引いた残り時間を計算。
   経過しきっていれば停止状態に、残っていればタイマー購読を再開する。
4. `isTimerRunning == false` の場合はそのまま `timeRemaining` を反映するのみ。

## 図解

```
iPhone (TimerViewModel)                     Watch (TimerViewModel)
   │  toggleTimer / resetTimer / switchMode
   ▼
TimerSyncManager.sendState()
   │  WCSession.updateApplicationContext(state.dictionary)
   ▼
                     ── WatchConnectivity ──▶
                                                 WCSessionDelegate
                                                 .didReceiveApplicationContext
                                                    ▼
                                                 TimerSyncManager
                                                    ▼
                                                 viewModel.applyRemoteState(state)
```
