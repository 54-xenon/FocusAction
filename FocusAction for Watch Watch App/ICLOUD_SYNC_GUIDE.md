# iCloud同期ガイド（iOS ↔ Watch）

## 🔗 現状の問題

現在、iOS版とWatch版は**別々のSwiftDataストレージ**を使用しているため：
- ❌ iPhoneで完了したセッションはWatchでは見れない
- ❌ Watchで完了したセッションはiPhoneでは見れない

---

## ✅ 解決策: iCloud + SwiftDataで同期

### 1. **Xcodeでの設定**

#### iOS Targetの設定

1. プロジェクトファイルを選択
2. **TARGETS** → **FocusAction** を選択
3. **Signing & Capabilities** タブ
4. **+ Capability** ボタンをクリック
5. **iCloud** を選択
6. **Services**で:
   - ✅ **CloudKit**
7. **Containers**セクションで:
   - **+** ボタンをクリック
   - Container ID: `iCloud.com.yourcompany.FocusAction`（適切に変更してください）
   - または既存のContainer IDを選択

#### Watch Targetの設定

同じ手順を **FocusAction for Watch Watch App** Targetでも実行。
**重要:** 同じContainer IDを使用すること！

---

### 2. **コードの修正**

#### iOS版エントリーポイント

```swift:FocusActionApp.swift
//
//  FocusActionApp.swift
//  FocusAction
//

import SwiftUI
import SwiftData

@main
struct FocusActionApp: App {
    var body: some Scene {
        WindowGroup {
            ControlView()
        }
        .modelContainer(for: FocusSession.self, isStoredInMemoryOnly: false) { result in
            switch result {
            case .success(let container):
                // CloudKit同期を有効化
                container.mainContext.undoManager = nil
                
                // 自動保存を有効化
                container.mainContext.autosaveEnabled = true
                
                print("✅ SwiftData + CloudKit initialized successfully")
            case .failure(let error):
                print("❌ Failed to initialize ModelContainer: \(error)")
            }
        }
    }
}
```

#### Watch版エントリーポイント

```swift:FocusAction_for_WatchApp.swift
//
//  FocusAction_for_WatchApp.swift
//  FocusAction for Watch Watch App
//

import SwiftUI
import SwiftData

@main
struct FocusAction_for_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTimerView()
        }
        .modelContainer(for: FocusSession.self, isStoredInMemoryOnly: false) { result in
            switch result {
            case .success(let container):
                container.mainContext.undoManager = nil
                container.mainContext.autosaveEnabled = true
                print("✅ [Watch] SwiftData + CloudKit initialized successfully")
            case .failure(let error):
                print("❌ [Watch] Failed to initialize ModelContainer: \(error)")
            }
        }
    }
}
```

---

### 3. **App Groupsの設定（さらに確実な同期）**

より確実にデータを共有するには、**App Groups**を使用します。

#### Xcodeでの設定

**iOS Target:**
1. **Signing & Capabilities** タブ
2. **+ Capability** → **App Groups**
3. **+** ボタンをクリック
4. Group ID: `group.com.yourcompany.FocusAction` を入力
5. チェックを入れる

**Watch Target:**
同じ手順で、**同じGroup ID**を追加。

#### コードの修正（App Groups対応）

```swift:FocusActionApp.swift
import SwiftUI
import SwiftData

@main
struct FocusActionApp: App {
    var body: some Scene {
        WindowGroup {
            ControlView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Shared Model Container

private var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        FocusSession.self,
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.yourcompany.FocusAction"),
        cloudKitDatabase: .automatic  // iCloud同期を有効化
    )
    
    do {
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        print("✅ Shared ModelContainer initialized with CloudKit")
        return container
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

**Watch版も同じように修正:**

```swift:FocusAction_for_WatchApp.swift
import SwiftUI
import SwiftData

@main
struct FocusAction_for_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTimerView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Shared Model Container

