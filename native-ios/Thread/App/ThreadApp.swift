import SwiftUI
import UIKit

@main
struct ThreadNativeApp: App {
    @UIApplicationDelegateAdaptor(ThreadAppDelegate.self) private var appDelegate
    @StateObject private var viewModel = ThreadRootViewModel()
    @StateObject private var archivePurchaseController = ThreadArchivePurchaseController()

    var body: some Scene {
        WindowGroup {
            ThreadRootView(
                viewModel: viewModel,
                appDelegate: appDelegate,
                archivePurchaseController: archivePurchaseController
            )
        }
    }
}

struct ThreadRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ThreadRootViewModel
    @ObservedObject var appDelegate: ThreadAppDelegate
    @ObservedObject var archivePurchaseController: ThreadArchivePurchaseController
    @State private var hasPresentedInitialResolvedScreen = false
    @State private var initialResolvedScreenVisible = false
    @State private var isArchivePaywallPresented = false

    var body: some View {
        ZStack {
            ThreadBackground()

            screenView
                .modifier(
                    ThreadInitialResolvedScreenEntrance(
                        screen: viewModel.screen,
                        isVisible: initialResolvedScreenVisible,
                        reduceMotion: reduceMotion
                    )
                )

#if DEBUG
            if let previewMilestone = viewModel.debugBadgePreviewState.unlockPreviewMilestone {
                ThreadStreakBadgeUnlockOverlay(
                    milestone: previewMilestone,
                    buttonTitle: "Close preview",
                    onContinue: viewModel.clearDebugBadgeUnlockPreview
                )
                .zIndex(2)
            }
#endif
        }
        .task {
            await viewModel.bootstrapIfNeeded()
        }
        .task {
            await archivePurchaseController.start()
        }
        .onAppear {
            presentInitialResolvedScreenIfNeeded(viewModel.screen)
        }
        .onChange(of: viewModel.screen) { _, newScreen in
            presentInitialResolvedScreenIfNeeded(newScreen)
        }
        .task(id: viewModel.todayDateKey) {
            await viewModel.waitForNextDailyRefresh()
        }
        .onChange(of: scenePhase) { _, newValue in
            Task {
                await viewModel.handleScenePhaseChange(newValue)
            }
        }
        .onChange(of: appDelegate.latestRemotePushToken) { _, token in
            Task {
                await viewModel.handleRemotePushTokenUpdate(token)
            }
        }
        .onChange(of: appDelegate.remotePushRegistrationError) { _, message in
            viewModel.handleRemotePushRegistrationError(message)
        }
        .onChange(of: archivePurchaseController.isEntitled) { _, isEntitled in
            handleArchiveEntitlementChange(isEntitled)
        }
        .sheet(isPresented: $isArchivePaywallPresented) {
            ArchivePaywallView(
                purchaseController: archivePurchaseController,
                onClose: { isArchivePaywallPresented = false },
                onUnlocked: unlockArchive
            )
        }
        .alert(item: notificationPromptBinding) { prompt in
            switch prompt.kind {
            case .requestAuthorization:
                Alert(
                    title: Text(prompt.title),
                    message: Text(prompt.message),
                    primaryButton: .default(Text(prompt.confirmTitle)) {
                        Task {
                            await viewModel.confirmNotificationPrompt(prompt)
                        }
                    },
                    secondaryButton: .cancel(Text("Not now")) {
                        viewModel.dismissNotificationPrompt()
                    }
                )

            case .openSettings:
                Alert(
                    title: Text(prompt.title),
                    message: Text(prompt.message),
                    primaryButton: .default(Text(prompt.confirmTitle)) {
                        viewModel.dismissNotificationPrompt()
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsURL)
                        }
                    },
                    secondaryButton: .cancel(Text("Not now")) {
                        viewModel.dismissNotificationPrompt()
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var screenView: some View {
        switch viewModel.screen {
        case .loading:
            Color.clear

        case .tutorial:
            TutorialView(
                onStartPractice: viewModel.startPractice,
                onSkipToDaily: viewModel.skipTutorial,
                onOpenSettings: viewModel.openSettings
            )

        case .practice(let index):
            if viewModel.practiceRounds.indices.contains(index) {
                let round = viewModel.practiceRounds[index]
                ThreadRoundView(
                    round: round,
                    kicker: "Practice \(index + 1) of \(viewModel.practiceRounds.count)",
                    completionButtonTitle: index < viewModel.practiceRounds.count - 1 ? "Next round" : "See practice summary",
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onRoundStarted: { resumedSavedProgress in
                        viewModel.trackPracticeRoundStarted(
                            index: index,
                            round: round,
                            resumedSavedProgress: resumedSavedProgress
                        )
                    },
                    onComplete: { completion in
                        viewModel.finishPracticeRound(
                            index: index,
                            round: round,
                            completion: completion
                        )
                    },
                    onOpenSettings: viewModel.openSettings,
                    secondaryActionTitle: "Skip to today's puzzle",
                    onSecondaryAction: viewModel.skipTutorial
                )
                .id("practice-\(index)-\(round.id)")
            }

        case .practiceSummary:
            PracticeSummaryView(
                rounds: viewModel.practiceRounds,
                scores: viewModel.practiceScores,
                onContinue: viewModel.continueFromPracticeSummary,
                onOpenSettings: viewModel.openSettings
            )

        case .daily:
            if let round = viewModel.dailyRound {
                ThreadRoundView(
                    round: round,
                    dateKey: viewModel.todayDateKey,
                    snapshot: viewModel.snapshotForCurrentDailyRound(),
                    kicker: "Thread #\(viewModel.dailyRoundNumber)",
                    completionButtonTitle: "See results",
                    autoAdvanceOnFailure: true,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onPersistSnapshot: viewModel.updateDailySnapshot,
                    onRoundStarted: { resumedSavedProgress in
                        viewModel.trackDailyRoundStarted(
                            round: round,
                            resumedSavedProgress: resumedSavedProgress
                        )
                    },
                    firstDailyNudgeStage: viewModel.visibleFirstDailyNudgeStage,
                    completionStreakCount: viewModel.projectedSolvedDailyStreakCount,
                    completionBadgeUnlock: viewModel.pendingStreakBadgeUnlockMilestone,
                    onCompletionBadgeUnlockPresented: viewModel.markStreakBadgeUnlockPresented,
                    onFirstDailyNudgeSubmission: viewModel.handleFirstDailyNudgeSubmission,
                    onComplete: viewModel.completeDaily,
                    onOpenArchive: archiveOpenAction,
                    onViewStats: viewModel.openStats,
                    onOpenSettings: viewModel.openSettings
                )
                .id("daily-\(viewModel.todayDateKey)-\(round.id)")
            }

        case .results:
            if let round = viewModel.dailyRound, let result = viewModel.displayedDailyResult {
                ResultsView(
                    round: round,
                    roundNumber: viewModel.dailyRoundNumber,
                    appShareURL: viewModel.externalLinks.shareAppURL,
                    appShareLabel: viewModel.externalLinks.shareAppLinkTitle,
                    score: result.score,
                    nextUnlockDate: viewModel.nextDailyRefreshDate,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onOpenArchive: archiveOpenAction,
                    onViewStats: viewModel.openStats,
                    onShare: viewModel.confirmSharedResults,
                    onOpenSettings: viewModel.openSettings
                )
            }

        case .alreadyPlayed:
            if let round = viewModel.dailyRound, let entry = viewModel.displayedDailyResult {
                AlreadyPlayedView(
                    round: round,
                    roundNumber: viewModel.dailyRoundNumber,
                    appShareURL: viewModel.externalLinks.shareAppURL,
                    appShareLabel: viewModel.externalLinks.shareAppLinkTitle,
                    entry: entry,
                    nextUnlockDate: viewModel.nextDailyRefreshDate,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onOpenArchive: archiveOpenAction,
                    onViewStats: viewModel.openStats,
                    onShare: viewModel.confirmSharedResults,
                    onOpenSettings: viewModel.openSettings
                )
            }

        case .archive:
            archiveView

        case .archiveRound(let dateKey):
            if let item = viewModel.archiveItem(for: dateKey), !item.isFinished {
                let puzzle = item.puzzle
                ThreadRoundView(
                    round: puzzle.round,
                    dateKey: puzzle.dateKey,
                    snapshot: viewModel.archiveSnapshot(for: puzzle),
                    kicker: "Archive · Thread #\(puzzle.roundNumber)",
                    completionButtonTitle: "Back to Archive",
                    autoAdvanceOnFailure: true,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onPersistSnapshot: viewModel.updateArchiveSnapshot,
                    onRoundStarted: { resumedSavedProgress in
                        viewModel.trackArchiveRoundStarted(
                            puzzle: puzzle,
                            resumedSavedProgress: resumedSavedProgress
                        )
                    },
                    onComplete: { completion in
                        viewModel.completeArchive(puzzle: puzzle, completion: completion)
                    },
                    onBack: viewModel.closeArchiveDetail
                )
                .id("archive-\(puzzle.dateKey)-\(puzzle.round.id)")
            } else {
                archiveView
            }

        case .archiveResult(let dateKey):
            if let item = viewModel.archiveItem(for: dateKey), item.isFinished {
                ArchiveResultView(
                    item: item,
                    onBack: viewModel.closeArchiveDetail
                )
            } else {
                archiveView
            }

        case .stats:
            StatsView(
                history: viewModel.history,
                todayKey: viewModel.todayDateKey,
                currentStreakValue: viewModel.displayedStatsCurrentStreak,
                bestStreakValue: viewModel.displayedStatsBestStreak,
                streakBadges: viewModel.displayedStreakBadges,
                onBack: viewModel.closeStats,
                onOpenSettings: viewModel.openSettings
            )

        case .settings:
#if DEBUG
            SettingsView(
                preferences: viewModel.preferences,
                displayedDailyRemindersEnabled: viewModel.displayedDailyRemindersEnabled,
                externalLinks: viewModel.externalLinks,
                onBack: viewModel.closeSettings,
                onSetAnalyticsEnabled: viewModel.setAnalyticsEnabled,
                onSetAggregateSharingEnabled: viewModel.setAggregateSharingEnabled,
                onSetHapticsEnabled: viewModel.setHapticsEnabled,
                onSetDailyRemindersEnabled: viewModel.setDailyRemindersEnabled,
                onOpenSupport: viewModel.trackSupportOpened,
                onOpenPrivacy: viewModel.trackPrivacyOpened,
                notificationAuthorizationStatus: viewModel.notificationAuthorizationStatus,
                notificationDebugSummary: viewModel.notificationDebugSummary,
                notificationDebugFeedback: viewModel.notificationDebugFeedback,
                badgeDebugSummary: viewModel.badgeDebugSummary,
                onClearLocalProgress: viewModel.clearLocalProgress,
                onRefreshNotificationDiagnostics: viewModel.refreshNotificationDiagnostics,
                onSendDebugReminder: viewModel.sendDebugReminder,
                onPreviewBadgeCollectionNext: {
                    viewModel.previewBadgeCollection(currentStreak: 20, bestStreak: 20)
                    viewModel.openStats()
                },
                onPreviewBadgeCollectionEarned30: {
                    viewModel.previewBadgeCollection(currentStreak: 32, bestStreak: 32)
                    viewModel.openStats()
                },
                onPreviewBadgeUnlock7: { viewModel.previewBadgeUnlock(.day7) },
                onPreviewBadgeUnlock14: { viewModel.previewBadgeUnlock(.day14) },
                onPreviewBadgeUnlock30: { viewModel.previewBadgeUnlock(.day30) },
                onClearBadgeDebugPreviews: viewModel.clearBadgeDebugPreviews
            )
#else
            SettingsView(
                preferences: viewModel.preferences,
                displayedDailyRemindersEnabled: viewModel.displayedDailyRemindersEnabled,
                externalLinks: viewModel.externalLinks,
                onBack: viewModel.closeSettings,
                onSetAnalyticsEnabled: viewModel.setAnalyticsEnabled,
                onSetAggregateSharingEnabled: viewModel.setAggregateSharingEnabled,
                onSetHapticsEnabled: viewModel.setHapticsEnabled,
                onSetDailyRemindersEnabled: viewModel.setDailyRemindersEnabled,
                onOpenSupport: viewModel.trackSupportOpened,
                onOpenPrivacy: viewModel.trackPrivacyOpened
            )
#endif

        case .error:
            ThreadScreenContainer {
                ThreadWordmark(subtitle: "The app couldn't load its puzzle data.")

                ThreadCard(alignment: .center) {
                    Text("Load error")
                        .font(ThreadFont.display(30))
                        .foregroundStyle(ThreadPalette.ink)

                    Text(viewModel.bootErrorMessage ?? "Unknown error")
                        .font(ThreadFont.body(15, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var archiveView: some View {
        ArchiveView(
            items: viewModel.archiveItems,
            onBack: viewModel.closeArchive,
            onSelect: viewModel.openArchiveItem
        )
    }

    private var archiveOpenAction: (() -> Void)? {
        requestArchiveAccess
    }

    private func requestArchiveAccess() {
        if archivePurchaseController.isEntitled {
            viewModel.openArchive()
        } else {
            isArchivePaywallPresented = true
        }
    }

    private func unlockArchive() {
        isArchivePaywallPresented = false
        guard viewModel.screen != .archive else { return }
        viewModel.openArchive()
    }

    private func handleArchiveEntitlementChange(_ isEntitled: Bool) {
        if isEntitled {
            if isArchivePaywallPresented {
                unlockArchive()
            }
            return
        }

        switch viewModel.screen {
        case .archive, .archiveRound, .archiveResult:
            viewModel.closeArchive()
        default:
            break
        }
    }

    private var notificationPromptBinding: Binding<ThreadNotificationPrompt?> {
        Binding(
            get: { viewModel.notificationPrompt },
            set: { newValue in
                if newValue == nil {
                    viewModel.clearNotificationPromptPresentation()
                }
            }
        )
    }

    private func presentInitialResolvedScreenIfNeeded(_ screen: ThreadScreen) {
        guard screen != .loading else { return }
        guard !hasPresentedInitialResolvedScreen else { return }

        hasPresentedInitialResolvedScreen = true

        if reduceMotion {
            initialResolvedScreenVisible = true
            return
        }

        initialResolvedScreenVisible = false
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.16)) {
                initialResolvedScreenVisible = true
            }
        }
    }
}

private struct ThreadInitialResolvedScreenEntrance: ViewModifier {
    let screen: ThreadScreen
    let isVisible: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if screen == .loading || reduceMotion {
            content
        } else {
            content
                .opacity(isVisible ? 1 : 0.97)
                .offset(y: isVisible ? 0 : 5)
        }
    }
}
