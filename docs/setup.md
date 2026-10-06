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
- `FocusActionWidgetExtension` … ウィジェット / Live Activity（iOS アプリに埋め込まれるため単体で実行はしない）

## 共通ファイルの扱いに関する注意

以下のファイルは iOS ターゲットと watchOS ターゲットの両方に Target Membership が設定されている
必要があります。新規追加・移動時は Xcode の File Inspector で両ターゲットにチェックが入っているか
確認してください。

- `TimerMode.swift`
- `FocusSession.swift`
- `PersistenceController.swift`
- `TimerSyncManager.swift`
- `TimerViewModel.swift`

## App Group の設定（ウィジェット）

ウィジェットはアプリと別プロセスで動くため、App Group の UserDefaults 経由でデータを受け取ります。

- App Group 識別子: `group.com.keito.FocusAction`
- `FocusAction/FocusAction.entitlements` と `FocusActionWidget/FocusActionWidget.entitlements` の両方に
  `com.apple.security.application-groups` が必要。
- 実機で動かすときは、Signing & Capabilities で両ターゲットに App Group が登録されているか確認する
  （自動署名なら Developer アカウント側にも自動で登録される）。

## アプリアイコン

アイコンは Icon Composer で作成した `FocusAction/FocusActionICON.icon` を使用しています。
iOS と watchOS の両ターゲットで Build Settings の `ASSETCATALOG_COMPILER_APPICON_NAME`
（General の「App Icon」）に、拡張子を除いた `FocusActionICON` を指定しています。
`.icon` ファイルはプロジェクトに追加するだけでは使われないので注意してください。

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

### Production へのスキーマ反映

CloudKit には Development と Production の2つの環境があり、インストール方法で接続先が変わります。

| インストール方法 | CloudKit の環境 |
|---|---|
| Xcode から実行（Development 署名） | Development |
| TestFlight / App Store / Ad Hoc | Production |

Development では保存時に足りないフィールドが自動で作られますが、Production では作られず `BAD_REQUEST` で
拒否されます。**`@Model` にプロパティやリレーションを追加したら、TestFlight に出す前に以下を行ってください。**

1. 実機に Xcode から実行し、追加したフィールドを含むデータを1件保存・同期する（Development にスキーマが作られる）。
2. [CloudKit Console](https://icloud.developer.apple.com/) → `iCloud.FocusActionContainer` → Development の
   Schema → Record Types で、`CD_FocusSession` / `CD_Tag` に必要なフィールドがあるか確認する。
3. 「Deploy Schema Changes...」で Production に反映し、Production 側にも同じフィールドがあるか確認する。

注意:
- Production に反映したスキーマは削除・型変更ができない（追加のみ）。Deploy 前に Development のスキーマが最終形か確認する。
- Development と Production はデータが別。同期の確認は2台とも同じ環境・同じ Apple ID で行う。
- TestFlight 版のログは Console.app で `FocusAction` のプロセスを絞り込み、`CloudKit` で検索して確認する。
  Xcode 実行時はスキームの Arguments に `-com.apple.CoreData.CloudKitDebug 1` を追加すると詳しいログが出る。

経緯は [作業記録 2026-10-04](./作業記録/2026-10-04_CloudKit同期不具合調査.md) を参照してください。

## 通知のテスト

`SettingView` から通知を許可した後、「テスト通知を送信」ボタンで5秒後に通知が届くことを
確認できます（`NotificationManager.sendTestNotification()`）。

## Watch 連携のテスト

iPhone 実機と Apple Watch（ペアリング済み・Watch アプリインストール済み）が必要です。
シミュレータ同士でも `WCSession` を使った基本的な動作確認は可能ですが、実際のペアリング環境での
確認を推奨します。詳細は [Watch 連携](./watch-sync.md) を参照してください。
