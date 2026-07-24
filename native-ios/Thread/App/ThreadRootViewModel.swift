import Foundation
import SwiftUI
import UIKit

enum ThreadScreen: Hashable {
    case loading
    case tutorial
    case practice(Int)
    case practiceSummary
    case daily
    case results
    case alreadyPlayed
    case archive
    case archiveRound(String)
    case archiveResult(String)
    case stats
    case settings
    case error
}

@MainActor
final class ThreadRootViewModel: ObservableObject {
    @Published private(set) var screen: ThreadScreen = .loading
    @Published private(set) var practiceRounds: [ThreadRound] = []
    @Published private(set) var dailyRound: ThreadRound?
    @Published private(set) var dailyRoundNumber = 1
    @Published private(set) var todayDateKey = ""
    @Published private(set) var practiceScores: [Int?] = []
    @Published private(set) var history: [DailyHistoryEntry] = []
    @Published private(set) var currentDailyResult: DailyHistoryEntry?
    @Published private(set) var currentDailySnapshot: GameSnapshot?
    @Published private(set) var archiveHistory: [ThreadArchiveHistoryEntry] = []
    @Published private(set) var archiveSnapshots: [String: GameSnapshot] = [:]
    @Published private(set) var preferences: ThreadPreferences = .default
    @Published private(set) var nextDailyRefreshDate: Date?
    @Published private(set) var externalLinks: ThreadExternalLinks
    @Published private(set) var bootErrorMessage: String?
    @Published private(set) var notificationAuthorizationStatus: ThreadNotificationAuthorizationStatus = .notDetermined
    @Published private(set) var remotePushStatus: ThreadRemotePushStatus = .disabled
    @Published private(set) var firstDailyNudgeStage: ThreadFirstDailyNudgeStage = .unseen
    @Published private(set) var pendingDailyRemindersEnableRequest = false
    @Published private(set) var notificationAuthorizationRequestInFlight = false
#if DEBUG
    @Published private(set) var notificationDebugSummary = "Not loaded"
    @Published private(set) var notificationDebugFeedback: String?
    @Published private(set) var debugBadgePreviewState: ThreadDebugBadgePreviewState = .default
#endif
    @Published var notificationPrompt: ThreadNotificationPrompt?

    var visibleFirstDailyNudgeStage: ThreadFirstDailyNudgeStage? {
        switch firstDailyNudgeStage {
        case .initial, .followup:
            return firstDailyNudgeStage
        case .unseen, .completed:
            return nil
        }
    }

    var displayedStatsSummary: ThreadStatsSummary {
        ThreadStatisticsBuilder.build(history: history, todayKey: todayDateKey)
    }

    var displayedStatsCurrentStreak: Int {
#if DEBUG
        debugBadgePreviewState.currentStreakOverride ?? displayedStatsSummary.currentStreak
#else
        displayedStatsSummary.currentStreak
#endif
    }

    var displayedStatsBestStreak: Int {
#if DEBUG
        debugBadgePreviewState.bestStreakOverride ?? displayedStatsSummary.bestStreak
#else
        displayedStatsSummary.bestStreak
#endif
    }

    var displayedStreakBadges: [ThreadStreakBadgeDisplay] {
        ThreadStreakBadgeLogic.displayItems(bestStreak: displayedStatsBestStreak)
    }

    var pendingStreakBadgeUnlockMilestone: ThreadStreakBadgeMilestone? {
#if DEBUG
        if let previewMilestone = debugBadgePreviewState.unlockPreviewMilestone {
            return previewMilestone
        }
#endif

        guard currentDailyResult == nil else { return nil }

        return ThreadStreakBadgeLogic.newlyUnlockedMilestone(
            projectedSolvedStreak: projectedSolvedDailyStreakCount,
            bestStreakBeforeToday: displayedStatsSummary.bestStreak,
            shownMilestones: store.shownStreakBadgeMilestones
        )
    }

    var displayedDailyResult: DailyHistoryEntry? {
        if let currentDailyResult {
            return currentDailyResult
        }

        guard let dailyRound else { return nil }
        return history.first {
            $0.dateKey == todayDateKey && $0.roundID == dailyRound.id
        }
    }

#if DEBUG
    var badgeDebugSummary: String {
        guard debugBadgePreviewState.hasAnyOverride else {
            return "Badge previews off"
        }

        var lines: [String] = []
        if let current = debugBadgePreviewState.currentStreakOverride {
            lines.append("Current streak override: \(current)")
        }
        if let best = debugBadgePreviewState.bestStreakOverride {
            lines.append("Best streak override: \(best)")
        }
        if let milestone = debugBadgePreviewState.unlockPreviewMilestone {
            lines.append("Unlock preview: \(milestone.title)")
        }

        return lines.joined(separator: "\n")
    }
#endif

    var projectedSolvedDailyStreakCount: Int? {
        if currentDailyResult?.score != nil {
            let currentStreak = currentStreakCount(for: history)
            return currentStreak >= 1 ? currentStreak : nil
        }

        guard let dailyRound else { return nil }
        guard !history.contains(where: { $0.dateKey == todayDateKey }) else {
            let currentStreak = currentStreakCount(for: history)
            return currentStreak >= 1 ? currentStreak : nil
        }

        let provisionalEntry = DailyHistoryEntry(
            dateKey: todayDateKey,
            roundID: dailyRound.id,
            answer: dailyRound.answer,
            score: 1,
            completedAt: .now,
            aggregateSubmittedAt: nil
        )
        let projectedStreak = ThreadStatisticsBuilder
            .build(history: history + [provisionalEntry], todayKey: todayDateKey)
            .currentStreak

        return projectedStreak >= 1 ? projectedStreak : nil
    }

    var displayedDailyRemindersEnabled: Bool {
        preferences.dailyRemindersEnabled || pendingDailyRemindersEnableRequest
    }

