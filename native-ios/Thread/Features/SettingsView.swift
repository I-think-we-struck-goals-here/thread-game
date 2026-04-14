import SwiftUI

@MainActor
struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    let preferences: ThreadPreferences
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
                            body: "Get a reminder at 9:00 AM when the new Thread goes live, and another at 9:00 PM if there are still a few hours left to solve it."
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
                        onClearLocalProgress()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset app to first launch")
                                    .font(ThreadFont.body(15, weight: .semibold))
                                    .foregroundStyle(ThreadPalette.failure)

                                Text("Clear saved history, in-progress daily state, and tutorial completion on this device. Preferences stay intact.")
                                    .font(ThreadFont.body(13, weight: .medium))
                                    .foregroundStyle(ThreadPalette.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ThreadPalette.failure)
                        }
                    }
                    .threadButton(.secondary)

                    Button {
                        onReplayLaunchReveal()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Replay launch animation")
                                    .font(ThreadFont.body(15, weight: .semibold))
                                    .foregroundStyle(ThreadPalette.ink)

                                Text("Replay the current Thread intro reveal without clearing your saved progress.")
                                    .font(ThreadFont.body(13, weight: .medium))
                                    .foregroundStyle(ThreadPalette.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ThreadPalette.faint)
                        }
                    }
                    .threadButton(.secondary)
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
            get: { preferences.dailyRemindersEnabled },
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
