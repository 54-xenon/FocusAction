# FocusAction

![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20watchOS-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)

ポモドーロテクニックを活用した集中力向上のためのタイマーアプリです。
##  概要

FocusActionは、作業効率を最大化するためのシンプルで美しいポモドーロタイマーアプリです。25分の集中時間と5分の休憩時間を繰り返すことで、生産性を向上させます。iPhone/iPadに加えApple Watchにも対応しています。

### 主な特徴

- ⏱️ **ポモドーロタイマー**: 25分の集中モードと5分の休憩モード
- 🎨 **モダンなUI**: Liquid Glassエフェクトを活用した美しいインターフェース。
- 📊 **進捗の可視化**: 円形プログレスバーで残り時間を直感的に表示。
- 🔄 **自動モード切替**: タイマー完了後、自動的に次のモードへ移行
- 📝 **履歴管理**: SwiftData + CloudKitで作業履歴を保存し、端末をまたいで同期
- 🏷️ **タグ機能**: タイトル・絵文字・背景色を持つタグをセッションに1つ付けて管理・絞り込み
- ⌚ **Apple Watch対応**: WatchConnectivityでiPhoneとタイマーの状態をリアルタイム同期
- 🔔 **通知**: タイマー完了時にローカル通知でお知らせ
- ⚙️ **カスタマイズ可能**: 設定画面でタイマーをカスタマイズ（今後実装予定）

## スクリーンショット
UIがもうちょっと固まってきたら追加します.
### メイン画面
- 円形のプログレスバーで残り時間を表示
- 集中モード（青）と休憩モード（緑）で色が変化
- 再生/一時停止、リセットボタンで簡単操作

### モード切替
- 集中タイム: 25分間の作業時間
- 休憩タイム: 5分間の休憩時間

### 設定画面
- 通知の管理
- バージョンの確認
##  アーキテクチャ

### ファイル構成

```
FocusAction.xcodeproj
├── FocusAction/                          … iOS/iPadOS アプリ本体
│   ├── App/
│   │   └── FocusActionApp.swift          … エントリポイント、ModelContainerの注入
│   ├── Models/
│   │   ├── TimerMode.swift               … タイマーのモード定義（集中/休憩）※iOS/watchOS共通
│   │   ├── FocusSession.swift            … SwiftDataの永続化モデル（セッション履歴）※iOS/watchOS共通
│   │   └── Tag.swift                     … SwiftDataの永続化モデル（タグ）※iOS/watchOS共通
│   ├── ViewModels/
│   │   └── TimerViewModel.swift          … タイマーの状態管理・進行ロジック ※iOS/watchOS共通
│   ├── Services/
│   │   ├── PersistenceController.swift   … CloudKit対応ModelContainerの構築 ※iOS/watchOS共通
│   │   ├── TimerSyncManager.swift        … WatchConnectivityによるiPhone-Watch間の状態同期 ※iOS/watchOS共通
│   │   └── NotificationManager.swift     … ローカル通知の管理（iOS専用）
│   └── Views/
│       ├── ControlView.swift             … TabViewによるルートナビゲーション
│       ├── TimerView.swift (+iPhone/+iPad) … タイマー画面
│       ├── HistoryView.swift (+iPhone/+iPad) … 履歴画面
│       ├── SettingView.swift             … 設定画面
│       ├── Color+Hex.swift, TagChipView.swift … タグ表示用の共通部品 ※iOS/watchOS共通
│       └── TagPickerMenu.swift, TagManagementView.swift, TagEditView.swift … タグ選択・管理（iOS専用）
│
└── FocusAction for Watch Watch App/      … watchOS アプリ
    ├── FocusAction_for_WatchApp.swift
    ├── WatchTagListView.swift            … 起動時のルート画面（タグ一覧）
    ├── WatchTimerView.swift              … タイマー画面（push先）
    └── Assets.xcassets (Watch用)
```

より詳しい構成やレイヤー設計は [docs/architecture.md](docs/architecture.md) を参照してください。

### 主要コンポーネント

#### TimerView
- タイマーのメイン画面
- `TimerViewModel`でタイマーの状態を管理し、`horizontalSizeClass`でiPhone/iPad向けに出し分け
- Combineフレームワークの`Timer.publish`で1秒ごとに更新
- Liquid Glassエフェクトを活用したモダンなUI

#### TimerMode
- 集中モードと休憩モードを定義
- 各モードの時間、色、アイコンを管理

#### ControlView
- 3つのタブ（Timer、History、Settings）を管理
- アプリ全体のナビゲーション

#### TimerSyncManager
- WatchConnectivityを使い、iPhoneとApple Watch間でタイマーの実行状態を同期

##  技術スタック

- **言語**: Swift 6.0
- **フレームワーク**: SwiftUI
- **対象OS**: iOS/iPadOS, watchOS
- **状態管理**: MVVM（`ObservableObject` + `@StateObject`/`@ObservedObject`）
- **リアクティブ**: Combine (Timer.publish)
- **永続化 / 同期**: SwiftData + CloudKit（プライベートデータベース）
- **端末間同期**: WatchConnectivity
- **デザイン**: Liquid Glass エフェクト

##  必要要件

- iOS/iPadOS 26.0以降
- watchOS 26.4以降
- Xcode 16以降
- Swift 6.0以降

##  インストール

1. リポジトリをクローン
```bash
git clone [repository-url]
```

2. Xcodeでプロジェクトを開く
```bash
cd FocusAction
open FocusAction.xcodeproj
```

3. シミュレーターまたは実機でビルド・実行

> CloudKit同期を有効にするには署名・Capabilityの設定が必要です。詳細は [docs/setup.md](docs/setup.md) を参照してください。

##  使い方

1. **タイマーの開始**: 再生ボタンをタップしてタイマーを開始
2. **一時停止**: 一時停止ボタンで作業を中断
3. **リセット**: リセットボタンでタイマーを初期状態に戻す
4. **モード切替**: 下部のモードボタンで集中モードと休憩モードを手動で切り替え
5. **自動切替**: タイマー完了後、自動的に次のモードへ移行

##  今後の予定

- [x] 履歴機能の実装
  - 完了したポモドーロの記録
  - 統計データの表示
- [x] データ永続化（SwiftData + CloudKit）
- [x] 通知機能の追加
- [x] Apple Watch対応（WatchConnectivityによる状態同期）
- [ ] 設定機能の拡充
  - タイマー時間のカスタマイズ
  - 通知設定
  - サウンド設定
- [ ] 長い休憩モードの追加（15分）
- [ ] ウィジェット対応

##  デザイン

このアプリは、Appleの最新デザイン言語である**Liquid Glass**を採用しています。Liquid Glassは以下の特徴を持ちます：

- 背景のコンテンツをぼかす
- 周囲の色と光を反射
- タッチやポインタのインタラクションにリアルタイムで反応
- 流動的なアニメーションと遷移



## 開発者向けドキュメント

アーキテクチャやデータモデル、Watch連携などの詳細は [docs/](docs/docs_README.md) にまとめています。

##  コントリビューション

プルリクエストは大歓迎です。大きな変更の場合は、まずissueを開いて変更内容を議論してください。どんな内容でも構いません。開発の励みになります。


