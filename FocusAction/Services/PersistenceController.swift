//
//  PersistenceController.swift
//  FocusAction
//
//  iOS/watchOS共通のCloudKit対応ModelContainer定義
//  このファイルは両方のTargetに追加してください（TimerMode.swiftと同様）
//

import SwiftData

enum PersistenceController {
    static let cloudKitContainerIdentifier = "iCloud.FocusActionContainer"

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
        }

        let localConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            fatalError("ローカルModelContainerの作成にも失敗しました: \(error)")
        }
    }()
}
