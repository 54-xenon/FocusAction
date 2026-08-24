# データモデル

## FocusSession（SwiftData モデル）

`FocusAction/Models/FocusSession.swift` で定義される、完了・中断したタイマーセッションの記録。

| プロパティ | 型 | 説明 |
|---|---|---|
| `id` | `UUID` | 一意識別子 |
| `startDate` | `Date` | セッション開始日時 |
| `duration` | `TimeInterval` | 実際に経過した時間（秒） |
| `sessionTypeRawValue` / `sessionType` | `String` / `SessionType` | 集中・休憩の種別（生の文字列で保持し、computed property で enum に変換） |
| `tags` | `[String]` | タグ（例: Watch から保存された場合は `["Watch"]`） |
| `isCompleted` | `Bool` | タイマーが最後まで完了したか |
| `createdAt` | `Date` | レコード作成日時 |

> **CloudKit との関係で全プロパティにインラインのデフォルト値が必須**（`var id: UUID = UUID()` のように）。
> `init` のデフォルト引数だけでは CloudKit 同期用のスキーマ要件を満たせず、同期が黙って失敗する。
> 新しいプロパティを追加する際は必ずインラインデフォルトを付けること。

### SessionType

```swift
enum SessionType: String, Codable, CaseIterable {
    case focus = "集中"
    case shortBreak = "休憩"
}
```

`color`（"blue" / "green"）と `icon`（SF Symbols 名）を持ち、履歴画面のアイコン・配色に使う。

### Predicate ヘルパー

`HistoryView` のフィルタ機能から使われる `#Predicate` ベースのヘルパーを `FocusSession` の
extension として用意している。

- `predicate(for tag:)` — タグでの絞り込み
- `predicate(from:to:)` — 期間での絞り込み
- `completedSessionsPredicate()` — 完了済みのみ
- `focusSessionsPredicate()` / `predicate(for sessionType:)` — セッション種別での絞り込み

## PersistenceController と CloudKit

`FocusAction/Services/PersistenceController.swift` が `ModelContainer` の構築を担う。

```swift
static let sharedModelContainer: ModelContainer = {
    // 1. CloudKit対応の ModelConfiguration で構築を試みる
    // 2. 失敗した場合はローカルのみの ModelConfiguration にフォールバック
    // 3. それも失敗したら fatalError
}()
```

- CloudKit コンテナ識別子: `iCloud.FocusActionContainer`
- プライベートデータベースのみを使用（`cloudKitDatabase: .private(...)`）
- iOS / watchOS の両エンティトルメントファイルに、この識別子と `com.apple.developer.icloud-services: CloudKit` が設定されている必要がある。

### CloudKit 対応が黙って無効化される問題への対策

CloudKit 用のストア作成に失敗しても、アプリはクラッシュせずローカルのみのストアで起動を続ける
（`do/catch` によるフォールバック）。これは可用性を優先した設計だが、**気づかないうちに端末間同期が
機能していない状態**になり得るため、以下のデバッグ手段が用意されている（`#if DEBUG` のみ）。

- `PersistenceController.logCloudKitAccountStatus()` — `CKContainer.accountStatus` を直接叩いて
  iCloud アカウントの状態（available / noAccount / restricted 等）をログ出力。`FocusActionApp.init()`
  から起動時に呼ばれる。
- `PersistenceController.logDetailedError(_:)` — SwiftData がラップしたエラーの中から
  `NSUnderlyingErrorKey` / `NSMultipleUnderlyingErrorsKey` を再帰的に辿り、本当の `CKError` を
  ログに出す。

同期が動かないと感じたら、まず DEBUG ログでアカウント状態と詳細エラーを確認すること。

## FocusSession のライフサイクル

1. `TimerViewModel.toggleTimer()` でタイマー開始時に `sessionStartDate` を記録。
2. タイマーが 0 になると `timerCompleted()` → `saveSession(isCompleted: true)` が呼ばれ、
   `FocusSession` を生成して `modelContext.insert` → `modelContext.save()`。
3. watchOS 側で保存された場合は `tags = ["Watch"]` が付与される。
4. `HistoryView` は `@Query(sort: \FocusSession.startDate, order: .reverse)` で全件を取得し、
   `FilterOption` に応じてクライアント側でフィルタ表示する。
