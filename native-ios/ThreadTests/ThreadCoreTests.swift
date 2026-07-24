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

    func testDefaultSchedulerUsesWebsiteLondonBoundary() {
        let rounds = [
            ThreadRound(id: 1, sourcePool: "test", answer: "HEAD", acceptedAnswers: ["HEAD"], clues: sampleClues),
            ThreadRound(id: 2, sourcePool: "test", answer: "HAND", acceptedAnswers: ["HAND"], clues: sampleClues),
        ]

        let scheduler = DailyScheduler(
            rounds: rounds,
            anchorComponents: DateComponents(year: 2026, month: 4, day: 4)
        )

        XCTAssertEqual(scheduler.timeZone.identifier, DailyScheduler.canonicalTimeZoneID)
        XCTAssertEqual(scheduler.todayDateKey(now: date("2026-04-04T23:30:00Z")), "2026-04-05")
        XCTAssertEqual(scheduler.roundForToday(now: date("2026-04-04T23:30:00Z")).id, 2)
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

    func testSchedulerBuildsArchiveAcrossReplacementPoolBoundary() {
        let rounds = [
            ThreadRound(id: 1, sourcePool: "legacyDaily", answer: "HEAD", acceptedAnswers: ["HEAD"], clues: sampleClues),
            ThreadRound(id: 2, sourcePool: "legacyDaily", answer: "HAND", acceptedAnswers: ["HAND"], clues: sampleClues),
            ThreadRound(id: 3, sourcePool: "futureDaily", answer: "FOOT", acceptedAnswers: ["FOOT"], clues: sampleClues),
            ThreadRound(id: 4, sourcePool: "futureDaily", answer: "RING", acceptedAnswers: ["RING"], clues: sampleClues),
        ]
        let scheduler = DailyScheduler(
            rounds: rounds,
            timeZoneID: "Europe/London",
            anchorComponents: DateComponents(year: 2026, month: 4, day: 1),
            roundSelectionAnchorComponents: DateComponents(year: 2026, month: 4, day: 3),
            futureShuffleSeed: 42
        )

        let archive = scheduler.archivePuzzles(now: date("2026-04-05T10:00:00Z"))

        XCTAssertEqual(archive.map(\.dateKey), ["2026-04-01", "2026-04-02", "2026-04-03", "2026-04-04"])
        XCTAssertEqual(archive.map(\.roundNumber), [1, 2, 3, 4])
        XCTAssertEqual(archive[0].round.id, 1)
        XCTAssertEqual(archive[1].round.id, 2)
        XCTAssertEqual(archive[2].round.sourcePool, "futureDaily")
        XCTAssertEqual(archive[3].round.sourcePool, "futureDaily")
    }

    func testBundledScheduleMapsMarchResetToThread44() throws {
        let scheduler = DailyScheduler(rounds: try ThreadRepository().loadDailyRounds())
        let lastLegacyDate = date("2026-03-30T12:00:00Z")
        let resetDate = date("2026-03-31T12:00:00Z")

        XCTAssertEqual(scheduler.dayNumber(now: lastLegacyDate), 43)
        XCTAssertEqual(scheduler.round(for: lastLegacyDate).id, 43)
        XCTAssertEqual(scheduler.dayNumber(now: resetDate), 44)
        XCTAssertEqual(scheduler.round(for: resetDate).sourcePool, "futureDaily")
    }

    func testArchiveStopsBeforeCurrentLondonDayAcrossDSTBoundary() throws {
        let scheduler = DailyScheduler(rounds: try ThreadRepository().loadDailyRounds())
        let archive = scheduler.archivePuzzles(now: date("2026-03-31T10:00:00Z"))

        XCTAssertEqual(archive.count, 43)
        XCTAssertEqual(archive.first?.dateKey, "2026-02-16")
        XCTAssertEqual(archive.last?.dateKey, "2026-03-30")
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

    func testStreakBadgeLogicEarnsMilestonesUpToBestStreak() {
        let displays = ThreadStreakBadgeLogic.displayItems(bestStreak: 32)

        XCTAssertEqual(displays.filter(\.isEarned).map(\.milestone), [.day7, .day14, .day30])
        XCTAssertEqual(displays.filter { !$0.isEarned }.map(\.milestone), [.day50, .day100, .day200, .day365])
    }

    func testStreakBadgeLogicReturnsNewUnlockAtExactMilestone() {
        let milestone = ThreadStreakBadgeLogic.newlyUnlockedMilestone(
            projectedSolvedStreak: 7,
            bestStreakBeforeToday: 6,
            shownMilestones: []
        )

        XCTAssertEqual(milestone, .day7)
    }

    func testStreakBadgeLogicDoesNotRepeatShownUnlock() {
        let milestone = ThreadStreakBadgeLogic.newlyUnlockedMilestone(
            projectedSolvedStreak: 30,
            bestStreakBeforeToday: 29,
            shownMilestones: [.day30]
        )

        XCTAssertNil(milestone)
    }

#if DEBUG
    @MainActor
    func testDebugBadgePreviewStatePersistsOverrides() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let viewModel = ThreadRootViewModel(store: store)

        viewModel.previewBadgeCollection(currentStreak: 14, bestStreak: 30)
        XCTAssertEqual(store.debugBadgePreviewState.currentStreakOverride, 14)
        XCTAssertEqual(store.debugBadgePreviewState.bestStreakOverride, 30)

        viewModel.previewBadgeUnlock(.day7)
        XCTAssertEqual(store.debugBadgePreviewState.unlockPreviewMilestone, .day7)

        let reloadedViewModel = ThreadRootViewModel(store: store)
        XCTAssertEqual(reloadedViewModel.debugBadgePreviewState.currentStreakOverride, 14)
        XCTAssertEqual(reloadedViewModel.debugBadgePreviewState.bestStreakOverride, 30)
        XCTAssertEqual(reloadedViewModel.debugBadgePreviewState.unlockPreviewMilestone, .day7)

        viewModel.clearBadgeDebugPreviews()
        XCTAssertEqual(store.debugBadgePreviewState, .default)
    }
#endif

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
        await waitUntil { viewModel.notificationPrompt?.kind == .requestAuthorization }

        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        XCTAssertEqual(viewModel.notificationPrompt?.kind, .requestAuthorization)
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(scheduledReminderCount, 0)
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
        await waitUntil { viewModel.notificationPrompt?.kind == .requestAuthorization }
        await viewModel.confirmNotificationPrompt()
        await waitUntil { viewModel.preferences.dailyRemindersEnabled }

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertNil(viewModel.notificationPrompt)
        let requestAuthorizationCount = await notifications.requestAuthorizationCount()
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(requestAuthorizationCount, 1)
        XCTAssertEqual(scheduledReminderCount, 1)
    }

    @MainActor
    func testAlertDismissalDuringConfirmDoesNotCancelReminderEnable() async {
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
        await waitUntil { viewModel.notificationPrompt?.kind == .requestAuthorization }
        let prompt = try! XCTUnwrap(viewModel.notificationPrompt)

        viewModel.clearNotificationPromptPresentation()
        XCTAssertNil(viewModel.notificationPrompt)
        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)

        await viewModel.confirmNotificationPrompt(prompt)
        await waitUntil { viewModel.preferences.dailyRemindersEnabled }

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertFalse(viewModel.pendingDailyRemindersEnableRequest)
        let requestAuthorizationCount = await notifications.requestAuthorizationCount()
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(requestAuthorizationCount, 1)
        XCTAssertEqual(scheduledReminderCount, 1)
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
        await waitUntil { viewModel.notificationPrompt?.kind == .requestAuthorization }
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
        await waitUntil { viewModel.preferences.dailyRemindersEnabled }

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertNil(viewModel.notificationPrompt)
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(scheduledReminderCount, 1)
    }

    @MainActor
    func testEnablingDailyRemindersWhenDeniedShowsSettingsPromptWithoutEnabling() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let notifications = TestNotificationService(status: .denied)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        viewModel.setDailyRemindersEnabled(true)
        await waitUntil { viewModel.notificationPrompt?.kind == .openSettings }

        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertFalse(viewModel.displayedDailyRemindersEnabled)
        XCTAssertEqual(viewModel.notificationPrompt?.kind, .openSettings)
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(scheduledReminderCount, 0)
    }

    @MainActor
    func testDisablingDailyRemindersRemovesScheduledReminders() async {
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
        await waitUntil { viewModel.preferences.dailyRemindersEnabled }
        viewModel.setDailyRemindersEnabled(false)
        await waitUntil { !viewModel.preferences.dailyRemindersEnabled }

        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertFalse(viewModel.displayedDailyRemindersEnabled)
        let removeCount = await notifications.removeCount()
        XCTAssertEqual(removeCount, 1)
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
        await waitUntil { viewModel.notificationPrompt?.kind == .requestAuthorization }

        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        XCTAssertFalse(viewModel.preferences.dailyRemindersEnabled)

        await notifications.setStatus(.authorized)
        await viewModel.handleScenePhaseChange(.active)
        await waitUntil { viewModel.preferences.dailyRemindersEnabled }

        XCTAssertTrue(viewModel.preferences.dailyRemindersEnabled)
        XCTAssertTrue(viewModel.displayedDailyRemindersEnabled)
        let scheduledReminderCount = await notifications.scheduledReminderCount()
        XCTAssertEqual(scheduledReminderCount, 1)
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
    func testLocalThreadStorePersistsArchiveProgressSeparately() {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")
        let store = LocalThreadStore(defaults: defaults)
        let snapshot = GameSnapshot(
            roundID: 12,
            dateKey: "2026-04-04",
            revealedClueCount: 3,
            guess: "RI",
            attempts: ["BELL", "CROWN"],
            isSolved: false,
            isFailed: false
        )
        let entry = ThreadArchiveHistoryEntry(
            dateKey: "2026-04-03",
            roundID: 11,
            answer: "HEAD",
            score: 2,
            completedAt: date("2026-04-05T08:00:00Z")
        )

        store.saveArchiveSnapshot(snapshot)
        _ = store.upsertArchiveHistoryEntry(entry)

        XCTAssertEqual(store.loadArchiveSnapshot(for: "2026-04-04", roundID: 12), snapshot)
        XCTAssertEqual(store.loadArchiveHistory(), [entry])
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertTrue(store.loadAllSnapshots().isEmpty)

        store.clearArchiveProgress()
        XCTAssertTrue(store.loadArchiveHistory().isEmpty)
        XCTAssertTrue(store.loadAllArchiveSnapshots().isEmpty)
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
        _ = store.upsertArchiveHistoryEntry(
            ThreadArchiveHistoryEntry(
                dateKey: "2026-04-03",
                roundID: 11,
                answer: "HEAD",
                score: 3,
                completedAt: date("2026-04-03T08:00:00Z")
            )
        )
        store.saveArchiveSnapshot(
            GameSnapshot(
                roundID: 10,
                dateKey: "2026-04-02",
                revealedClueCount: 3,
                guess: "HA",
                attempts: ["BELL", "CROWN"],
                isSolved: false,
                isFailed: false
            )
        )
        store.clearGameplayProgress()

        XCTAssertTrue(store.tutorialCompleted)
        XCTAssertTrue(store.loadHistory().isEmpty)
        XCTAssertNil(store.loadSnapshot(for: "2026-04-04", roundID: 12))
        XCTAssertTrue(store.loadArchiveHistory().isEmpty)
        XCTAssertTrue(store.loadAllArchiveSnapshots().isEmpty)
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
            privacyPolicyURL: URL(string: "https://daily-thread.co/privacy"),
            appStoreURL: nil
        )

        XCTAssertEqual(configured.supportEmailURL?.absoluteString, "mailto:zmailinglist@gmail.com")
        XCTAssertTrue(configured.hasAnyLink)

        let empty = ThreadExternalLinks(
            supportURL: nil,
            supportEmailAddress: nil,
            privacyPolicyURL: nil,
            appStoreURL: nil
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
    func testClearLocalProgressRoutesImmediatelyToTutorialFirstLaunch() async {
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
        store.tutorialCompleted = true
        await viewModel.bootstrapIfNeeded()
        viewModel.openSettings()
        viewModel.clearLocalProgress()
        await waitUntil { viewModel.screen == .tutorial }

        XCTAssertEqual(viewModel.screen, .tutorial)
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
                totalGuessCount: 5,
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

    @MainActor
    func testCompletingDailyKeepsDisplayableResultForResultsScreen() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let viewModel = ThreadRootViewModel(
            store: LocalThreadStore(defaults: defaults),
            analytics: NoopAnalyticsClient(),
            notifications: TestNotificationService(status: .authorized)
        )

        await viewModel.bootstrapIfNeeded()

        guard let round = viewModel.dailyRound else {
            return XCTFail("Expected daily round to load")
        }

        viewModel.completeDaily(
            completion: ThreadRoundCompletion(
                score: 5,
                cluesUsed: 5,
                wrongGuessCount: 0,
                totalGuessCount: 1,
                solveDurationSeconds: 20,
                timeToFirstGuessSeconds: 12,
                resumedSavedProgress: false
            )
        )

        XCTAssertEqual(viewModel.screen, .results)
        XCTAssertEqual(viewModel.displayedDailyResult?.roundID, round.id)
        XCTAssertEqual(viewModel.displayedDailyResult?.dateKey, viewModel.todayDateKey)
        XCTAssertEqual(viewModel.displayedDailyResult?.score, 5)
        XCTAssertEqual(viewModel.projectedSolvedDailyStreakCount, 1)
    }

    @MainActor
    func testCompletingArchiveDoesNotChangeDailyStatsOrStreak() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")
        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: NoopThreadPrivateCloudSyncService(),
            notifications: TestNotificationService(status: .authorized)
        )

        await viewModel.bootstrapIfNeeded()
        guard let item = viewModel.archiveItems.last else {
            return XCTFail("Expected at least one archived Thread")
        }

        viewModel.openArchive()
        viewModel.openArchiveItem(item.puzzle.dateKey)
        XCTAssertEqual(viewModel.screen, .archiveRound(item.puzzle.dateKey))

        let snapshot = GameSnapshot(
            roundID: item.puzzle.round.id,
            dateKey: item.puzzle.dateKey,
            revealedClueCount: 2,
            guess: "",
            attempts: ["BELL"],
            isSolved: false,
            isFailed: false
        )
        viewModel.updateArchiveSnapshot(snapshot)
        XCTAssertEqual(store.loadArchiveSnapshot(for: item.puzzle.dateKey, roundID: item.puzzle.round.id), snapshot)

        viewModel.completeArchive(
            puzzle: item.puzzle,
            completion: ThreadRoundCompletion(
                score: 3,
                cluesUsed: 3,
                wrongGuessCount: 2,
                totalGuessCount: 3,
                solveDurationSeconds: 40,
                timeToFirstGuessSeconds: 10,
                resumedSavedProgress: false
            )
        )

        XCTAssertEqual(viewModel.screen, .archive)
        XCTAssertEqual(viewModel.archiveHistory.first?.dateKey, item.puzzle.dateKey)
        XCTAssertNil(store.loadArchiveSnapshot(for: item.puzzle.dateKey, roundID: item.puzzle.round.id))
        XCTAssertTrue(viewModel.history.isEmpty)
        XCTAssertEqual(viewModel.displayedStatsSummary.totalPlayed, 0)
        XCTAssertEqual(viewModel.displayedStatsCurrentStreak, 0)

        viewModel.openArchiveItem(item.puzzle.dateKey)
        XCTAssertEqual(viewModel.screen, .archiveResult(item.puzzle.dateKey))
    }

    @MainActor
    func testPastDailySnapshotMigratesIntoArchiveWithoutLosingProgress() async throws {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")
        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true

        let scheduler = DailyScheduler(rounds: try ThreadRepository().loadDailyRounds())
        let yesterday = try XCTUnwrap(
            scheduler.calendar.date(byAdding: .day, value: -1, to: scheduler.startOfDay(for: .now))
        )
        let dateKey = DateKeyFormatter.storage.string(from: yesterday, timeZone: scheduler.timeZone)
        let round = scheduler.round(for: yesterday)
        let snapshot = GameSnapshot(
            roundID: round.id,
            dateKey: dateKey,
            revealedClueCount: 3,
            guess: "HEAD",
            attempts: ["TAIL", "BED"],
            isSolved: false,
            isFailed: false
        )
        store.saveSnapshot(snapshot)

        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: NoopThreadPrivateCloudSyncService(),
            notifications: TestNotificationService(status: .authorized)
        )
        await viewModel.bootstrapIfNeeded()

        XCTAssertNil(store.loadSnapshot(for: dateKey, roundID: round.id))
        XCTAssertEqual(store.loadArchiveSnapshot(for: dateKey, roundID: round.id), snapshot)
        XCTAssertEqual(
            viewModel.archiveItem(for: dateKey)?.status,
            .inProgress(revealedClueCount: 3)
        )
    }

    @MainActor
    func testSolvedPastDailySnapshotMigratesIntoFinishedArchiveHistory() async throws {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")
        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true

        let scheduler = DailyScheduler(rounds: try ThreadRepository().loadDailyRounds())
        let yesterday = try XCTUnwrap(
            scheduler.calendar.date(byAdding: .day, value: -1, to: scheduler.startOfDay(for: .now))
        )
        let dateKey = DateKeyFormatter.storage.string(from: yesterday, timeZone: scheduler.timeZone)
        let round = scheduler.round(for: yesterday)
        store.saveSnapshot(
            GameSnapshot(
                roundID: round.id,
                dateKey: dateKey,
                revealedClueCount: 2,
                guess: round.answer,
                attempts: ["WRONG"],
                isSolved: true,
                isFailed: false
            )
        )

        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: NoopThreadPrivateCloudSyncService(),
            notifications: TestNotificationService(status: .authorized)
        )
        await viewModel.bootstrapIfNeeded()

        XCTAssertNil(store.loadSnapshot(for: dateKey, roundID: round.id))
        XCTAssertNil(store.loadArchiveSnapshot(for: dateKey, roundID: round.id))
        XCTAssertEqual(viewModel.archiveHistory.first?.dateKey, dateKey)
        XCTAssertEqual(viewModel.archiveHistory.first?.score, 2)
        XCTAssertEqual(viewModel.archiveItem(for: dateKey)?.status, .finished(score: 2))
    }

    @MainActor
    func testCompletingDailyReschedulesRemindersWithoutEveningReminder() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        store.preferences = ThreadPreferences(
            analyticsEnabled: true,
            aggregateSharingEnabled: true,
            hapticsEnabled: true,
            dailyRemindersEnabled: true
        )
        let notifications = TestNotificationService(status: .authorized)
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            notifications: notifications
        )

        await viewModel.bootstrapIfNeeded()
        viewModel.completeDaily(
            completion: ThreadRoundCompletion(
                score: 5,
                cluesUsed: 5,
                wrongGuessCount: 0,
                totalGuessCount: 1,
                solveDurationSeconds: 20,
                timeToFirstGuessSeconds: 12,
                resumedSavedProgress: false
            )
        )
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(1)
        var scheduledContexts = await notifications.scheduledReminderContexts()
        while !scheduledContexts.contains(where: { $0.hasSolvedToday }) && clock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
            scheduledContexts = await notifications.scheduledReminderContexts()
        }

        XCTAssertEqual(scheduledContexts.last?.hasSolvedToday, true)
    }

    @MainActor
    func testBootstrapShowsLocalDailyBeforeCloudSyncFinishes() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true
        let cloud = SequencedPrivateCloudSyncService(
            responses: [nil],
            delayedSyncNumbers: [1]
        )
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: cloud,
            notifications: TestNotificationService(status: .authorized)
        )

        let bootstrapTask = Task { @MainActor in
            await viewModel.bootstrapIfNeeded()
        }
        await cloud.waitForSyncToSuspend(number: 1)

        let isSyncSuspended = await cloud.isSyncSuspended(number: 1)
        XCTAssertTrue(isSyncSuspended)
        XCTAssertEqual(viewModel.screen, .daily)

        await cloud.resumeSync(number: 1)
        await bootstrapTask.value
    }

    @MainActor
    func testBootstrapCloudHistoryReconcilesToAlreadyPlayed() async throws {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        let dailyRounds = try ThreadRepository().loadDailyRounds()
        let scheduler = DailyScheduler(
            rounds: dailyRounds
        )
        let todaysRound = scheduler.roundForToday()
        let todaysDateKey = scheduler.todayDateKey()
        let cloudEntry = DailyHistoryEntry(
            dateKey: todaysDateKey,
            roundID: todaysRound.id,
            answer: todaysRound.answer,
            score: 3,
            completedAt: date("2026-04-04T08:00:00Z"),
            aggregateSubmittedAt: nil
        )
        let cloud = SequencedPrivateCloudSyncService(
            responses: [
                ThreadCloudSyncState(
                    preferences: .default,
                    history: [cloudEntry],
                    snapshots: [:]
                )
            ]
        )
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: cloud,
            notifications: TestNotificationService(status: .authorized)
        )

        await viewModel.bootstrapIfNeeded()

        XCTAssertEqual(viewModel.screen, .alreadyPlayed)
        XCTAssertEqual(viewModel.displayedDailyResult, cloudEntry)
        XCTAssertTrue(store.tutorialCompleted)
    }

    @MainActor
    func testCloudSyncFinishingAfterCompletionDoesNotClearResultsScreen() async {
        let defaults = UserDefaults(suiteName: "ThreadCoreTests.\(#function)")!
        defaults.removePersistentDomain(forName: "ThreadCoreTests.\(#function)")

        let store = LocalThreadStore(defaults: defaults)
        store.tutorialCompleted = true
        let cloud = SequencedPrivateCloudSyncService(
            responses: [
                nil,
                ThreadCloudSyncState(
                    preferences: .default,
                    history: [],
                    snapshots: [:]
                )
            ],
            delayedSyncNumbers: [2]
        )
        let viewModel = ThreadRootViewModel(
            store: store,
            analytics: NoopAnalyticsClient(),
            privateCloudSync: cloud,
            notifications: TestNotificationService(status: .authorized)
        )

        await viewModel.bootstrapIfNeeded()

        guard let round = viewModel.dailyRound else {
            return XCTFail("Expected daily round to load")
        }

        let refreshTask = Task { @MainActor in
            await viewModel.handleScenePhaseChange(.active)
        }
        await cloud.waitForSyncToSuspend(number: 2)

        viewModel.completeDaily(
            completion: ThreadRoundCompletion(
                score: 4,
                cluesUsed: 4,
                wrongGuessCount: 0,
                totalGuessCount: 1,
                solveDurationSeconds: 25,
                timeToFirstGuessSeconds: 10,
                resumedSavedProgress: false
            )
        )

        await cloud.resumeSync(number: 2)
        await refreshTask.value

        XCTAssertEqual(viewModel.screen, .results)
        XCTAssertEqual(viewModel.displayedDailyResult?.roundID, round.id)
        XCTAssertEqual(viewModel.displayedDailyResult?.dateKey, viewModel.todayDateKey)
        XCTAssertEqual(viewModel.displayedDailyResult?.score, 4)
        XCTAssertEqual(store.loadHistory().first?.score, 4)
    }

    @MainActor
    func testArchivePurchaseControllerLoadsProductAndExistingEntitlement() async {
        let service = TestArchivePurchaseService(isEntitled: true)
        let controller = ThreadArchivePurchaseController(service: service)

        await controller.start()

        XCTAssertTrue(controller.isEntitled)
        XCTAssertEqual(controller.product?.displayName, "Thread Archive")
        XCTAssertEqual(controller.product?.displayPrice, "£0.99")
        XCTAssertNil(controller.message)
    }

    @MainActor
    func testArchivePurchaseControllerUnlocksAfterVerifiedPurchase() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            purchaseOutcome: .purchased
        )
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        let unlocked = await controller.purchase()

        XCTAssertTrue(unlocked)
        XCTAssertTrue(controller.isEntitled)
        XCTAssertNil(controller.message)
    }

    @MainActor
    func testArchivePurchaseControllerKeepsPendingPurchaseLocked() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            purchaseOutcome: .pending
        )
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        let unlocked = await controller.purchase()

        XCTAssertFalse(unlocked)
        XCTAssertFalse(controller.isEntitled)
        XCTAssertEqual(
            controller.message,
            "Purchase pending approval. The Archive will unlock automatically once approved."
        )
    }

    @MainActor
    func testArchivePurchaseControllerReportsMissingRestore() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            restoredEntitlement: false
        )
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        let restored = await controller.restore()

        XCTAssertFalse(restored)
        XCTAssertFalse(controller.isEntitled)
        XCTAssertEqual(controller.message, "No Archive purchase was found for this Apple Account.")
    }

    @MainActor
    func testArchivePurchaseControllerRestoresExistingPurchase() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            restoredEntitlement: true
        )
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        let restored = await controller.restore()

        XCTAssertTrue(restored)
        XCTAssertTrue(controller.isEntitled)
        XCTAssertEqual(controller.message, "Archive purchase restored.")
    }

    @MainActor
    func testArchivePurchaseControllerDoesNotUnlockAfterCancellation() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            purchaseOutcome: .cancelled
        )
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        let unlocked = await controller.purchase()

        XCTAssertFalse(unlocked)
        XCTAssertFalse(controller.isEntitled)
        XCTAssertNil(controller.message)
    }

    @MainActor
    func testArchivePurchaseControllerRetriesFailedProductLoad() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            productLoadFailuresRemaining: 1
        )
        let controller = ThreadArchivePurchaseController(service: service)

        await controller.start()
        XCTAssertNil(controller.product)
        XCTAssertEqual(
            controller.message,
            ThreadArchiveStoreError.productUnavailable.localizedDescription
        )

        await controller.retryProductLoad()

        XCTAssertEqual(controller.product?.displayName, "Thread Archive")
        XCTAssertNil(controller.message)
    }

    @MainActor
    func testArchivePurchaseControllerKeepsNewerEntitlementUpdateDuringStartup() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            entitlementLookupDelay: .milliseconds(100)
        )
        let controller = ThreadArchivePurchaseController(service: service)

        let startTask = Task {
            await controller.start()
        }
        await Task.yield()
        await service.sendEntitlementUpdate(true)
        await startTask.value

        XCTAssertTrue(controller.isEntitled)
    }

    @MainActor
    func testArchivePurchaseControllerKeepsSuccessfulRestoreDuringStartup() async {
        let service = TestArchivePurchaseService(
            isEntitled: false,
            restoredEntitlement: true,
            entitlementLookupDelay: .milliseconds(100)
        )
        let controller = ThreadArchivePurchaseController(service: service)

        let startTask = Task {
            await controller.start()
        }
        await Task.yield()
        let restored = await controller.restore()
        await startTask.value

        XCTAssertTrue(restored)
        XCTAssertTrue(controller.isEntitled)
    }

    @MainActor
    func testArchivePurchaseControllerLocksAfterRevocationUpdate() async {
        let service = TestArchivePurchaseService(isEntitled: true)
        let controller = ThreadArchivePurchaseController(service: service)
        await controller.start()

        await service.sendEntitlementUpdate(false)
        await waitUntil {
            !controller.isEntitled
        }

        XCTAssertFalse(controller.isEntitled)
    }

    func testArchiveStoreKitConfigurationMatchesProductionProduct() throws {
        let configurationURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("StoreKit/Archive.storekit")
        let data = try Data(contentsOf: configurationURL)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let products = try XCTUnwrap(object["products"] as? [[String: Any]])
        let product = try XCTUnwrap(products.first)
        let localizations = try XCTUnwrap(product["localizations"] as? [[String: Any]])
        let english = try XCTUnwrap(localizations.first(where: { $0["locale"] as? String == "en_GB" }))

        XCTAssertEqual(product["productID"] as? String, StoreKitThreadArchivePurchaseService.productID)
        XCTAssertEqual(product["type"] as? String, "NonConsumable")
        XCTAssertEqual(product["displayPrice"] as? String, "0.99")
        XCTAssertEqual(english["displayName"] as? String, "Thread Archive")
        XCTAssertEqual(english["description"] as? String, "Play every past Daily Thread.")
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

    @MainActor
    private func waitUntil(
        timeout: Duration = .seconds(1),
        pollInterval: Duration = .milliseconds(10),
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while !condition() {
            guard clock.now < deadline else { return }
            try? await Task.sleep(for: pollInterval)
        }
    }

}

