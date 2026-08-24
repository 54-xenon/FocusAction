# セットアップ

## 必要要件

- iOS/iPadOS 26.0 以降
- watchOS（Watch App ターゲットをビルドする場合）
- Xcode（Swift 6.0 対応バージョン）

## ビルド手順

```bash
git clone <repository-url>
cd FocusAction
open FocusAction.xcodeproj
```

Xcode 上でターゲットを選択してビルド・実行する。

- `FocusAction` … iOS/iPadOS アプリ
- `FocusAction for Watch Watch App` … watchOS アプリ

## 共通ファイルの扱いに関する注意

以下のファイルは iOS ターゲットと watchOS ターゲットの両方に Target Membership が設定されている
必要があります。新規追加・移動時は Xcode の File Inspector で両ターゲットにチェックが入っているか
確認してください。

- `TimerMode.swift`
- `FocusSession.swift`
- `PersistenceController.swift`
- `TimerSyncManager.swift`
- `TimerViewModel.swift`

## CloudKit / iCloud の設定

このアプリは SwiftData + CloudKit（プライベートデータベース）でセッション履歴を同期します。

- CloudKit コンテナ識別子: `iCloud.FocusActionContainer`
- 両ターゲットの entitlements ファイルに以下が必要:
  - `com.apple.developer.icloud-container-identifiers`: `["iCloud.FocusActionContainer"]`
  - `com.apple.developer.icloud-services`: `["CloudKit"]`
- 実機・シミュレータで動作させるには、Apple Developer アカウントで対象の iCloud コンテナを
  有効化し、実行端末で iCloud にサインインしている必要があります。

### 同期が動かないときの確認方法

`PersistenceController` は CloudKit 対応ストアの作成に失敗しても、ローカルのみのストアに
黙ってフォールバックして起動を続けます。そのため「アプリは動くのに端末間で履歴が同期されない」
という状態に気づきにくいので、以下を確認してください。

1. DEBUG ビルドで実行し、起動時のログを確認する
   （`FocusActionApp.init()` 内で `PersistenceController.logCloudKitAccountStatus()` が
   自動的に呼ばれ、`[CloudKit] accountStatus: ...` が出力される）。
2. `accountStatus` が `available` でない場合（`noAccount` など）は、実行端末で iCloud に
   サインインしているか確認する。
3. `CloudKit対応ModelContainerの作成に失敗したため、ローカルストアにフォールバックします` という
   ログが出ている場合、続く `logDetailedError` の出力から実際の `CKError` を確認する。

詳細は [データモデル](./data-model.md#persistencecontroller-と-cloudkit) を参照してください。

## 通知のテスト

`SettingView` から通知を許可した後、「テスト通知を送信」ボタンで5秒後に通知が届くことを
確認できます（`NotificationManager.sendTestNotification()`）。

## Watch 連携のテスト

iPhone 実機と Apple Watch（ペアリング済み・Watch アプリインストール済み）が必要です。
シミュレータ同士でも `WCSession` を使った基本的な動作確認は可能ですが、実際のペアリング環境での
確認を推奨します。詳細は [Watch 連携](./watch-sync.md) を参照してください。
