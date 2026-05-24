# FocusAction

![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)

ポモドーロテクニックを活用した集中力向上のためのタイマーアプリです。
##  概要

FocusActionは、作業効率を最大化するためのシンプルで美しいポモドーロタイマーアプリです。25分の集中時間と5分の休憩時間を繰り返すことで、生産性を向上させます。

### 主な特徴

- ⏱️ **ポモドーロタイマー**: 25分の集中モードと5分の休憩モード
- 🎨 **モダンなUI**: Liquid Glassエフェクトを活用した美しいインターフェース。
- 📊 **進捗の可視化**: 円形プログレスバーで残り時間を直感的に表示。
- 🔄 **自動モード切替**: タイマー完了後、自動的に次のモードへ移行
- 📝 **履歴管理**: 作業履歴を確認できる。モチベーションを維持し、目標を実現するためサポートします（今後実装予定）
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
## 🏗️ アーキテクチャ

### ファイル構成

```
FocusAction/
├── iOS App/
│   ├── FocusActionApp.swift
│   ├── ControlView.swift
│   ├── TimerView.swift (iPad対応済み)
│   ├── HistoryView.swift
│   ├── SettingView.swift
|   ├── TimerMode.swift
|   ├── FocusSession.swift (SwiftData)
|   |── NotificationManager.swift
│   └── その他のiOS専用ファイル
│
├── Watch App/
    ├── FocusActionWatchApp.swift
    ├── WatchTimerView.swift
    └── Assets.xcassets (Watch用)

```

### 主要コンポーネント

#### TimerView
- タイマーのメイン画面
- `@State`プロパティでタイマーの状態を管理
- Combineフレームワークの`Timer.publish`で1秒ごとに更新
- Liquid Glassエフェクトを活用したモダンなUI

#### TimerMode (Enum)
- 集中モードと休憩モードを定義
- 各モードの時間、色、アイコンを管理

#### ControlView
- 3つのタブ（Timer、History、Settings）を管理
- アプリ全体のナビゲーション

##  技術スタック

- **言語**: Swift
- **フレームワーク**: SwiftUI
- **状態管理**: `@State`, `@Binding`
- **リアクティブ**: Combine (Timer.publish)
- **デザイン**: Liquid Glass エフェクト

##  必要要件

- iOS 15.0以降
- Xcode 14.0以降
- Swift 5.7以降

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

##  使い方

1. **タイマーの開始**: 再生ボタンをタップしてタイマーを開始
2. **一時停止**: 一時停止ボタンで作業を中断
3. **リセット**: リセットボタンでタイマーを初期状態に戻す
4. **モード切替**: 下部のモードボタンで集中モードと休憩モードを手動で切り替え
5. **自動切替**: タイマー完了後、自動的に次のモードへ移行

##  今後の予定

- [ ] 履歴機能の実装
  - 完了したポモドーロの記録
  - 統計データの表示
- [ ] 設定機能の実装
  - タイマー時間のカスタマイズ
  - 通知設定
  - サウンド設定
- [ ] 長い休憩モードの追加（15分）
- [ ] データ永続化（SwiftData）
- [ ] 通知機能の追加
- [ ] ウィジェット対応

##  デザイン

このアプリは、Appleの最新デザイン言語である**Liquid Glass**を採用しています。Liquid Glassは以下の特徴を持ちます：

- 背景のコンテンツをぼかす
- 周囲の色と光を反射
- タッチやポインタのインタラクションにリアルタイムで反応
- 流動的なアニメーションと遷移



##  コントリビューション

プルリクエストは大歓迎です。大きな変更の場合は、まずissueを開いて変更内容を議論してください。どんな内容でも構いません。開発の励みになります。


