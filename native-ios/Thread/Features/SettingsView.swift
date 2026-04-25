import SwiftUI

@MainActor
struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    private let reminderSchedule = ThreadReminderSchedule.fromBundle()

    let preferences: ThreadPreferences
    let displayedDailyRemindersEnabled: Bool
    let notificationAuthorizationStatus: ThreadNotificationAuthorizationStatus
    let notificationDebugSummary: String
    let notificationDebugFeedback: String?
    let externalLinks: ThreadExternalLinks
    let onBack: () -> Void
    let onSetAnalyticsEnabled: (Bool) -> Void
    let onSetAggregateSharingEnabled: (Bool) -> Void
    let onSetHapticsEnabled: (Bool) -> Void
    let onSetDailyRemindersEnabled: (Bool) -> Void
    let onOpenSupport: () -> Void
    let onOpenPrivacy: () -> Void
    let onClearLocalProgress: () -> Void
    let onReplayLaunchReveal: () -> Void
    let onRefreshNotificationDiagnostics: () -> Void
    let onSendDebugReminder: () -> Void

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                leading: ThreadBarAction(systemName: "chevron.left", label: "Back", action: onBack)
            )

            ThreadWordmark(subtitle: "Preferences for this device.")

            ThreadAdaptiveSplit {
                ThreadCard {
                    Text("Privacy and feel")
                        .font(ThreadFont.display(30))
                        .foregroundStyle(ThreadPalette.ink)

                    Toggle(isOn: dailyRemindersBinding) {
                        settingsRow(
                            title: "Daily reminders",
                            body: dailyRemindersDescription
                        )
                    }
                    .tint(ThreadPalette.accent)

                    Divider()
                        .overlay(ThreadPalette.border)

                    Toggle(isOn: analyticsBinding) {
                        settingsRow(
                            title: "Anonymous analytics",
                            body: "Help improve Daily Thread by sharing lightweight anonymous usage analytics about completion, retention, and friction points."
                        )
                    }
                    .tint(ThreadPalette.accent)

                    Divider()
                        .overlay(ThreadPalette.border)

                    Toggle(isOn: aggregateSharingBinding) {
                        settingsRow(
                            title: "Share anonymous results",
                            body: "Allow your finished daily result to contribute to overall score distributions. No account or personal profile."
                        )
                    }
                    .tint(ThreadPalette.accent)

                    Divider()
                        .overlay(ThreadPalette.border)

                    Toggle(isOn: hapticsBinding) {
                        settingsRow(
                            title: "Haptics",
                            body: "Keep the native feedback pulses on for correct solves, misses, and key actions."
                        )
                    }
                    .tint(ThreadPalette.accent)
                }
            } secondary: {
                EmptyView()
            }

            if externalLinks.hasAnyLink {
                ThreadCard {
                    Text("Support and privacy")
                        .font(ThreadFont.body(12, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(ThreadPalette.faint)

                    VStack(spacing: 0) {
                        if let supportDestination = supportDestination {
                            Button {
                                onOpenSupport()
                                openURL(supportDestination)
                            } label: {
                                externalLinkRow(
                                    title: supportButtonTitle,
                                    body: supportButtonBody
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if let privacyPolicyURL = externalLinks.privacyPolicyURL {
                            if supportDestination != nil {
                                Divider()
                                    .overlay(ThreadPalette.border)
                            }

                            Button {
                                onOpenPrivacy()
                                openURL(privacyPolicyURL)
                            } label: {
                                externalLinkRow(
                                    title: "Privacy policy",
                                    body: privacyPolicyURL.absoluteString
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

#if DEBUG
            ThreadCard {
                Text("Local data")
                    .font(ThreadFont.body(12, weight: .semibold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(ThreadPalette.faint)

                VStack(spacing: 12) {
                    Button {
                        onSendDebugReminder()
                    } label: {
                        debugToolRow(
                            title: debugReminderActionTitle,
                            body: debugReminderActionBody,
                            icon: debugReminderActionIcon
                        )
                    }
                    .buttonStyle(ThreadDebugToolButtonStyle())

                    Button {
                        onRefreshNotificationDiagnostics()
                    } label: {
                        debugToolRow(
                            title: "Refresh notification diagnostics",
                            body: "Inspect authorization state and pending reminders",
                            icon: "arrow.clockwise"
                        )
                    }
                    .buttonStyle(ThreadDebugToolButtonStyle())

                    if let notificationDebugFeedback {
                        Text(notificationDebugFeedback)
                            .font(ThreadFont.body(12, weight: .semibold))
                            .foregroundStyle(ThreadPalette.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }

                    Text(notificationDebugSummary)
                        .font(ThreadFont.body(12, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)

                    Button {
                        onClearLocalProgress()
                    } label: {
                        debugToolRow(
                            title: "Reset app to first launch",
                            body: "Clear saved history, in-progress daily state, and tutorial completion on this device. Preferences stay intact.",
                            icon: "trash",
                            titleColor: ThreadPalette.failure,
                            iconColor: ThreadPalette.failure
                        )
                    }
                    .buttonStyle(ThreadDebugToolButtonStyle())

                    Button {
                        onReplayLaunchReveal()
                    } label: {
                        debugToolRow(
                            title: "Replay launch animation",
                            body: "Replay the current Thread intro reveal without clearing your saved progress",
                            icon: "sparkles"
                        )
                    }
                    .buttonStyle(ThreadDebugToolButtonStyle())
                }
            }
#endif
        }
    }

    private var analyticsBinding: Binding<Bool> {
        Binding(
            get: { preferences.analyticsEnabled },
            set: { newValue in
                onSetAnalyticsEnabled(newValue)
            }
        )
    }

    private var aggregateSharingBinding: Binding<Bool> {
        Binding(
            get: { preferences.aggregateSharingEnabled },
            set: { newValue in
                onSetAggregateSharingEnabled(newValue)
            }
        )
    }

    private var dailyRemindersBinding: Binding<Bool> {
        Binding(
            get: { displayedDailyRemindersEnabled },
            set: { newValue in
                onSetDailyRemindersEnabled(newValue)
            }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { preferences.hapticsEnabled },
            set: { newValue in
                onSetHapticsEnabled(newValue)
            }
        )
    }

    private var dailyRemindersDescription: String {
        "Get a reminder at \(formattedReminderTime(hour: 9, minute: 0)) when the new Thread goes live, and another at \(formattedReminderTime(hour: reminderSchedule.finalReminderHour, minute: reminderSchedule.finalReminderMinute)) if there are still a few hours left to solve it."
    }

    private var debugReminderActionTitle: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return "Allow notifications + test"
        case .denied, .unsupported:
            return "Notifications blocked"
        case .authorized, .provisional, .ephemeral:
            return "Send test reminder"
        }
    }

    private var debugReminderActionBody: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return "Request iOS permission, then schedule a local notification in 10 seconds"
        case .denied, .unsupported:
            return "This app cannot schedule reminders until notifications are enabled in iOS Settings"
        case .authorized, .provisional, .ephemeral:
            return "Schedule a local notification in 10 seconds"
        }
    }

    private var debugReminderActionIcon: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return "bell.badge"
        case .denied, .unsupported:
            return "exclamationmark.bubble"
        case .authorized, .provisional, .ephemeral:
            return "bell.badge"
        }
    }

    private var supportDestination: URL? {
        externalLinks.supportURL ?? externalLinks.supportEmailURL
    }

    private var supportButtonTitle: String {
        externalLinks.supportURL != nil ? "Support site" : "Email support"
    }

    private var supportButtonBody: String {
        if let supportURL = externalLinks.supportURL {
            return supportURL.absoluteString
        }

        if let email = externalLinks.supportEmailAddress {
            return email
        }

        return ""
    }

    @ViewBuilder
    private func settingsRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ThreadFont.body(15, weight: .semibold))
                .foregroundStyle(ThreadPalette.ink)

            Text(body)
                .font(ThreadFont.body(13, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func formattedReminderTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        let components = DateComponents(hour: hour, minute: minute)
        let calendar = Calendar.autoupdatingCurrent
        let fallback = String(format: "%02d:%02d", hour, minute)

        guard let date = calendar.date(from: components) else {
            return fallback
        }

        return formatter.string(from: date)
    }

    @ViewBuilder
    private func debugToolRow(
        title: String,
        body: String,
        icon: String,
        titleColor: Color = ThreadPalette.ink,
        iconColor: Color = ThreadPalette.faint
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ThreadFont.body(15, weight: .semibold))
                    .foregroundStyle(titleColor)

                Text(body)
                    .font(ThreadFont.body(13, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func externalLinkRow(title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(ThreadFont.body(15, weight: .semibold))
                    .foregroundStyle(ThreadPalette.ink)

                Text(body)
                    .font(ThreadFont.body(13, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ThreadPalette.faint)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 14)
    }
}

private struct ThreadDebugToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ThreadPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(ThreadPalette.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed ? 0.992 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