actor TestArchivePurchaseService: ThreadArchivePurchaseServicing {
    nonisolated private let entitlementUpdateStream: AsyncStream<Bool>
    nonisolated private let entitlementUpdateContinuation: AsyncStream<Bool>.Continuation
    private let product = ThreadArchiveStoreProduct(
        displayName: "Thread Archive",
        description: "Play every past Daily Thread.",
        displayPrice: "£0.99"
    )
    private var isEntitled: Bool
    private let purchaseOutcome: ThreadArchivePurchaseOutcome
    private let restoredEntitlement: Bool
    private let entitlementLookupDelay: Duration?
    private var productLoadFailuresRemaining: Int

    init(
        isEntitled: Bool,
        purchaseOutcome: ThreadArchivePurchaseOutcome = .cancelled,
        restoredEntitlement: Bool = false,
        entitlementLookupDelay: Duration? = nil,
        productLoadFailuresRemaining: Int = 0
    ) {
        let (stream, continuation) = AsyncStream<Bool>.makeStream()
        self.entitlementUpdateStream = stream
        self.entitlementUpdateContinuation = continuation
        self.isEntitled = isEntitled
        self.purchaseOutcome = purchaseOutcome
        self.restoredEntitlement = restoredEntitlement
        self.entitlementLookupDelay = entitlementLookupDelay
        self.productLoadFailuresRemaining = productLoadFailuresRemaining
    }

    func loadProduct() async throws -> ThreadArchiveStoreProduct {
        if productLoadFailuresRemaining > 0 {
            productLoadFailuresRemaining -= 1
            throw ThreadArchiveStoreError.productUnavailable
        }
        return product
    }

    func hasCurrentEntitlement() async -> Bool {
        if let entitlementLookupDelay {
            try? await Task.sleep(for: entitlementLookupDelay)
        }
        return isEntitled
    }

    func purchase() async throws -> ThreadArchivePurchaseOutcome {
        if purchaseOutcome == .purchased {
            isEntitled = true
        }
        return purchaseOutcome
    }

    func restore() async throws -> Bool {
        isEntitled = restoredEntitlement
        return restoredEntitlement
    }

    func sendEntitlementUpdate(_ value: Bool) {
        isEntitled = value
        entitlementUpdateContinuation.yield(value)
    }

    nonisolated func entitlementUpdates() -> AsyncStream<Bool> {
        entitlementUpdateStream
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

    func scheduledReminderContexts() -> [ThreadReminderContext] {
        scheduledContexts
    }

    func removeCount() -> Int {
        removedCount
    }

    func setStatus(_ newStatus: ThreadNotificationAuthorizationStatus) {
        status = newStatus
    }
}

actor SequencedPrivateCloudSyncService: ThreadPrivateCloudSyncing {
    private var responses: [ThreadCloudSyncState?]
    private let delayedSyncNumbers: Set<Int>
    private var syncCount = 0
    private var suspendedSyncs: Set<Int> = []
    private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]

    init(
        responses: [ThreadCloudSyncState?],
        delayedSyncNumbers: Set<Int> = []
    ) {
        self.responses = responses
        self.delayedSyncNumbers = delayedSyncNumbers
    }

    func synchronize(localState: ThreadCloudSyncState) async -> ThreadCloudSyncState {
        syncCount += 1
        let currentSyncNumber = syncCount

        if delayedSyncNumbers.contains(currentSyncNumber) {
            await withCheckedContinuation { continuation in
                suspendedSyncs.insert(currentSyncNumber)
                continuations[currentSyncNumber] = continuation
            }
        }

        if responses.isEmpty {
            return localState
        }

        return responses.removeFirst() ?? localState
    }

    func upsertPreferences(_ preferences: ThreadPreferences) async {}
    func upsertHistoryEntry(_ entry: DailyHistoryEntry) async {}
    func saveSnapshot(_ snapshot: GameSnapshot) async {}
    func deleteSnapshot(for dateKey: String) async {}
    func clearHistoryAndSnapshots(historyDateKeys: [String], snapshotDateKeys: [String]) async {}

    func waitForSyncToSuspend(
        number: Int,
        timeout: Duration = .seconds(1),
        pollInterval: Duration = .milliseconds(10)
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while !suspendedSyncs.contains(number) {
            guard clock.now < deadline else { return }
            try? await Task.sleep(for: pollInterval)
        }
    }

    func isSyncSuspended(number: Int) -> Bool {
        suspendedSyncs.contains(number)
    }

    func resumeSync(number: Int) {
        continuations.removeValue(forKey: number)?.resume()
    }
}
