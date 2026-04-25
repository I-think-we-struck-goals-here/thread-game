import XCTest
@testable import ThreadApp

final class ThreadCoreTests: XCTestCase {
    func testGuessNormalizerCollapsesWhitespaceAndUppercases() {
        XCTAssertEqual(GuessNormalizer.normalize("  head   ") , "HEAD")
        XCTAssertEqual(GuessNormalizer.normalize("silver   tongue"), "SILVER TONGUE")
    }

    func testGuessLengthPolicyDoesNotLeakShortAnswerLength() {
        let round = ThreadRound(
            id: 1,
            sourcePool: "practice",
            answer: "STAR",
            acceptedAnswers: ["STAR"],
            clues: [
                RoundClue(word: "WARS", connection: "Star Wars"),
                RoundClue(word: "SHOOTING", connection: "Shooting star"),
                RoundClue(word: "HOLLYWOOD", connection: "Hollywood star"),
                RoundClue(word: "NIGHT", connection: "Stars at night"),
                RoundClue(word: "FISH", connection: "Starfish"),
            ]
        )

        XCTAssertEqual(ThreadGuessLengthPolicy.maxGuessLength(for: round), 12)
    }

    func testSchedulerUsesAnchorDateForDayNumbers() {
        let rounds = [
            ThreadRound(id: 1, sourcePool: "test", answer: "HEAD", acceptedAnswers: ["HEAD"], clues: sampleClues),
            ThreadRound(id: 2, sourcePool: "test", answer: "HAND", acceptedAnswers: ["HAND"], clues: sampleClues),
        ]

        let scheduler = DailyScheduler(
            rounds: rounds,
            timeZoneID: "Europe/London",
            anchorComponents: DateComponents(year: 2026, month: 4, day: 4)
        )

        XCTAssertEqual(scheduler.dayNumber(now: date("2026-04-04T10:00:00Z")), 1)
        XCTAssertEqual(scheduler.dayNumber(now: date("2026-04-05T10:00:00Z")), 2)
        XCTAssertEqual(scheduler.roundForToday(now: date("2026-04-05T10:00:00Z")).id, 2)
        XCTAssertEqual(scheduler.todayDateKey(now: date("2026-04-04T23:30:00Z")), "2026-04-05")
    }

    func testSchedulerComputesNextUnlockAtLondonMidnight() {
        let scheduler = DailyScheduler(
            rounds: [
                ThreadRound(id: 1, sourcePool: "test", answer: "HEAD", acceptedAnswers: ["HEAD"], clues: sampleClues),
            ],
            timeZoneID: "Europe/London",
            anchorComponents: DateComponents(year: 2026, month: 4, day: 4)
        )

        XCTAssertEqual(
            ISO8601DateFormatter().string(from: scheduler.nextUnlockDate(now: date("2026-04-04T22:15:00Z"))),
            "2026-04-04T23:00:00Z"
        )
    }

    @MainActor
    func testGameViewModelAcceptsVariantsAndScoresCorrectly() {
        let round = ThreadRound(
            id: 1,
            sourcePool: "test",
            answer: "BRIDGE",
            acceptedAnswers: ["BRIDGE", "BRIDGES"],
            clues: sampleClues
        )

        let viewModel = ThreadGameViewModel(round: round)
        viewModel.guess = "bridges"
        let outcome = viewModel.submitGuess()

        XCTAssertTrue(viewModel.isSolved)
        XCTAssertEqual(outcome, .solved(1))
    }

    @MainActor
    func testGameViewModelDoesNotConsumeClueForDuplicateGuess() {
        let round = ThreadRound(
            id: 1,
            sourcePool: "test",
            answer: "BRIDGE",
            acceptedAnswers: ["BRIDGE"],
            clues: sampleClues
        )

        let viewModel = ThreadGameViewModel(round: round)
        viewModel.guess = "bell"

        XCTAssertEqual(viewModel.submitGuess(), .revealedNextClue)
        XCTAssertEqual(viewModel.revealedClueCount, 2)
        XCTAssertEqual(viewModel.attempts, ["BELL"])

        viewModel.guess = " bell "
        XCTAssertEqual(viewModel.submitGuess(), .duplicate)
        XCTAssertEqual(viewModel.revealedClueCount, 2)
        XCTAssertEqual(viewModel.attempts, ["BELL"])
        XCTAssertEqual(
            viewModel.feedback,
            RoundFeedback(text: "You already tried BELL. Try a new angle.", tone: .warning)
        )
    }

