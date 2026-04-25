import SwiftUI
import UIKit

@main
struct ThreadNativeApp: App {
    @UIApplicationDelegateAdaptor(ThreadAppDelegate.self) private var appDelegate
    @StateObject private var viewModel = ThreadRootViewModel()

    var body: some Scene {
        WindowGroup {
            ThreadRootView(
                viewModel: viewModel,
                appDelegate: appDelegate
            )
        }
    }
}

struct ThreadRootView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: ThreadRootViewModel
    @ObservedObject var appDelegate: ThreadAppDelegate
    @State private var showsDailyReveal = false
    @State private var hasShownInitialDailyReveal = false

    private let dailyRevealDisplayDuration: Duration = .milliseconds(350)
    private let dailyRevealFadeDuration: Double = 0.2

    var body: some View {
        ZStack {
            ThreadBackground()

            screenView
                .transition(ThreadMotion.pageTransition)

            if showsDailyReveal {
                ThreadDailyRevealView(roundNumber: viewModel.dailyRoundNumber)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(ThreadMotion.defaultSpring, value: viewModel.screen)
        .task {
            await viewModel.bootstrapIfNeeded()
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
        .onChange(of: viewModel.screen) { _, newValue in
            showDailyRevealIfNeeded(for: newValue)
        }
        .onChange(of: viewModel.launchRevealReplayToken) { _, _ in
            showDailyReveal(force: true, for: viewModel.screen)
        }
        .alert(item: notificationPromptBinding) { prompt in
            switch prompt.kind {
            case .requestAuthorization:
                Alert(
                    title: Text(prompt.title),
                    message: Text(prompt.message),
                    primaryButton: .default(Text(prompt.confirmTitle)) {
                        Task {
                            await viewModel.confirmNotificationPrompt()
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
                    onFirstDailyNudgeSubmission: viewModel.handleFirstDailyNudgeSubmission,
                    onComplete: viewModel.completeDaily,
                    onViewStats: viewModel.openStats,
                    onOpenSettings: viewModel.openSettings
                )
                .id("daily-\(viewModel.todayDateKey)-\(round.id)")
            }

        case .results:
            if let round = viewModel.dailyRound, let result = viewModel.currentDailyResult {
                ResultsView(
                    round: round,
                    roundNumber: viewModel.dailyRoundNumber,
                    appShareURL: viewModel.externalLinks.shareAppURL,
                    appShareLabel: viewModel.externalLinks.shareAppLinkTitle,
                    score: result.score,
                    nextUnlockDate: viewModel.nextDailyRefreshDate,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onViewStats: viewModel.openStats,
                    onShare: viewModel.confirmSharedResults,
                    onOpenSettings: viewModel.openSettings
                )
            }

        case .alreadyPlayed:
            if let round = viewModel.dailyRound, let entry = viewModel.currentDailyResult {
                AlreadyPlayedView(
                    round: round,
                    roundNumber: viewModel.dailyRoundNumber,
                    appShareURL: viewModel.externalLinks.shareAppURL,
                    appShareLabel: viewModel.externalLinks.shareAppLinkTitle,
                    entry: entry,
                    nextUnlockDate: viewModel.nextDailyRefreshDate,
                    hapticsEnabled: viewModel.preferences.hapticsEnabled,
                    onViewStats: viewModel.openStats,
                    onShare: viewModel.confirmSharedResults,
                    onOpenSettings: viewModel.openSettings
                )
            }

        case .stats:
            StatsView(
                history: viewModel.history,
                todayKey: viewModel.todayDateKey,
                onBack: viewModel.closeStats,
                onOpenSettings: viewModel.openSettings
            )

        case .settings:
            SettingsView(
                preferences: viewModel.preferences,
                displayedDailyRemindersEnabled: viewModel.displayedDailyRemindersEnabled,
                notificationAuthorizationStatus: viewModel.notificationAuthorizationStatus,
                notificationDebugSummary: viewModel.notificationDebugSummary,
                notificationDebugFeedback: viewModel.notificationDebugFeedback,
                externalLinks: viewModel.externalLinks,
                onBack: viewModel.closeSettings,
                onSetAnalyticsEnabled: viewModel.setAnalyticsEnabled,
                onSetAggregateSharingEnabled: viewModel.setAggregateSharingEnabled,
                onSetHapticsEnabled: viewModel.setHapticsEnabled,
                onSetDailyRemindersEnabled: viewModel.setDailyRemindersEnabled,
                onOpenSupport: viewModel.trackSupportOpened,
                onOpenPrivacy: viewModel.trackPrivacyOpened,
                onClearLocalProgress: viewModel.clearLocalProgress,
                onReplayLaunchReveal: viewModel.replayLaunchReveal,
                onRefreshNotificationDiagnostics: viewModel.refreshNotificationDiagnostics,
                onSendDebugReminder: viewModel.sendDebugReminder
            )

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

    private var notificationPromptBinding: Binding<ThreadNotificationPrompt?> {
        Binding(
            get: { viewModel.notificationPrompt },
            set: { newValue in
                if newValue == nil {
                    viewModel.dismissNotificationPrompt()
                }
            }
        )
    }

    private func showDailyRevealIfNeeded(for screen: ThreadScreen) {
        showDailyReveal(force: false, for: screen)
    }

    private func showDailyReveal(force: Bool, for screen: ThreadScreen) {
        guard force || !hasShownInitialDailyReveal else { return }
        switch screen {
        case .daily, .alreadyPlayed:
            hasShownInitialDailyReveal = true
            showsDailyReveal = true

            Task {
                try? await Task.sleep(for: dailyRevealDisplayDuration)
                await MainActor.run {
                    withAnimation(.easeOut(duration: dailyRevealFadeDuration)) {
                        showsDailyReveal = false
                    }
                }
            }

        default:
            break
        }
    }
}
