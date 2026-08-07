//
//  PersistenceController.swift
//  FocusAction
//
//  iOS/watchOS共通のCloudKit対応ModelContainer定義
//  このファイルは両方のTargetに追加してください（TimerMode.swiftと同様）
//

import CloudKit
import SwiftData

enum PersistenceController {
    static let cloudKitContainerIdentifier = "iCloud.FocusActionContainer"

    #if DEBUG
    /// CKContainerのアカウント状態を直接確認するための一時的なデバッグ用関数。
    /// entitlements上は正しく見えても、実際のiCloudアカウント状態が
    /// available でないと同期が動かないため、切り分け用に使う。
    static func logCloudKitAccountStatus() {
        let container = CKContainer(identifier: cloudKitContainerIdentifier)
        container.accountStatus { status, error in
            let statusDescription: String
            switch status {
            case .available: statusDescription = "available"
            case .noAccount: statusDescription = "noAccount"
            case .restricted: statusDescription = "restricted"
            case .couldNotDetermine: statusDescription = "couldNotDetermine"
            case .temporarilyUnavailable: statusDescription = "temporarilyUnavailable"
            @unknown default: statusDescription = "unknown"
            }
            print("[CloudKit] accountStatus: \(statusDescription), error: \(String(describing: error))")
        }
    }

    /// SwiftDataErrorがラップしている本当の原因(NSError/CKError)を掘り出して出力する。
    static func logDetailedError(_ error: Error, depth: Int = 0) {
        let nsError = error as NSError
        let indent = String(repeating: "  ", count: depth)
        print("\(indent)[詳細] domain=\(nsError.domain) code=\(nsError.code) description=\(nsError.localizedDescription)")
        if !nsError.userInfo.isEmpty {
            print("\(indent)[詳細] userInfo=\(nsError.userInfo)")
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            logDetailedError(underlying, depth: depth + 1)
        }
        if let multiple = nsError.userInfo[NSMultipleUnderlyingErrorsKey] as? [NSError] {
            for underlying in multiple {
                logDetailedError(underlying, depth: depth + 1)
            }
        }
    }
    #endif

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([FocusSession.self])
        let cloudKitConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudKitConfiguration])
        } catch {
            // CloudKit対応ストアの作成/マイグレーションに失敗した場合でも、
            // ローカルのみのストアで起動を継続できるようにフォールバックする。
            print("CloudKit対応ModelContainerの作成に失敗したため、ローカルストアにフォールバックします: \(error)")
            logDetailedError(error)
        }

        let localConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            fatalError("ローカルModelContainerの作成にも失敗しました: \(error)")
        }
    }()
}