    func testStatisticsBuilderComputesCurrentAndBestStreaks() {
        let history = [
            DailyHistoryEntry(dateKey: "2026-04-04", roundID: 1, answer: "HEAD", score: 2, completedAt: date("2026-04-04T08:00:00Z"), aggregateSubmittedAt: nil),
            DailyHistoryEntry(dateKey: "2026-04-05", roundID: 2, answer: "HAND", score: 3, completedAt: date("2026-04-05T08:00:00Z"), aggregateSubmittedAt: nil),
            DailyHistoryEntry(dateKey: "2026-04-06", roundID: 3, answer: "FOOT", score: nil, completedAt: date("2026-04-06T08:00:00Z"), aggregateSubmittedAt: nil),
        ]

        let summary = ThreadStatisticsBuilder.build(history: history, todayKey: "2026-04-06")

        XCTAssertEqual(summary.totalPlayed, 3)
        XCTAssertEqual(summary.solveRate, 66)
        XCTAssertEqual(summary.currentStreak, 3)
        XCTAssertEqual(summary.bestStreak, 3)
        XCTAssertEqual(summary.scoreCounts[2], 1)
        XCTAssertEqual(summary.scoreCounts[3], 1)
        XCTAssertEqual(summary.missedCount, 1)
    }

    func testShareTextBuilderMatchesScoreRow() {
        let text = ShareTextBuilder.resultText(roundNumber: 42, score: 3)

        XCTAssertTrue(text.contains("THREAD #42"))
        XCTAssertTrue(text.contains("🟢🟢🟢⚪⚪"))
        XCTAssertTrue(text.contains("Sharp - 3 clues"))
    }

