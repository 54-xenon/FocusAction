# FocusAction ドキュメント

FocusAction は、iOS/iPadOS と watchOS 上で動作するポモドーロタイマーアプリです。
このディレクトリには、開発・保守に必要な技術ドキュメントをまとめています。

## 目次

- [アーキテクチャ概要](./architecture.md) — アプリ全体の構成、ターゲット構成、レイヤー設計
- [データモデル](./data-model.md) — SwiftData モデルと CloudKit 同期
- [Watch 連携](./watch-sync.md) — WatchConnectivity によるタイマー状態同期の仕組み
- [画面構成](./views.md) — 各 View の役割とレイアウト分岐（iPhone / iPad / Watch）
- [通知](./notifications.md) — ローカル通知のスケジューリング
- [セットアップ](./setup.md) — 開発環境の準備、ビルド、CloudKit 設定

## プロジェクト概要

- **プラットフォーム**: iOS/iPadOS 26.0+, watchOS
- **言語**: Swift 6.0
- **UI フレームワーク**: SwiftUI
- **永続化**: SwiftData + CloudKit（プライベートデータベース）
- **端末間同期**: WatchConnectivity（タイマーの実行状態のみ。履歴データは CloudKit 経由）

トップレベルの `README.md`（プロジェクトルート）には、機能紹介やスクリーンショット等のユーザー向け情報があります。このディレクトリは開発者向けの技術ドキュメントです。
