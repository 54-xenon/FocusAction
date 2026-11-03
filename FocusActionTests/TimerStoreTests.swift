//
//  TimerStoreTests.swift
//  FocusActionTests
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import FocusAction

/// 受け取ったイベントを記録するだけのハンドラ
@MainActor
private final class RecordingHandler: TimerEventHandler {
    private(set) var events: [TimerEvent] = []
    private(set) var contexts: [TimerEventContext] = []

    func handle(_ event: TimerEvent, context: TimerEventContext) {
        events.append(event)
        contexts.append(context)
    }
}

/// テストから進められる時計
@MainActor
private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

@MainActor
struct TimerStoreTests {
    private let handler = RecordingHandler()
    private let clock = TestClock()

    private func makeStore(modelContext: ModelContext? = nil, isFromWatch: Bool = false) -> TimerStore {
        let clock = clock
        return TimerStore(
            modelContext: modelContext,
            eventHandlers: [handler],
            isFromWatch: isFromWatch,
            now: { clock.now }
        )
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([FocusSession.self, Tag.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    /// バックグラウンドから復帰した扱いにして、時計に合わせた tick を即座に走らせる
    private func tick(_ store: TimerStore) {
        store.handleScenePhaseChange(.active)
    }

    // MARK: - イベント

    @Test func 開始と一時停止でイベントが出る() {
        let store = makeStore()
        store.toggleTimer()
        clock.advance(by: 60)
        store.toggleTimer()
        #expect(handler.events == [.started, .paused])
        #expect(handler.contexts[0].state.isRunning)
        #expect(!handler.contexts[1].state.isRunning)
        #expect(handler.contexts[1].state.timeRemaining == 25 * 60 - 60)
    }

    @Test func リセットでイベントが出る() {
        let store = makeStore()
        store.toggleTimer()
        store.resetTimer()
        #expect(handler.events == [.started, .reset])
        #expect(handler.contexts[1].state.timeRemaining == 25 * 60)
    }

    @Test func 同じモードへの切替ではイベントが出ない() {
        let store = makeStore()
        store.switchMode(to: .focus)
        #expect(handler.events.isEmpty)
        store.switchMode(to: .shortBreak)
        #expect(handler.events == [.modeSwitched])
        #expect(handler.contexts[0].state.mode == .shortBreak)
    }

    @Test func タグを変えるとイベントが出る() {
        let store = makeStore()
        let tag = Tag(title: "勉強", emoji: "📚", colorHex: "#FF0000")
        store.selectedTag = tag
        #expect(handler.events == [.tagChanged])
        #expect(handler.contexts[0].tag === tag)
    }

    @Test func 終了前のtickではイベントが出ない() {
        let store = makeStore()
        store.toggleTimer()
        clock.advance(by: 60)
        tick(store)
        #expect(handler.events == [.started])
        #expect(store.timeRemaining == 25 * 60 - 60)
    }

    @Test func Watchから受信した状態の反映ではイベントが出ない() {
        let store = makeStore()
        store.applyRemoteState(TimerSyncState(
            timerModeRawValue: TimerMode.focus.rawValue,
            totalTime: 25 * 60,
            timeRemaining: 600,
            isTimerRunning: true,
            sessionStartTimestamp: nil,
            referenceTimestamp: clock.now.timeIntervalSince1970
        ))
        #expect(store.isTimerRunning)
        #expect(handler.events.isEmpty)
    }

    // MARK: - 完了

    @Test func 完了すると次のモードに切り替わる() {
        let store = makeStore()
        let startDate = clock.now
        store.toggleTimer()
        clock.advance(by: 25 * 60)
        tick(store)

        let completion = TimerCompletion(mode: .focus, sessionStartDate: startDate, duration: 25 * 60)
        // modelContext がないので保存はされない
        #expect(handler.events == [.started, .completed(completion), .modeSwitched])
        #expect(store.completionCount == 1)
        #expect(store.timerMode == .shortBreak)
        #expect(!store.isTimerRunning)
        #expect(store.timeRemaining == 5 * 60)
    }

    @Test func 完了したセッションが保存される() throws {
        let modelContext = try makeInMemoryContext()
        let tag = Tag(title: "勉強", emoji: "📚", colorHex: "#FF0000")
        modelContext.insert(tag)

        let store = makeStore(modelContext: modelContext)
        store.selectedTag = tag
        let startDate = clock.now
        store.toggleTimer()
        clock.advance(by: 25 * 60)
        tick(store)

        let completion = TimerCompletion(mode: .focus, sessionStartDate: startDate, duration: 25 * 60)
        #expect(handler.events == [.tagChanged, .started, .completed(completion), .sessionSaved, .modeSwitched])

        let sessions = try modelContext.fetch(FetchDescriptor<FocusSession>())
        let session = try #require(sessions.first)
        #expect(sessions.count == 1)
        #expect(session.startDate == startDate)
        #expect(session.duration == 25 * 60)
        #expect(session.sessionType == .focus)
        #expect(session.tag === tag)
        #expect(!session.isFromWatch)
        #expect(session.isCompleted)
    }

    @Test func Watchで完了したセッションはWatch由来として保存される() throws {
        let modelContext = try makeInMemoryContext()
        let store = makeStore(modelContext: modelContext, isFromWatch: true)
        store.toggleTimer()
        clock.advance(by: 25 * 60)
        tick(store)

        let session = try #require(try modelContext.fetch(FetchDescriptor<FocusSession>()).first)
        #expect(session.isFromWatch)
    }

    @Test func 途中でリセットしたセッションは保存されない() throws {
        let modelContext = try makeInMemoryContext()
        let store = makeStore(modelContext: modelContext)
        store.toggleTimer()
        clock.advance(by: 600)
        store.resetTimer()
        clock.advance(by: 25 * 60)
        tick(store)

        #expect(try modelContext.fetch(FetchDescriptor<FocusSession>()).isEmpty)
    }
}