    func testLegacyThreadPreferencesDecodeDefaultsNewReminderField() throws {
        let legacyJSON = """
        {
          "analyticsEnabled": false,
          "aggregateSharingEnabled": true,
          "hapticsEnabled": false
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ThreadPreferences.self, from: legacyJSON)

        XCTAssertEqual(decoded.analyticsEnabled, false)
        XCTAssertEqual(decoded.aggregateSharingEnabled, true)
        XCTAssertEqual(decoded.hapticsEnabled, false)
        XCTAssertEqual(decoded.dailyRemindersEnabled, false)
        XCTAssertNil(decoded.updatedAt)
    }

    @MainActor
    func testEnablingDailyRemindersWithoutAuthorizationShowsPromptButDoesNotEnablePreference() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .notDetermined)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        viewModel.setDailyRemindersEnabled(true)
        await settleAsyncWork()

        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        XCTAssertEqual(viewModel.notificationPrompt?.kind, .requestAuthorization)
        XCTAssertEqual(await notifications.scheduledReminderCount(), 0)
    }

    @MainActor
    func testConfirmingNotificationPromptEnablesPreferenceAndSchedulesReminders() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .notDetermined, requestResultStatus: .authorized)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        viewModel.setDailyRemindersEnabled(true)
        await settleAsyncWork()
        await viewModel.confirmNotificationPrompt()
        await settleAsyncWork()

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertNil(viewModel.notificationPrompt)
        XCTAssertEqual(await notifications.requestAuthorizationCount(), 1)
        XCTAssertEqual(await notifications.scheduledReminderCount(), 1)
    }

    @MainActor
    func testDismissingReminderPromptResetsDisplayedToggleState() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .notDetermined)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        viewModel.setDailyRemindersEnabled(true)
        await settleAsyncWork()
        viewModel.dismissNotificationPrompt()

        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertFalse(viewModel.displayedDailyRemindersEnabled)
        XCTAssertNil(viewModel.notificationPrompt)
    }

    @MainActor
    func testEnablingDailyRemindersWithGrantedAuthorizationSchedulesImmediately() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .authorized)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        viewModel.setDailyRemindersEnabled(true)
        await settleAsyncWork()

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertNil(viewModel.notificationPrompt)
        XCTAssertEqual(await notifications.scheduledReminderCount(), 1)
    }

    @MainActor
    func testPendingReminderEnableReconcilesAfterAuthorizationAppearsOnRefresh() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .notDetermined)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        await viewModel.bootstrapIfNeeded()
        viewModel.setDailyRemindersEnabled(true)
        await settleAsyncWork()

        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)

        await notifications.setStatus(.authorized)
        await viewModel.handleScenePhaseChange(.active)
        await settleAsyncWork()

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        XCTAssertEqual(await notifications.scheduledReminderCount(), 1)
    }

    @MainActor
    func testLocalThreadStoreTracksDistinctNotificationPromptDays() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        _ = store.recordAppOpenDay("2026-04-04")
        _ = store.recordAppOpenDay("2026-04-04")
        let state = store.recordAppOpenDay("2026-04-05")

        XCTAssertEqual(state.seenDateKeys, ["2026-04-04", "2026-04-05"])
        XCTAssertEqual(state.promptCount, 0)

        let promptedState = store.markNotificationPromptShown(at: date("2026-04-05T09:00:00Z"))
        XCTAssertEqual(promptedState.promptCount, 1)
        XCTAssertEqual(promptedState.lastPromptAt, date("2026-04-05T09:00:00Z"))
    }

    func testThreadRoundValidatorRejectsDuplicateIDs() {
        let rounds = [
            ThreadRound(id: 7, sourcePool: "test", answer: "HEAD", acceptedAnswers: ["HEAD"], clues: sampleClues),
            ThreadRound(id: 7, sourcePool: "test", answer: "HAND", acceptedAnswers: ["HAND"], clues: sampleClues),
        ]

        XCTAssertThrowsError(try ThreadRoundValidator.validate(rounds, sourceName: "test")) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "Invalid bundled resource test: duplicate round ID 7"
            )
        }
    }

    func testBundledRoundResourcesPassSemanticValidation() throws {
        let decoder = JSONDecoder()

        let dailyRounds = try decoder.decode([ThreadRound].self, from: Data(contentsOf: resourcesURL.appendingPathComponent("daily-rounds.json")))
        let practiceRounds = try decoder.decode([ThreadRound].self, from: Data(contentsOf: resourcesURL.appendingPathComponent("practice-rounds.json")))

        XCTAssertNoThrow(try ThreadRoundValidator.validate(dailyRounds, sourceName: "daily-rounds"))
        XCTAssertNoThrow(try ThreadRoundValidator.validate(practiceRounds, sourceName: "practice-rounds"))
    }

    @MainActor
    func testLocalThreadStorePersistsPreferencesAndSnapshots() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let preferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: true,
            hapticsEnabled: false,
            dailyRemindersEnabled: true
        )

        store.preferences = preferences
        XCTAssertEqual(store.preferences, preferences)

        let snapshot = GameSnapshot(
            roundID: 77,
            dateKey: "2026-04-04",
            revealedClueCount: 2,
            guess: "RIN",
            attempts: ["BELL"],
            isSolved: false,
            isFailed: false
        )

        store.saveSnapshot(snapshot)
        XCTAssertEqual(store.loadSnapshot(for: "2026-04-04", roundID: 77), snapshot)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 78))

        store.clearSnapshot(for: "2026-04-04")
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 77))
    }

    @MainActor
    func testLocalThreadStoreCanClearProgressWithoutTouchingPreferencesOrInstallationID() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let installationID = store.installationID
        store.tutorialCompleted = true
        store.preferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: false,
            hapticsEnabled: true,
            dailyRemindersEnabled: true
        )

        _ = store.upsertHistoryEntry(
            DailyHistoryEntry(
                dateKey: "2026-04-04",
                roundID: 12,
                answer: "RING",
                score: 2,
                completedAt: date("2026-04-04T08:00:00Z"),
                aggregateSubmittedAt: nil
            )
        )
        store.saveSnapshot(
            GameSnapshot(
                roundID: 12,
                dateKey: "2026-04-04",
                revealedClueCount: 2,
                guess: "RI",
                attempts: ["BELL"],
                isSolved: false,
                isFailed: false
            )
        )

        store.resetTutorial()
        store.clearHistory()
        store.clearAllSnapshots()

        XCTAssertFalse(store.tutorialCompleted)
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 12))
        XCTAssertEqual(store.preferences.analyticsEnabled, false)
        XCTAssertEqual(store.preferences.aggregateSharingEnabled, false)
        XCTAssertEqual(store.preferences.hapticsEnabled, true)
        XCTAssertEqual(store.preferences.dailyRemindersEnabled, true)
        XCTAssertEqual(store.installationID, installationID)
    }

    @MainActor
    func testLocalThreadStoreCanClearGameplayProgressWithoutTouchingTutorialPreferencesOrInstallationID() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let installationID = store.installationID
        store.tutorialCompleted = true
        store.preferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: true,
            hapticsEnabled: false,
            dailyRemindersEnabled: true
        )

        _ = store.upsertHistoryEntry(
            DailyHistoryEntry(
                dateKey: "2026-04-04",
                roundID: 12,
                answer: "RING",
                score: 2,
                completedAt: date("2026-04-04T08:00:00Z"),
                aggregateSubmittedAt: nil
            )
        )
        store.saveSnapshot(
            GameSnapshot(
                roundID: 12,
                dateKey: "2026-04-04",
                revealedClueCount: 2,
                guess: "RI",
                attempts: ["BELL"],
                isSolved: false,
                isFailed: false
            )
        )

        store.clearGameplayProgress()

        XCTAssertTrue(store.tutorialCompleted)
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 12))
        XCTAssertEqual(store.preferences.analyticsEnabled, false)
        XCTAssertEqual(store.preferences.aggregateSharingEnabled, true)
        XCTAssertEqual(store.preferences.hapticsEnabled, false)
        XCTAssertEqual(store.preferences.dailyRemindersEnabled, true)
        XCTAssertEqual(store.installationID, installationID)
    }

    @MainActor
    func testLocalThreadStoreCanResetForFreshLaunchWithoutTouchingPreferencesOrInstallationID() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let installationID = store.installationID
        store.tutorialCompleted = true
        store.preferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: true,
            hapticsEnabled: false,
            dailyRemindersEnabled: true
        )

        _ = store.upsertHistoryEntry(
            DailyHistoryEntry(
                dateKey: "2026-04-04",
                roundID: 12,
                answer: "RING",
                score: 2,
                completedAt: date("2026-04-04T08:00:00Z"),
                aggregateSubmittedAt: nil
            )
        )
        store.saveSnapshot(
            GameSnapshot(
                roundID: 12,
                dateKey: "2026-04-04",
                revealedClueCount: 2,
                guess: "RI",
                attempts: ["BELL"],
                isSolved: false,
                isFailed: false
            )
        )

        store.resetForFreshLaunch()

        XCTAssertFalse(store.tutorialCompleted)
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 12))
        XCTAssertEqual(store.preferences.analyticsEnabled, false)
        XCTAssertEqual(store.preferences.aggregateSharingEnabled, true)
        XCTAssertEqual(store.preferences.hapticsEnabled, false)
        XCTAssertEqual(store.preferences.dailyRemindersEnabled, true)
        XCTAssertEqual(store.installationID, installationID)
    }

    func testHistoryEntryMarksAggregateSubmission() {
        let completedAt = date("2026-04-04T08:00:00Z")
        let submittedAt = date("2026-04-04T08:05:00Z")

        let entry = DailyHistoryEntry(
            dateKey: "2026-04-04",
            roundID: 4,
            answer: "RING",
            score: 2,
            completedAt: completedAt,
            aggregateSubmittedAt: nil
        )

        let updated = entry.markingAggregateSubmitted(at: submittedAt)

        XCTAssertEqual(updated.dateKey, entry.dateKey)
        XCTAssertEqual(updated.roundID, entry.roundID)
        XCTAssertEqual(updated.answer, entry.answer)
        XCTAssertEqual(updated.score, entry.score)
        XCTAssertEqual(updated.completedAt, entry.completedAt)
        XCTAssertEqual(updated.aggregateSubmittedAt, submittedAt)
    }

    func testThreadExternalLinksBuildsMailtoAndFlagsConfiguredState() {
        let configured = ThreadExternalLinks(
            supportURL: URL(string: "https://daily-thread.co/support"),
            supportEmailAddress: "zmailinglist@gmail.com",
            privacyPolicyURL: URL(string: "https://daily-thread.co/privacy")
        )

        XCTAssertEqual(configured.supportEmailURL?.absoluteString, "mailto:zmailinglist@gmail.com")
        XCTAssertTrue(configured.hasAnyLink)

        let empty = ThreadExternalLinks(
            supportURL: nil,
            supportEmailAddress: nil,
            privacyPolicyURL: nil
        )

        XCTAssertNil(empty.supportEmailURL)
        XCTAssertFalse(empty.hasAnyLink)
    }

    @MainActor
    func testResetTutorialProgressRoutesImmediatelyToTutorial() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true

        let viewModel = ThreadRootViewModel(store: store)
        viewModel.openSettings()
        viewModel.resetTutorialProgress()

        XCTAssertEqual(viewModel.screen, .tutorial)
        XCTAssertFalse(store.tutorialCompleted)
    }

    @MainActor
    func testClearLocalProgressRoutesImmediatelyToDailyWhenTutorialAlreadyCompleted() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true
        _ = store.upsertHistoryEntry(
            DailyHistoryEntry(
                dateKey: "2026-04-04",
                roundID: 12,
                answer: "RING",
                score: 2,
                completedAt: date("2026-04-04T08:00:00Z"),
                aggregateSubmittedAt: nil
            )
        )
        store.saveSnapshot(
            GameSnapshot(
                roundID: 12,
                dateKey: "2026-04-04",
                revealedClueCount: 2,
                guess: "RI",
                attempts: ["BELL"],
                isSolved: false,
                isFailed: false
            )
        )

        let viewModel = ThreadRootViewModel(store: store)
        viewModel.openSettings()
        viewModel.clearLocalProgress()

        XCTAssertEqual(viewModel.screen, .daily)
        XCTAssertTrue(viewModel.history.isEmpty)
        XCTAssertNil(viewModel.snapshotForCurrentDailyRound())
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 12))
    }

    func testCloudSyncMergerPrefersBestHistoryResultAndLatestAggregateSubmission() {
        let local = ThreadCloudSyncState(
            preferences: ThreadPreferences.default.markedUpdated(at: date("2026-04-04T08:00:00Z")),
            history: [
                DailyHistoryEntry(
                    dateKey: "2026-04-04",
                    roundID: 12,
                    answer: "RING",
                    score: 4,
                    completedAt: date("2026-04-04T08:00:00Z"),
                    aggregateSubmittedAt: nil
                )
            ],
            snapshots: [:]
        )

        let remote = ThreadCloudSyncState(
            preferences: ThreadPreferences(
                analyticsEnabled: false,
                aggregateSharingEnabled: false,
                hapticsEnabled: true,
                updatedAt: date("2026-04-04T08:10:00Z")
            ),
            history: [
                DailyHistoryEntry(
                    dateKey: "2026-04-04",
                    roundID: 12,
                    answer: "RING",
                    score: 2,
                    completedAt: date("2026-04-04T08:05:00Z"),
                    aggregateSubmittedAt: date("2026-04-04T08:10:00Z")
                )
            ],
            snapshots: [:]
        )

        let merged = ThreadCloudSyncMerger.merge(local: local, remote: remote)

        XCTAssertEqual(merged.preferences.analyticsEnabled, false)
        XCTAssertEqual(merged.preferences.aggregateSharingEnabled, false)
        XCTAssertEqual(merged.preferences.hapticsEnabled, true)
        XCTAssertEqual(merged.preferences.updatedAt, date("2026-04-04T08:10:00Z"))
        XCTAssertEqual(merged.history.count, 1)
        XCTAssertEqual(merged.history[0].score, 2)
        XCTAssertEqual(merged.history[0].completedAt, date("2026-04-04T08:00:00Z"))
        XCTAssertEqual(merged.history[0].aggregateSubmittedAt, date("2026-04-04T08:10:00Z"))
    }

    func testCloudSyncMergerKeepsLocalPreferencesWhenRemotePreferencesMissing() {
        let localPreferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: false,
            hapticsEnabled: true
        )

        let merged = ThreadCloudSyncMerger.merge(
            local: ThreadCloudSyncState(
                preferences: localPreferences,
                history: [],
                snapshots: [:]
            ),
            remotePreferences: nil,
            remoteHistory: [],
            remoteSnapshots: [:]
        )

        XCTAssertEqual(merged.preferences, localPreferences)
    }

    func testCloudSyncMergerKeepsNewerLocalPreferencesWhenRemoteIsOlder() {
        let localPreferences = ThreadPreferences(
            analyticsEnabled: true,
            aggregateSharingEnabled: false,
            hapticsEnabled: false,
            dailyRemindersEnabled: true,
            updatedAt: date("2026-04-06T08:00:00Z")
        )
        let remotePreferences = ThreadPreferences(
            analyticsEnabled: false,
            aggregateSharingEnabled: true,
            hapticsEnabled: true,
            dailyRemindersEnabled: false,
            updatedAt: date("2026-04-05T08:00:00Z")
        )

        let merged = ThreadCloudSyncMerger.merge(
            local: ThreadCloudSyncState(
                preferences: localPreferences,
                history: [],
                snapshots: [:]
            ),
            remotePreferences: remotePreferences,
            remoteHistory: [],
            remoteSnapshots: [:]
        )

        XCTAssertEqual(merged.preferences, localPreferences)
    }

    func testCloudSyncMergerPrefersNewestSnapshot() {
        let local = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 2,
            guess: "RI",
            attempts: ["BELL"],
            isSolved: false,
            isFailed: false,
            updatedAt: date("2026-04-04T08:00:00Z")
        )
        let remote = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 3,
            guess: "RIN",
            attempts: ["BELL", "CROWN"],
            isSolved: false,
            isFailed: false,
            updatedAt: date("2026-04-04T08:01:00Z")
        )

        let merged = ThreadCloudSyncMerger.merge(local: local, remote: remote)

        XCTAssertEqual(merged, remote)
    }

    func testCloudSyncMergerPrefersSolvedSnapshotWhenTimestampsTie() {
        let timestamp = date("2026-04-04T08:01:00Z")
        let local = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 2,
            guess: "RING",
            attempts: ["BELL", "RING"],
            isSolved: true,
            isFailed: false,
            updatedAt: timestamp
        )
        let remote = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 5,
            guess: "",
            attempts: ["BELL", "CROWN", "BRASS"],
            isSolved: false,
            isFailed: true,
            updatedAt: timestamp
        )

        let merged = ThreadCloudSyncMerger.merge(local: local, remote: remote)

        XCTAssertEqual(merged, local)
    }

    func testCloudSyncMergerDropsSnapshotWhenHistoryExistsForSameDay() {
        let dateKey = "2026-04-04"
        let snapshot = GameSnapshot(
            roundID: 12,
            dateKey: dateKey,
            revealedClueCount: 5,
            guess: "",
            attempts: ["BELL", "CROWN", "BRASS", "STONE"],
            isSolved: false,
            isFailed: false,
            updatedAt: date("2026-04-04T08:01:00Z")
        )

        let merged = ThreadCloudSyncMerger.merge(
            local: ThreadCloudSyncState(
                preferences: .default,
                history: [
                    DailyHistoryEntry(
                        dateKey: dateKey,
                        roundID: 12,
                        answer: "RING",
                        score: nil,
                        completedAt: date("2026-04-04T08:02:00Z"),
                        aggregateSubmittedAt: nil
                    )
                ],
                snapshots: [dateKey: snapshot]
            ),
            remote: ThreadCloudSyncState(
                preferences: .default,
                history: [],
                snapshots: [:]
            )
        )

        XCTAssertNil(merged.snapshots[dateKey])
        XCTAssertEqual(merged.history.count, 1)
    }

    @MainActor
    func testGameViewModelCompletionSummaryPreservesSavedTimingContext() {
        let snapshot = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 3,
            guess: "",
            attempts: ["BELL", "CROWN"],
            isSolved: true,
            isFailed: false,
            startedAt: date("2026-04-04T08:00:00Z"),
            firstSubmittedGuessAt: date("2026-04-04T08:00:12Z"),
            updatedAt: date("2026-04-04T08:01:00Z")
        )

        let viewModel = ThreadGameViewModel(
            round: ThreadRound(id: 12, sourcePool: "test", answer: "RING", acceptedAnswers: ["RING"], clues: sampleClues),
            dateKey: "2026-04-04",
            snapshot: snapshot
        )

        let summary = viewModel.completionSummary(now: date("2026-04-04T08:01:34Z"))

        XCTAssertEqual(summary.score, 3)
        XCTAssertEqual(summary.cluesUsed, 3)
        XCTAssertEqual(summary.wrongGuessCount, 2)
        XCTAssertEqual(summary.solveDurationSeconds, 94)
        XCTAssertEqual(summary.timeToFirstGuessSeconds, 12)
        XCTAssertTrue(summary.resumedSavedProgress)
    }

    func testAnalyticsRoundFinishedEventUsesPrivacySafeProperties() {
        let event = AnalyticsEvent.roundFinished(
            mode: "daily",
            result: "solved",
            roundID: 47,
            roundNumber: 47,
            dateKey: "2026-04-07",
            currentStreak: 5,
            completion: ThreadRoundCompletion(
                score: 3,
                cluesUsed: 3,
                wrongGuessCount: 2,
                solveDurationSeconds: 94,
                timeToFirstGuessSeconds: 12,
                resumedSavedProgress: false
            )
        )

        XCTAssertEqual(event.name, "round_finished")
        XCTAssertEqual(event.properties["mode"], "daily")
        XCTAssertEqual(event.properties["round_id"], "47")
        XCTAssertEqual(event.properties["score"], "3")
        XCTAssertEqual(event.properties["solve_duration_seconds"], "94")
        XCTAssertEqual(event.properties["current_streak_bucket"], "4-6")
        XCTAssertNil(event.properties["guess"])
        XCTAssertNil(event.properties["apple_id"])
    }

    private func date(_ raw: String) -> Date {
        ISO8601DateFormatter().date(from: raw)!
    }

    private var resourcesURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Thread")
            .appendingPathComponent("Resources")
    }

    private var sampleClues: [RoundClue] {
        [
            RoundClue(word: "FIGURE", connection: "Figurehead"),
            RoundClue(word: "NAIL", connection: "Hit the nail on the head"),
            RoundClue(word: "QUARTERS", connection: "Headquarters"),
            RoundClue(word: "LINE", connection: "Headline"),
            RoundClue(word: "BED", connection: "Bed head"),
        ]
    }

    @MainActor
    private func settleAsyncWork() async {
        await Task.yield()
        await Task.yield()
    }
}

actor TestNotificationService: ThreadNotificationManaging {
    private var status: ThreadNotificationAuthorizationStatus
    private let requestResultStatus: ThreadNotificationAuthorizationStatus?
    private var requestCount = 0
    private var scheduledContexts: [ThreadReminderContext] = []
    private var removedCount = 0
    private var debugRequests: [ThreadDebugNotificationRequest] = []

    init(
        status: ThreadNotificationAuthorizationStatus,
        requestResultStatus: ThreadNotificationAuthorizationStatus? = nil
    ) {
        self.status = status
        self.requestResultStatus = requestResultStatus
    }

    func authorizationStatus() async -> ThreadNotificationAuthorizationStatus {
        status
    }

    func requestAuthorization() async -> ThreadNotificationAuthorizationStatus {
        requestCount += 1
        if let requestResultStatus {
            status = requestResultStatus
        }
        return status
    }

    func scheduleDailyReminders(context: ThreadReminderContext) async {
        scheduledContexts.append(context)
    }

    func removeDailyReminders() async {
        removedCount += 1
    }

    func debugPendingRequests() async -> [ThreadDebugNotificationRequest] {
        debugRequests
    }

    func scheduleDebugReminder(after seconds: TimeInterval) async {
        debugRequests.append(
            ThreadDebugNotificationRequest(
                identifier: "thread.debug-reminder.test",
                title: "Thread debug reminder",
                body: "If you can see this, local notifications are working.",
                nextTriggerDate: Date().addingTimeInterval(seconds)
            )
        )
    }

    func requestAuthorizationCount() -> Int {
        requestCount
    }

    func scheduledReminderCount() -> Int {
        scheduledContexts.count
    }

    func removeCount() -> Int {
        removedCount
    }

    func setStatus(_ newStatus: ThreadNotificationAuthorizationStatus) {
        status = newStatus
    }
}