    var archiveItems: [ThreadArchiveItem] {
        guard let scheduler else { return [] }

        let dailyHistoryByDate = Dictionary(uniqueKeysWithValues: history.map { ($0.dateKey, $0) })
        let archiveHistoryByDate = Dictionary(uniqueKeysWithValues: archiveHistory.map { ($0.dateKey, $0) })

        return scheduler.archivePuzzles().reversed().map { scheduledPuzzle in
            if let dailyEntry = dailyHistoryByDate[scheduledPuzzle.dateKey] {
                let puzzle = archivePuzzle(
                    scheduledPuzzle,
                    completedRoundID: dailyEntry.roundID,
                    scheduler: scheduler
                )
                return ThreadArchiveItem(
                    puzzle: puzzle,
                    status: .finished(score: dailyEntry.score),
                    completedAnswer: dailyEntry.answer
                )
            }

            if let archiveEntry = archiveHistoryByDate[scheduledPuzzle.dateKey] {
                let puzzle = archivePuzzle(
                    scheduledPuzzle,
                    completedRoundID: archiveEntry.roundID,
                    scheduler: scheduler
                )
                return ThreadArchiveItem(
                    puzzle: puzzle,
                    status: .finished(score: archiveEntry.score),
                    completedAnswer: archiveEntry.answer
                )
            }

            if let snapshot = archiveSnapshots[scheduledPuzzle.dateKey],
               snapshot.roundID == scheduledPuzzle.round.id {
                return ThreadArchiveItem(
                    puzzle: scheduledPuzzle,
                    status: .inProgress(revealedClueCount: snapshot.revealedClueCount),
                    completedAnswer: nil
                )
            }

            return ThreadArchiveItem(
                puzzle: scheduledPuzzle,
                status: .unplayed,
                completedAnswer: nil
            )
        }
    }

    private let repository: ThreadRepository
    private let store: LocalThreadStore
    private let analytics: AnalyticsTracking
    private let aggregateStats: AggregateStatsProviding
    private let privateCloudSync: any ThreadPrivateCloudSyncing
    private let notifications: any ThreadNotificationManaging
    private let pushConfiguration: ThreadPushServiceConfiguration
    private let pushRegistration: any ThreadPushRegistrationSending
    private let resetProgressOnLaunch: Bool
    private var scheduler: DailyScheduler?
    private var hasBootstrapped = false
    private var returnScreen: ThreadScreen = .daily
    private var snapshotSyncTask: Task<Void, Never>?
    private var notificationPromptTask: Task<Void, Never>?
    private var firstDailyNudgeTask: Task<Void, Never>?
    private var analyticsSessionStartedAt: Date?
#if DEBUG
    private var pendingDebugReminderAfterAuthorization = false
#endif

    init(
        repository: ThreadRepository = ThreadRepository(),
        store: LocalThreadStore? = nil,
        analytics: AnalyticsTracking? = nil,
        aggregateStats: AggregateStatsProviding = AggregateServiceFactory.make(),
        privateCloudSync: (any ThreadPrivateCloudSyncing)? = nil,
        notifications: (any ThreadNotificationManaging)? = nil,
        pushConfiguration: ThreadPushServiceConfiguration = .fromEnvironment(),
        pushRegistration: (any ThreadPushRegistrationSending)? = nil,
        resetProgressOnLaunch: Bool? = nil,
        externalLinks: ThreadExternalLinks = .fromBundle()
    ) {
        let resolvedStore = store ?? LocalThreadStore()
        self.repository = repository
        self.store = resolvedStore
        self.analytics = analytics ?? AnalyticsServiceFactory.make()
        self.aggregateStats = aggregateStats
        self.notifications = notifications ?? ThreadNotificationService()
        self.pushConfiguration = pushConfiguration
        self.pushRegistration = pushRegistration ?? ThreadPushServiceFactory.make(configuration: pushConfiguration)
        if let privateCloudSync {
            self.privateCloudSync = privateCloudSync
        } else if ThreadCloudKitConfiguration.isEnabled() {
            self.privateCloudSync = ThreadCloudKitSyncService(
                containerIdentifier: ThreadCloudKitConfiguration.containerIdentifier()
            )
        } else {
            self.privateCloudSync = NoopThreadPrivateCloudSyncService()
        }
        let resolvedResetProgressOnLaunch = resetProgressOnLaunch ?? ThreadLaunchConfiguration.shouldResetProgressOnLaunch()
        self.resetProgressOnLaunch = resolvedResetProgressOnLaunch
        self.externalLinks = externalLinks
#if DEBUG
        self.debugBadgePreviewState = resolvedStore.debugBadgePreviewState
#endif
    }