private var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        FocusSession.self,
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.yourcompany.FocusAction"),
        cloudKitDatabase: .automatic
    )
    
    do {
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        print("✅ [Watch] Shared ModelContainer initialized with CloudKit")
        return container
    } catch {
        fatalError("[Watch] Could not create ModelContainer: \(error)")
    }
}()
```

---

## 📊 データ同期の仕組み

### iCloud + SwiftDataの動作

```
┌─────────────┐          ┌──────────────┐          ┌─────────────┐
│   iPhone    │          │   iCloud     │          │ Apple Watch │
│             │          │   CloudKit   │          │             │
│ ┌─────────┐ │          │              │          │ ┌─────────┐ │
│ │SwiftData│ │ ←─同期──→│   Container  │ ←─同期──→│ │SwiftData│ │
│ └─────────┘ │          │              │          │ └─────────┘ │
└─────────────┘          └──────────────┘          └─────────────┘
```

- **自動同期**: SwiftDataが変更を検知して自動的にCloudKitにアップロード
- **双方向**: iPhoneでもWatchでも変更が反映される
- **オフライン対応**: ネットワークがない時はローカルに保存、後で同期

---

## 🧪 テスト方法

### 1. **iCloudにサインイン**
- iPhone: 設定 → Apple ID → iCloud → ON
- Watch: iPhoneのWatch App → 一般 → iCloud → ON

### 2. **データ同期の確認**

1. **iPhoneでセッションを記録**
   - タイマーを開始して完了
   - HistoryViewで確認

2. **Watchでセッションを記録**
   - タイマーを開始して完了
   - デバッグログで保存を確認

3. **両方のデバイスで確認**
   - 数秒〜数分待つ（同期には時間がかかる場合あり）
   - iPhoneのHistoryViewでWatchのセッションが表示されるか確認
   - Watchタグがついているはず

---

## 🔍 トラブルシューティング

### データが同期されない場合

1. **iCloudストレージを確認**
   - 設定 → Apple ID → iCloud → ストレージを管理
   - 十分な空き容量があるか確認

2. **ネットワーク接続を確認**
   - Wi-Fiまたはモバイルデータに接続されているか

3. **CloudKitダッシュボードで確認**
   - [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
   - データが正しくアップロードされているか確認

4. **クリーンビルド**
   - Xcode → Product → Clean Build Folder
   - 両方のアプリを再インストール

5. **デバッグログを確認**
   - Xcodeのコンソールで`SwiftData`や`CloudKit`のエラーを確認

---

## ⚠️ 注意事項

### 1. **開発時の制限**
- Simulatorでは完全なCloudKit同期は動作しない場合がある
- **実機でのテストが推奨**

### 2. **プライバシー**
- iCloudを使用するため、ユーザーがApple IDでサインインしている必要がある
- プライバシーポリシーにiCloudの使用を明記

### 3. **データ容量**
- 各ユーザーのiCloudストレージを使用
- 大量のデータを保存する場合は容量に注意

### 4. **同期のタイミング**
- 即座に同期されるとは限らない（数秒〜数分かかる場合あり）
- デバイスがスリープ中やバッテリー節約モード時は同期が遅延

---

## 📋 チェックリスト

### Xcodeでの設定
- [ ] iOS Targetに**iCloud Capability**を追加
- [ ] Watch Targetに**iCloud Capability**を追加
- [ ] 両方で同じ**Container ID**を使用
- [ ] iOS Targetに**App Groups Capability**を追加（オプション）
- [ ] Watch Targetに**App Groups Capability**を追加（オプション）
- [ ] 両方で同じ**Group ID**を使用（オプション）

### コードの修正
- [ ] iOS版エントリーポイントを修正
- [ ] Watch版エントリーポイントを修正
- [ ] `sharedModelContainer`を実装（App Groups使用時）
- [ ] `.modelContainer()`に`cloudKitDatabase: .automatic`を追加

### テスト
- [ ] iPhoneの実機でテスト
- [ ] Apple Watchの実機でテスト
- [ ] iCloudにサインイン
- [ ] データが同期されることを確認

---

## 🚀 次のステップ

現在の実装（ローカルのみ）でも十分動作しますが、iCloud同期を追加すると：

✅ **iPhoneとWatchでデータを共有できる**
✅ **デバイスを変更してもデータが残る**
✅ **バックアップが自動的に作成される**

ただし、実装にはXcodeでの追加設定が必要です。必要に応じて実装してください！

---

**作成日**: 2026-05-14  
**対応バージョン**: iOS 18+, watchOS 11+, Swift 6