    func bootstrapIfNeeded() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        do {
            if resetProgressOnLaunch {
                store.resetForFreshLaunch()
            }
            practiceRounds = try repository.loadPracticeRounds()
            let dailyRounds = try repository.loadDailyRounds()
            let scheduler = DailyScheduler(
                rounds: dailyRounds
            )
            self.scheduler = scheduler
            preferences = store.preferences
            applyTodayState(using: scheduler)
            let localDefaultScreen = defaultScreenForToday()
            screen = localDefaultScreen
            await synchronizePrivateCloudState()
            let syncedDefaultScreen = defaultScreenForToday()
            reconcileVisibleScreenAfterPrivateCloudSync(defaultScreen: syncedDefaultScreen)
            track(
                .bootstrapped(
                    defaultScreen: screenName(syncedDefaultScreen),
                    tutorialCompleted: store.tutorialCompleted,
                    remindersEnabled: preferences.dailyRemindersEnabled,
                    aggregateSharingEnabled: preferences.aggregateSharingEnabled
                )
            )
            await refreshNotificationsState()
#if DEBUG
            await refreshNotificationDebugSummary()
            notificationDebugFeedback = nil
#endif
            if UIApplication.shared.applicationState == .active {
                startAnalyticsSessionIfNeeded()
            }
        } catch {
            bootErrorMessage = error.localizedDescription
            screen = .error
        }
    }

    func handleScenePhaseChange(_ newValue: ScenePhase) async {
        switch newValue {
        case .active:
            if hasBootstrapped {
                startAnalyticsSessionIfNeeded()
            }
            await refreshIfNeededForToday()
        case .background:
            endAnalyticsSessionIfNeeded()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func startPractice() {
        store.tutorialCompleted = true
        practiceScores = []
        track(.tutorialStarted(roundCount: practiceRounds.count))
        screen = .practice(0)
    }

    func skipTutorial() {
        store.tutorialCompleted = true
        prepareFirstDailyNudgeIfNeeded()
        track(.tutorialSkipped())
        screen = .daily
    }

    func trackPracticeRoundStarted(index: Int, round: ThreadRound, resumedSavedProgress: Bool) {
        track(
            .roundStarted(
                mode: "practice",
                roundID: round.id,
                practiceIndex: index + 1,
                resumedSavedProgress: resumedSavedProgress
            )
        )
    }

    func finishPracticeRound(index: Int, round: ThreadRound, completion: ThreadRoundCompletion) {
        practiceScores.append(completion.score)
        if completion.score != nil {
            store.hasSolvedPracticeRound = true
            completeFirstDailyNudge()
        }
        track(
            .roundFinished(
                mode: "practice",
                result: completion.score == nil ? "failed" : "solved",
                roundID: round.id,
                practiceIndex: index + 1,
                completion: completion
            )
        )

        if practiceScores.count < practiceRounds.count {
            screen = .practice(practiceScores.count)
        } else {
            track(.tutorialCompleted(totalRounds: practiceRounds.count))
            screen = .practiceSummary
        }
    }

    func continueFromPracticeSummary() {
        refreshFirstDailyNudgeStage()
        screen = .daily
    }

    func openStats() {
        returnScreen = screen == .stats ? returnScreen : screen
        track(.statsOpened())
        screen = .stats
    }

    func closeStats() {
        screen = returnScreen
    }

    func openSettings() {
        returnScreen = screen == .settings ? returnScreen : screen
        track(.settingsOpened())
        screen = .settings
    }

    func closeSettings() {
        screen = returnScreen
    }

    func openArchive() {
        switch screen {
        case .archive, .archiveRound, .archiveResult:
            break
        default:
            returnScreen = screen
        }
        track(.archiveOpened())
        screen = .archive
    }

    func closeArchive() {
        screen = returnScreen
    }

    func openArchiveItem(_ dateKey: String) {
        guard let item = archiveItem(for: dateKey) else { return }
        screen = item.isFinished ? .archiveResult(dateKey) : .archiveRound(dateKey)
    }

    func closeArchiveDetail() {
        screen = .archive
    }

    func archiveItem(for dateKey: String) -> ThreadArchiveItem? {
        archiveItems.first { $0.puzzle.dateKey == dateKey }
    }

    func archiveSnapshot(for puzzle: ThreadArchivePuzzle) -> GameSnapshot? {
        archiveSnapshots[puzzle.dateKey].flatMap { snapshot in
            snapshot.roundID == puzzle.round.id ? snapshot : nil
        }
    }

    func updateArchiveSnapshot(_ snapshot: GameSnapshot) {
        guard case .archiveRound(let dateKey) = screen,
              snapshot.dateKey == dateKey else { return }
        archiveSnapshots[dateKey] = snapshot
        store.saveArchiveSnapshot(snapshot)
    }

    func trackArchiveRoundStarted(puzzle: ThreadArchivePuzzle, resumedSavedProgress: Bool) {
        track(
            .roundStarted(
                mode: "archive",
                roundID: puzzle.round.id,
                roundNumber: puzzle.roundNumber,
                dateKey: puzzle.dateKey,
                resumedSavedProgress: resumedSavedProgress
            )
        )
    }

    func completeArchive(puzzle: ThreadArchivePuzzle, completion: ThreadRoundCompletion) {
        guard case .archiveRound(let dateKey) = screen,
              dateKey == puzzle.dateKey else { return }

        let entry = ThreadArchiveHistoryEntry(
            dateKey: puzzle.dateKey,
            roundID: puzzle.round.id,
            answer: puzzle.round.answer,
            score: completion.score,
            completedAt: .now
        )
        archiveHistory = store.upsertArchiveHistoryEntry(entry)
        archiveSnapshots.removeValue(forKey: puzzle.dateKey)
        store.clearArchiveSnapshot(for: puzzle.dateKey)
        track(
            .roundFinished(
                mode: "archive",
                result: completion.score == nil ? "failed" : "solved",
                roundID: puzzle.round.id,
                roundNumber: puzzle.roundNumber,
                dateKey: puzzle.dateKey,
                completion: completion
            )
        )
        screen = .archive
    }

    func snapshotForCurrentDailyRound() -> GameSnapshot? {
        currentDailySnapshot
    }

    func updateDailySnapshot(_ snapshot: GameSnapshot) {
        currentDailySnapshot = snapshot
        store.saveSnapshot(snapshot)
        scheduleSnapshotCloudSync(snapshot)
    }

    func trackDailyRoundStarted(round: ThreadRound, resumedSavedProgress: Bool) {
        track(
            .roundStarted(
                mode: "daily",
                roundID: round.id,
                roundNumber: dailyRoundNumber,
                dateKey: todayDateKey,
                resumedSavedProgress: resumedSavedProgress,
                currentStreak: currentStreakCount(for: history)
            )
        )
    }

    func completeDaily(completion: ThreadRoundCompletion) {
        guard let dailyRound else { return }
        let hasSolvedDailyBefore = history.contains { $0.score != nil }

        let entry = DailyHistoryEntry(
            dateKey: todayDateKey,
            roundID: dailyRound.id,
            answer: dailyRound.answer,
            score: completion.score,
            completedAt: .now,
            aggregateSubmittedAt: nil
        )

        history = store.upsertHistoryEntry(entry)
        currentDailyResult = entry
        currentDailySnapshot = nil
        store.clearSnapshot(for: todayDateKey)
        snapshotSyncTask?.cancel()
        if preferences.dailyRemindersEnabled {
            let completedReminderContext = reminderContext()
            Task(priority: .userInitiated) {
                await notifications.scheduleDailyReminders(context: completedReminderContext)
            }
        }
        completeFirstDailyNudge()
        let completedDailyCount = history.count
        track(
            .roundFinished(
                mode: "daily",
                result: completion.score == nil ? "failed" : "solved",
                roundID: dailyRound.id,
                roundNumber: dailyRoundNumber,
                dateKey: todayDateKey,
                currentStreak: currentStreakCount(for: history),
                completion: completion
            )
        )
        screen = .results

        if completion.score != nil && !hasSolvedDailyBefore {
            scheduleMilestoneNotificationPrompt(expectedPromptCount: 0)
        } else if completedDailyCount >= 3 && store.notificationPromptState.promptCount == 1 {
            scheduleMilestoneNotificationPrompt(expectedPromptCount: 1)
        }

        let aggregateStats = self.aggregateStats
        let installationID = store.installationID
        let roundID = dailyRound.id
        let dateKey = todayDateKey
        let aggregateSharingEnabled = preferences.aggregateSharingEnabled
        let privateCloudSync = self.privateCloudSync

        Task {
            await privateCloudSync.deleteSnapshot(for: dateKey)
            await privateCloudSync.upsertHistoryEntry(entry)

            if aggregateSharingEnabled {
                let didSubmit = await aggregateStats.submitDailyResult(
                    installationID: installationID,
                    roundID: roundID,
                    dateKey: dateKey,
                    score: completion.score
                )

                if didSubmit {
                    let updated = entry.markingAggregateSubmitted(at: .now)
                    await MainActor.run {
                        history = store.upsertHistoryEntry(updated)
                        currentDailyResult = updated
                    }
                    await privateCloudSync.upsertHistoryEntry(updated)
                }
            }

        }
    }

    func confirmSharedResults() {
        guard let dailyRound, let currentDailyResult else { return }
        track(
            .resultShared(
                roundID: dailyRound.id,
                roundNumber: dailyRoundNumber,
                dateKey: todayDateKey,
                score: currentDailyResult.score
            )
        )
    }

    func refreshIfNeededForToday() async {
        guard let scheduler else { return }

        let previousDateKey = todayDateKey
        let previousRoundID = dailyRound?.id
        let previousDayNumber = dailyRoundNumber

        applyTodayState(using: scheduler)

        let didChangeDay = previousDateKey != todayDateKey
            || previousRoundID != dailyRound?.id
            || previousDayNumber != dailyRoundNumber

        if didChangeDay {
            let updatedScreen = defaultScreenForToday()
            switch screen {
            case .stats, .settings, .archive, .archiveRound, .archiveResult:
                returnScreen = updatedScreen
            default:
                screen = updatedScreen
            }
        }

        await synchronizePrivateCloudState()
        let syncedDefaultScreen = defaultScreenForToday()
        reconcileVisibleScreenAfterPrivateCloudSync(defaultScreen: syncedDefaultScreen)
        await refreshNotificationsState()
    }

    func setAnalyticsEnabled(_ isEnabled: Bool) {
        updatePreferences { $0.analyticsEnabled = isEnabled }
        track(.preferenceChanged(key: "analytics_enabled", enabled: isEnabled))
    }

    func setAggregateSharingEnabled(_ isEnabled: Bool) {
        updatePreferences { $0.aggregateSharingEnabled = isEnabled }
        track(.preferenceChanged(key: "aggregate_sharing_enabled", enabled: isEnabled))
    }

    func setHapticsEnabled(_ isEnabled: Bool) {
        updatePreferences { $0.hapticsEnabled = isEnabled }
        track(.preferenceChanged(key: "haptics_enabled", enabled: isEnabled))
    }

    func setDailyRemindersEnabled(_ isEnabled: Bool) {
        Task {
            guard isEnabled else {
                pendingDailyRemindersEnableRequest = false
#if DEBUG
                pendingDebugReminderAfterAuthorization = false
#endif
                if preferences.dailyRemindersEnabled {
                    updatePreferences { $0.dailyRemindersEnabled = false }
                    track(.preferenceChanged(key: "daily_reminders_enabled", enabled: false))
                }
                notificationPrompt = nil
                await notifications.removeDailyReminders()
#if DEBUG
                await refreshNotificationDebugSummary()
                notificationDebugFeedback = "Daily reminders turned off"
#endif
                return
            }

            let status = await notifications.authorizationStatus()
            notificationAuthorizationStatus = status

            guard status.isGranted else {
                pendingDailyRemindersEnableRequest = (status == .notDetermined)
                if preferences.dailyRemindersEnabled {
                    updatePreferences { $0.dailyRemindersEnabled = false }
                    track(.preferenceChanged(key: "daily_reminders_enabled", enabled: false))
                }
                presentNotificationPrompt(status: status)
#if DEBUG
                notificationDebugFeedback = status == .notDetermined
                    ? "Confirm the permission prompt to enable reminders for this app"
                    : "Notifications are off for this app in iOS Settings"
#endif
                return
            }

            pendingDailyRemindersEnableRequest = false
            if !preferences.dailyRemindersEnabled {
                updatePreferences { $0.dailyRemindersEnabled = true }
                track(.preferenceChanged(key: "daily_reminders_enabled", enabled: true))
            }

            notificationPrompt = nil
            await notifications.scheduleDailyReminders(context: reminderContext())
#if DEBUG
            await refreshNotificationDebugSummary()
            notificationDebugFeedback = "Daily reminders enabled"
#endif
        }
    }

    func dismissNotificationPrompt() {
        pendingDailyRemindersEnableRequest = false
        notificationAuthorizationRequestInFlight = false
#if DEBUG
        pendingDebugReminderAfterAuthorization = false
#endif
        notificationPrompt = nil
#if DEBUG
        notificationDebugFeedback = "Notification prompt dismissed"
#endif
    }

    func clearNotificationPromptPresentation() {
        notificationPrompt = nil
    }

#if DEBUG
    func refreshNotificationDiagnostics() {
        Task {
            await refreshNotificationsState()
            notificationDebugFeedback = "Notification diagnostics refreshed"
        }
    }

    func sendDebugReminder() {
        Task {
            var status = await notifications.authorizationStatus()
            notificationAuthorizationStatus = status

            if status == .notDetermined {
                notificationAuthorizationRequestInFlight = true
                notificationDebugFeedback = "Requesting notification permission for this app"
                let requestedStatus = await notifications.requestAuthorization()
                notificationAuthorizationRequestInFlight = false
                notificationAuthorizationStatus = requestedStatus
                track(.notificationPermissionResult(status: requestedStatus))
                status = requestedStatus
            }

            guard status.isGranted else {
                pendingDebugReminderAfterAuthorization = false
                if status != .notDetermined {
                    presentNotificationPrompt(status: status)
                }
                notificationDebugFeedback = status == .denied
                    ? "Notifications are disabled for this app in iOS Settings"
                    : "Notification permission was not granted for this app"
                await refreshNotificationDebugSummary(statusOverride: status)
                return
            }

            await notifications.scheduleDebugReminder(after: 10)
            await refreshNotificationDebugSummary(statusOverride: status)
            notificationDebugFeedback = "Test reminder scheduled for \(formattedDebugTime(Date().addingTimeInterval(10)))"
        }
    }
#endif

    func handleRemotePushTokenUpdate(_ token: String?) async {
        guard let token, !token.isEmpty else { return }

        guard pushConfiguration.isEnabled else {
            remotePushStatus = .disabled
            return
        }

        guard notificationAuthorizationStatus.isGranted else {
            remotePushStatus = .awaitingAuthorization
            return
        }

        guard pushConfiguration.backendConfigured else {
            remotePushStatus = .backendMissing
            return
        }

        let didSync = await pushRegistration.upsertSubscription(
            installationID: store.installationID,
            deviceToken: token,
            remindersEnabled: preferences.dailyRemindersEnabled,
            authorizationStatus: notificationAuthorizationStatus
        )

        remotePushStatus = didSync ? .synced : .failed
    }

    func handleRemotePushRegistrationError(_ message: String?) {
        guard pushConfiguration.isEnabled else {
            remotePushStatus = .disabled
            return
        }

        if let message, !message.isEmpty {
            remotePushStatus = .failed
        }
    }

    func confirmNotificationPrompt(_ presentedPrompt: ThreadNotificationPrompt? = nil) async {
        guard let prompt = presentedPrompt ?? notificationPrompt else { return }
        notificationPrompt = nil

        switch prompt.kind {
        case .requestAuthorization:
            notificationAuthorizationRequestInFlight = true
            try? await Task.sleep(for: .milliseconds(300))
            let status = await notifications.requestAuthorization()
            notificationAuthorizationRequestInFlight = false
            notificationAuthorizationStatus = status
            track(.notificationPermissionResult(status: status))

            if status.isGranted {
                if !preferences.dailyRemindersEnabled {
                    updatePreferences { $0.dailyRemindersEnabled = true }
                    track(.preferenceChanged(key: "daily_reminders_enabled", enabled: true))
                }
                await notifications.scheduleDailyReminders(context: reminderContext())
                pendingDailyRemindersEnableRequest = false
                await registerForRemotePushIfNeeded()
#if DEBUG
                if pendingDebugReminderAfterAuthorization {
                    await notifications.scheduleDebugReminder(after: 10)
                    notificationDebugFeedback = "Permission granted. Test reminder scheduled for \(formattedDebugTime(Date().addingTimeInterval(10)))"
                } else {
                    notificationDebugFeedback = "Permission granted. Daily reminders enabled"
                }
#endif
            } else if preferences.dailyRemindersEnabled {
                updatePreferences { $0.dailyRemindersEnabled = false }
                track(.preferenceChanged(key: "daily_reminders_enabled", enabled: false))
                pendingDailyRemindersEnableRequest = false
#if DEBUG
                notificationDebugFeedback = "Permission denied. Daily reminders remain off"
#endif
            } else {
                pendingDailyRemindersEnableRequest = false
#if DEBUG
                notificationDebugFeedback = "Permission not granted for this app"
#endif
            }
#if DEBUG
            pendingDebugReminderAfterAuthorization = false
            await refreshNotificationDebugSummary()
#endif

        case .openSettings:
            pendingDailyRemindersEnableRequest = false
            notificationAuthorizationRequestInFlight = false
#if DEBUG
            pendingDebugReminderAfterAuthorization = false
#endif
            track(.notificationSettingsOpened())
#if DEBUG
            notificationDebugFeedback = "Open iOS Settings to enable notifications for this app"
#endif
            break
        }
    }

    func resetTutorialProgress() {
        store.resetTutorial()
        firstDailyNudgeTask?.cancel()
        firstDailyNudgeStage = .unseen
        returnScreen = .tutorial
        screen = .tutorial
    }

    func clearLocalProgress() {
        let historyDateKeys = history.map(\.dateKey)
        let snapshotDateKeys = Array(store.loadAllSnapshots().keys)
        store.resetForFreshLaunch()
        store.notificationPromptState = .default
        snapshotSyncTask?.cancel()
        notificationPromptTask?.cancel()
        firstDailyNudgeTask?.cancel()

        practiceScores = []
        history = []
        currentDailyResult = nil
        currentDailySnapshot = nil
        archiveHistory = []
        archiveSnapshots = [:]
        notificationPrompt = nil
        bootErrorMessage = nil
        firstDailyNudgeStage = .unseen
        pendingDailyRemindersEnableRequest = false
        notificationAuthorizationRequestInFlight = false
#if DEBUG
        notificationDebugSummary = "Not loaded"
        notificationDebugFeedback = nil
        pendingDebugReminderAfterAuthorization = false
        debugBadgePreviewState = .default
#endif

        if let scheduler {
            applyTodayState(using: scheduler)
        }

        Task { @MainActor in
            await Task.yield()
            returnScreen = .tutorial
            screen = .tutorial
        }

        let privateCloudSync = self.privateCloudSync
        Task {
            await privateCloudSync.clearHistoryAndSnapshots(
                historyDateKeys: historyDateKeys,
                snapshotDateKeys: snapshotDateKeys
            )
        }
    }

    func markStreakBadgeUnlockPresented(_ milestone: ThreadStreakBadgeMilestone) {
#if DEBUG
        guard debugBadgePreviewState.unlockPreviewMilestone != milestone else { return }
#endif
        store.markStreakBadgeMilestoneShown(milestone)
    }

#if DEBUG
    func previewBadgeCollection(currentStreak: Int, bestStreak: Int) {
        debugBadgePreviewState.currentStreakOverride = currentStreak
        debugBadgePreviewState.bestStreakOverride = bestStreak
        persistDebugBadgePreviewState()
    }

    func previewBadgeUnlock(_ milestone: ThreadStreakBadgeMilestone) {
        debugBadgePreviewState.unlockPreviewMilestone = milestone
        persistDebugBadgePreviewState()
    }

    func clearDebugBadgeUnlockPreview() {
        debugBadgePreviewState.unlockPreviewMilestone = nil
        persistDebugBadgePreviewState()
    }

    func clearBadgeDebugPreviews() {
        debugBadgePreviewState = .default
        persistDebugBadgePreviewState()
    }
#endif

    func trackSupportOpened() {
        track(.supportOpened())
    }

    func trackPrivacyOpened() {
        track(.privacyOpened())
    }

    func handleFirstDailyNudgeSubmission(outcome: GuessSubmissionOutcome) {
        guard firstDailyNudgeStage == .initial else { return }

        switch outcome {
        case .revealedNextClue, .failed:
            store.firstDailyNudgeStage = .followup
            firstDailyNudgeStage = .followup
            scheduleFirstDailyNudgeCompletion()
        case .solved:
            completeFirstDailyNudge()
        case .ignored, .alreadyComplete, .duplicate:
            break
        }
    }

    func waitForNextDailyRefresh() async {
        guard let nextDailyRefreshDate else { return }

        let delay = max(0.25, nextDailyRefreshDate.timeIntervalSinceNow + 0.1)

        do {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        } catch {
            return
        }

        await refreshIfNeededForToday()
    }

    private func track(_ event: AnalyticsEvent) {
        guard preferences.analyticsEnabled else { return }
        analytics.track(event)
    }

    private func startAnalyticsSessionIfNeeded(now: Date = .now) {
        guard analyticsSessionStartedAt == nil else { return }
        analyticsSessionStartedAt = now
        track(.appSessionStarted(screenName: screenName(screen)))
    }

    private func endAnalyticsSessionIfNeeded(now: Date = .now) {
        guard let analyticsSessionStartedAt else { return }
        let durationSeconds = max(1, Int(now.timeIntervalSince(analyticsSessionStartedAt)))
        self.analyticsSessionStartedAt = nil
        track(
            .appSessionEnded(
                durationSeconds: durationSeconds,
                lastScreenName: screenName(screen)
            )
        )
    }

    private func currentStreakCount(for history: [DailyHistoryEntry]) -> Int {
        ThreadStatisticsBuilder.build(history: history, todayKey: todayDateKey).currentStreak
    }

    private func screenName(_ screen: ThreadScreen) -> String {
        switch screen {
        case .loading:
            return "loading"
        case .tutorial:
            return "tutorial"
        case .practice:
            return "practice"
        case .practiceSummary:
            return "practice_summary"
        case .daily:
            return "daily"
        case .results:
            return "results"
        case .alreadyPlayed:
            return "already_played"
        case .archive:
            return "archive"
        case .archiveRound:
            return "archive_round"
        case .archiveResult:
            return "archive_result"
        case .stats:
            return "stats"
        case .settings:
            return "settings"
        case .error:
            return "error"
        }
    }

    private func defaultScreenForToday() -> ThreadScreen {
        if currentDailyResult != nil {
            return .alreadyPlayed
        }
        let hasCompletedPuzzle = !history.isEmpty
        let hasStartedToday = currentDailySnapshot != nil

        if !store.tutorialCompleted && !hasCompletedPuzzle && !hasStartedToday {
            return .tutorial
        }
        return .daily
    }

    private func reconcileVisibleScreenAfterPrivateCloudSync(defaultScreen: ThreadScreen) {
        switch screen {
        case .loading, .daily, .tutorial:
            screen = defaultScreen
        case .stats, .settings, .archive, .archiveRound, .archiveResult:
            returnScreen = defaultScreen
        default:
            break
        }
    }

    private func applyTodayState(using scheduler: DailyScheduler) {
        let round = scheduler.roundForToday()
        dailyRound = round
        dailyRoundNumber = scheduler.dayNumber()
        todayDateKey = scheduler.todayDateKey()
        nextDailyRefreshDate = scheduler.nextUnlockDate()

        var loadedHistory = store.loadHistory()
        let hadInvalidTodayHistory = loadedHistory.contains {
            $0.dateKey == todayDateKey && $0.roundID != round.id
        }

        if hadInvalidTodayHistory {
            loadedHistory.removeAll { $0.dateKey == todayDateKey && $0.roundID != round.id }
            store.replaceHistory(loadedHistory)
        }

        let allSnapshots = store.loadAllSnapshots()
        let hadInvalidTodaySnapshot = allSnapshots[todayDateKey].map { $0.roundID != round.id } ?? false

        if hadInvalidTodaySnapshot {
            store.clearSnapshot(for: todayDateKey)
        }

        var loadedArchiveHistory = store.loadArchiveHistory()
        var loadedArchiveSnapshots = store.loadAllArchiveSnapshots()
        let archivePuzzlesByDate = Dictionary(
            uniqueKeysWithValues: scheduler.archivePuzzles().map { ($0.dateKey, $0) }
        )
        var migratedDailySnapshotDateKeys: [String] = []

        for (dateKey, snapshot) in allSnapshots where dateKey < todayDateKey {
            guard let scheduledPuzzle = archivePuzzlesByDate[dateKey] else { continue }

            if loadedHistory.contains(where: { $0.dateKey == dateKey })
                || loadedArchiveHistory.contains(where: { $0.dateKey == dateKey }) {
                store.clearSnapshot(for: dateKey)
                migratedDailySnapshotDateKeys.append(dateKey)
                continue
            }

            let puzzle = archivePuzzle(
                scheduledPuzzle,
                completedRoundID: snapshot.roundID,
                scheduler: scheduler
            )
            guard puzzle.round.id == snapshot.roundID else { continue }

            if snapshot.isSolved || snapshot.isFailed {
                let entry = ThreadArchiveHistoryEntry(
                    dateKey: dateKey,
                    roundID: puzzle.round.id,
                    answer: puzzle.round.answer,
                    score: snapshot.isSolved ? snapshot.revealedClueCount : nil,
                    completedAt: snapshot.updatedAt ?? .now
                )
                loadedArchiveHistory = store.upsertArchiveHistoryEntry(entry)
                loadedArchiveSnapshots.removeValue(forKey: dateKey)
                store.clearArchiveSnapshot(for: dateKey)
            } else if let migratedSnapshot = ThreadCloudSyncMerger.merge(
                local: loadedArchiveSnapshots[dateKey],
                remote: snapshot
            ) {
                loadedArchiveSnapshots[dateKey] = migratedSnapshot
                store.saveArchiveSnapshot(migratedSnapshot)
            }

            store.clearSnapshot(for: dateKey)
            migratedDailySnapshotDateKeys.append(dateKey)
        }

        history = loadedHistory
        archiveHistory = loadedArchiveHistory
        archiveSnapshots = loadedArchiveSnapshots
        currentDailyResult = loadedHistory.first {
            $0.dateKey == todayDateKey && $0.roundID == round.id
        }
        currentDailySnapshot = store.loadSnapshot(for: todayDateKey, roundID: round.id)
        if currentDailyResult != nil, currentDailySnapshot != nil {
            currentDailySnapshot = nil
            store.clearSnapshot(for: todayDateKey)
            let dateKey = todayDateKey
            let privateCloudSync = self.privateCloudSync
            Task {
                await privateCloudSync.deleteSnapshot(for: dateKey)
            }
        }
        refreshFirstDailyNudgeStage()

        if hadInvalidTodayHistory || hadInvalidTodaySnapshot || !migratedDailySnapshotDateKeys.isEmpty {
            let privateCloudSync = self.privateCloudSync
            let dateKey = todayDateKey
            Task {
                await privateCloudSync.clearHistoryAndSnapshots(
                    historyDateKeys: hadInvalidTodayHistory ? [dateKey] : [],
                    snapshotDateKeys: (hadInvalidTodaySnapshot ? [dateKey] : [])
                        + migratedDailySnapshotDateKeys
                )
            }
        }

    }

    private func persistPreferences() {
        store.preferences = preferences
        let preferences = self.preferences
        let privateCloudSync = self.privateCloudSync
        Task {
            await privateCloudSync.upsertPreferences(preferences)
        }
    }

    private func archivePuzzle(
        _ scheduledPuzzle: ThreadArchivePuzzle,
        completedRoundID: Int,
        scheduler: DailyScheduler
    ) -> ThreadArchivePuzzle {
        guard completedRoundID != scheduledPuzzle.round.id,
              let completedRound = scheduler.round(withID: completedRoundID) else {
            return scheduledPuzzle
        }

        return ThreadArchivePuzzle(
            dateKey: scheduledPuzzle.dateKey,
            roundNumber: scheduledPuzzle.roundNumber,
            round: completedRound
        )
    }

    private func updatePreferences(_ mutate: (inout ThreadPreferences) -> Void) {
        var nextPreferences = preferences
        mutate(&nextPreferences)
        preferences = nextPreferences.markedUpdated()
        persistPreferences()
    }

#if DEBUG
    private func persistDebugBadgePreviewState() {
        store.debugBadgePreviewState = debugBadgePreviewState
    }
#endif

    private func refreshNotificationsState() async {
        let localDateKey = DateKeyFormatter.storage.string(from: .now, timeZone: .current)
        _ = store.recordAppOpenDay(localDateKey)

        let status = await notifications.authorizationStatus()
        notificationAuthorizationStatus = status

        if status.isGranted && pendingDailyRemindersEnableRequest && !preferences.dailyRemindersEnabled {
            updatePreferences { $0.dailyRemindersEnabled = true }
            await notifications.scheduleDailyReminders(context: reminderContext())
            pendingDailyRemindersEnableRequest = false
            await registerForRemotePushIfNeeded()
#if DEBUG
            if pendingDebugReminderAfterAuthorization {
                await notifications.scheduleDebugReminder(after: 10)
                notificationDebugFeedback = "Permission detected. Test reminder scheduled for \(formattedDebugTime(Date().addingTimeInterval(10)))"
                pendingDebugReminderAfterAuthorization = false
            }
#endif
        } else if notificationAuthorizationRequestInFlight {
            return
        } else if preferences.dailyRemindersEnabled && status.isGranted {
            await notifications.scheduleDailyReminders(context: reminderContext())
            await registerForRemotePushIfNeeded()
        } else {
            let shouldPreservePendingEnableRequest = pendingDailyRemindersEnableRequest && status == .notDetermined
            if !shouldPreservePendingEnableRequest {
                pendingDailyRemindersEnableRequest = false
            }
            if preferences.dailyRemindersEnabled && !status.isGranted {
                updatePreferences { $0.dailyRemindersEnabled = false }
            }
            await notifications.removeDailyReminders()
            remotePushStatus = pushConfiguration.isEnabled ? .awaitingAuthorization : .disabled
            if !status.isGranted {
#if DEBUG
                pendingDebugReminderAfterAuthorization = false
#endif
            }
        }

#if DEBUG
        await refreshNotificationDebugSummary(statusOverride: status)
#endif
    }

    private func scheduleMilestoneNotificationPrompt(expectedPromptCount: Int) {
        guard store.notificationPromptState.promptCount == expectedPromptCount else { return }

        notificationPromptTask?.cancel()
        notificationPromptTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(15))
            } catch {
                return
            }

            guard let self else { return }
            guard UIApplication.shared.applicationState == .active else { return }
            guard notificationPrompt == nil else { return }

            let status = await notifications.authorizationStatus()
            notificationAuthorizationStatus = status

            guard !status.isGranted else { return }
            guard store.notificationPromptState.promptCount == expectedPromptCount else { return }

            presentNotificationPrompt(status: status)
        }
    }

    private func presentNotificationPrompt(status: ThreadNotificationAuthorizationStatus) {
        guard notificationPrompt == nil else { return }
        let nextPrompt = immediateNotificationPrompt(for: status)
        guard let nextPrompt else { return }
        let promptState = store.markNotificationPromptShown()
        notificationPrompt = nextPrompt
        track(
            .notificationPromptShown(
                kind: nextPrompt.kind == .requestAuthorization ? "request_authorization" : "open_settings",
                promptCount: promptState.promptCount
            )
        )
    }

    private func reminderContext(now: Date = .now) -> ThreadReminderContext {
        ThreadReminderContext(
            currentStreak: currentStreakCount(for: history),
            hasSolvedToday: currentDailyResult != nil,
            nextDailyRefreshDate: nextDailyRefreshDate,
            now: now
        )
    }

    private func immediateNotificationPrompt(for status: ThreadNotificationAuthorizationStatus) -> ThreadNotificationPrompt? {
        switch status {
        case .notDetermined:
            return ThreadNotificationPrompt(
                id: "notifications-request-immediate",
                kind: .requestAuthorization,
                title: "Never miss a Thread",
                message: "Turn on reminders when each new Thread goes live.",
                confirmTitle: "Turn on reminders"
            )
        case .denied, .unsupported:
            return ThreadNotificationPrompt(
                id: "notifications-settings-immediate",
                kind: .openSettings,
                title: "Turn reminders back on?",
                message: "Notifications are currently off for Thread. Open Settings to enable the 9:00 AM and 9:00 PM reminders.",
                confirmTitle: "Open Settings"
            )
        case .authorized, .provisional, .ephemeral:
            return nil
        }
    }

    private func currentPrivateCloudState() -> ThreadCloudSyncState {
        ThreadCloudSyncState(
            preferences: store.preferences,
            history: store.loadHistory(),
            snapshots: store.loadAllSnapshots()
        )
    }

    private func synchronizePrivateCloudState() async {
        let mergedState = await privateCloudSync.synchronize(localState: currentPrivateCloudState())
        let resolvedState = ThreadCloudSyncMerger.merge(
            local: currentPrivateCloudState(),
            remote: mergedState
        )

        store.replacePreferences(resolvedState.preferences)
        store.replaceHistory(resolvedState.history)
        store.replaceSnapshots(resolvedState.snapshots)

        preferences = resolvedState.preferences
        history = resolvedState.history

        if !store.tutorialCompleted && (!resolvedState.history.isEmpty || !resolvedState.snapshots.isEmpty) {
            store.tutorialCompleted = true
        }

        if let scheduler {
            applyTodayState(using: scheduler)
        }
    }

    private func scheduleSnapshotCloudSync(_ snapshot: GameSnapshot) {
        guard snapshot.dateKey != nil else { return }

        snapshotSyncTask?.cancel()
        let privateCloudSync = self.privateCloudSync
        snapshotSyncTask = Task {
            try? await Task.sleep(for: .seconds(1))
            await privateCloudSync.saveSnapshot(snapshot)
        }
    }

    private func registerForRemotePushIfNeeded() async {
        guard pushConfiguration.isEnabled else {
            remotePushStatus = .disabled
            return
        }

        guard notificationAuthorizationStatus.isGranted else {
            remotePushStatus = .awaitingAuthorization
            return
        }

        if !pushConfiguration.backendConfigured {
            remotePushStatus = .backendMissing
        } else {
            remotePushStatus = .registering
        }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

#if DEBUG
    private func refreshNotificationDebugSummary(
        statusOverride: ThreadNotificationAuthorizationStatus? = nil
    ) async {
        let status: ThreadNotificationAuthorizationStatus
        if let statusOverride {
            status = statusOverride
        } else {
            status = await notifications.authorizationStatus()
        }
        let pendingRequests = await notifications.debugPendingRequests()

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        let lines: [String]
        if pendingRequests.isEmpty {
            lines = [
                "Bundle: \(Bundle.main.bundleIdentifier ?? "unknown")",
                "Authorization: \(status.rawValue)",
                status == .notDetermined
                    ? "Permission has not been requested for this app yet"
                    : "Pending reminders: none"
            ]
        } else {
            lines = [
                "Bundle: \(Bundle.main.bundleIdentifier ?? "unknown")",
                "Authorization: \(status.rawValue)",
                "Pending reminders:"
            ] + pendingRequests.map { request in
                let triggerText = request.nextTriggerDate.map { formatter.string(from: $0) } ?? "unknown time"
                return "• \(request.identifier) at \(triggerText)"
            }
        }

        notificationDebugSummary = lines.joined(separator: "\n")
    }

    private func formattedDebugTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
#endif

    private func prepareFirstDailyNudgeIfNeeded() {
        guard history.isEmpty else {
            completeFirstDailyNudge()
            return
        }

        guard !store.hasSolvedPracticeRound else {
            completeFirstDailyNudge()
            return
        }

        if store.firstDailyNudgeStage == .unseen {
            store.firstDailyNudgeStage = .initial
            store.firstDailyNudgeDateKey = todayDateKey
        }

        refreshFirstDailyNudgeStage()
    }

    private func refreshFirstDailyNudgeStage() {
        guard dailyRound != nil else {
            firstDailyNudgeTask?.cancel()
            firstDailyNudgeStage = .unseen
            return
        }

        guard store.tutorialCompleted,
              history.isEmpty,
              currentDailyResult == nil,
              !store.hasSolvedPracticeRound else {
            firstDailyNudgeTask?.cancel()
            firstDailyNudgeStage = .unseen
            return
        }

        if let firstDailyNudgeDateKey = store.firstDailyNudgeDateKey,
           firstDailyNudgeDateKey != todayDateKey {
            completeFirstDailyNudge()
            return
        }

        switch store.firstDailyNudgeStage {
        case .initial, .followup:
            firstDailyNudgeStage = store.firstDailyNudgeStage
        case .unseen:
            firstDailyNudgeStage = .unseen
        case .completed:
            firstDailyNudgeTask?.cancel()
            firstDailyNudgeStage = .completed
        }
    }

    private func scheduleFirstDailyNudgeCompletion() {
        firstDailyNudgeTask?.cancel()
        firstDailyNudgeTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(4))
            } catch {
                return
            }

            guard let self else { return }
            completeFirstDailyNudge()
        }
    }

    private func completeFirstDailyNudge() {
        firstDailyNudgeTask?.cancel()
        store.firstDailyNudgeStage = .completed
        firstDailyNudgeStage = .completed
    }
}
