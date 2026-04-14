import SwiftUI

struct TutorialView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let onStartPractice: () -> Void
    let onSkipToDaily: () -> Void
    let onOpenSettings: () -> Void

    private let steps = [
        "Start with one clue",
        "Type your best guess",
        "Wrong guess reveals the next clue",
    ]

    private var usesTabletLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollViewReader { proxy in
            ThreadScreenContainer {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Spacer()

                        ThreadIconButton(
                            action: ThreadBarAction(systemName: "gearshape", label: "Settings", action: onOpenSettings)
                        )
                    }

                    ThreadWordmark(subtitle: nil)

                    if usesTabletLayout {
                        VStack(spacing: 18) {
                            tutorialHeroCard(proxy: proxy)
                                .frame(maxWidth: 460)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 18, alignment: .top),
                                    GridItem(.flexible(), spacing: 18, alignment: .top),
                                ],
                                alignment: .center,
                                spacing: 18
                            ) {
                                tutorialHowItWorksSection
                                    .id("tutorial-guide")

                                tutorialRevealSection

                                tutorialScoringSection

                                tutorialShareSection
                            }

                            VStack(spacing: 10) {
                                Button("Start 3 practice rounds", action: onStartPractice)
                                    .threadButton(.primary)
                                    .frame(maxWidth: 340)
                            }
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: 920)
                    } else {
                        VStack(spacing: 10) {
                            tutorialHeroCard(proxy: proxy)

                            tutorialSections

                            VStack(spacing: 10) {
                                Button("Start 3 practice rounds", action: onStartPractice)
                                    .threadButton(.primary)
                            }
                            .padding(.top, 6)
                        }
                        .frame(maxWidth: 340)
                    }
                }
            }
        }
    }

    private func tutorialHeroCard(proxy: ScrollViewProxy) -> some View {
        ThreadCard(alignment: .center) {
            Text("New to Thread?")
                .font(ThreadFont.body(9.5, weight: .bold))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.faint)

            Text("Learn how to play")
                .font(ThreadFont.display(usesTabletLayout ? 31 : 28, weight: .semibold))
                .foregroundStyle(ThreadPalette.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(-2)

            Text("Find one hidden word from clue words.")
                .font(ThreadFont.body(13.5, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Button {
                    withAnimation(ThreadMotion.defaultSpring) {
                        proxy.scrollTo("tutorial-guide", anchor: .top)
                    }
                } label: {
                    Text("Learn how to play ↓")
                }
                .threadButton(.primary)

                Button("Skip to today's puzzle", action: onSkipToDaily)
                    .threadButton(.secondary)
            }
        }
    }

    private var tutorialSections: some View {
        VStack(spacing: 10) {
            tutorialHowItWorksSection
                .id("tutorial-guide")

            tutorialRevealSection

            tutorialScoringSection

            tutorialShareSection
        }
    }

    private var tutorialHowItWorksSection: some View {
        TutorialSectionCard(
            icon: "🧵",
            title: "How Thread works",
            description: "You are finding one hidden word from clue words."
        ) {
            VStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(ThreadFont.body(11, weight: .bold))
                            .foregroundStyle(ThreadPalette.accent)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(ThreadPalette.accentSoft)
                            )

                        Text(step)
                            .font(ThreadFont.body(12.6, weight: .medium))
                            .foregroundStyle(ThreadPalette.ink)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ThreadPalette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ThreadPalette.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var tutorialRevealSection: some View {
        TutorialSectionCard(
            icon: "💡",
            title: "Clues reveal one by one",
            description: "Guess whenever you feel ready. Wrong guesses unlock the next clue."
        ) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(["SATURN", "BOXING", "PHONE"], id: \.self) { word in
                    Text(word)
                        .font(ThreadFont.display(19.5, weight: .regular))
                        .tracking(2.1)
                        .foregroundStyle(ThreadPalette.ink)
                }

                ForEach(Array(["???", "???"].enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .font(ThreadFont.display(19.5, weight: .regular))
                        .tracking(2.1)
                        .foregroundStyle(ThreadPalette.faint)
                }

                Divider()
                    .overlay(ThreadPalette.border)
                    .padding(.vertical, 8)

                Text("RING")
                    .font(ThreadFont.display(22, weight: .semibold))
                    .tracking(2.6)
                    .foregroundStyle(ThreadPalette.accent)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ThreadPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ThreadPalette.border, lineWidth: 1)
            )
        }
    }

    private var tutorialScoringSection: some View {
        TutorialSectionCard(
            icon: "⚡",
            title: "Fewer clues = better score",
            description: "Bold guesses can win big. More wrong guesses means a lower rating."
        ) {
            VStack(spacing: 8) {
                ForEach(ScoreTier.allCases, id: \.rawValue) { tier in
                    HStack(spacing: 12) {
                        ScoreDotsMeterView(score: tier.rawValue)
                            .frame(width: 80, alignment: .leading)

                        Text("\(tier.rawValue) clue\(tier.rawValue == 1 ? "" : "s")")
                            .font(ThreadFont.body(12.4, weight: .medium))
                            .foregroundStyle(ThreadPalette.muted)
                            .frame(width: 72, alignment: .leading)

                        Text(tier.title)
                            .font(ThreadFont.body(12.4, weight: .semibold))
                            .foregroundStyle(ThreadPalette.ink)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var tutorialShareSection: some View {
        TutorialSectionCard(
            icon: "📤",
            title: "Share your result",
            description: "Daily puzzle. Share a spoiler-free emoji grid when you finish."
        ) {
            VStack(spacing: 6) {
                Text("🧵 THREAD #42")
                    .font(ThreadFont.body(13.5, weight: .semibold))
                    .foregroundStyle(ThreadPalette.ink)

                Text("🟢🟢⚪⚪⚪")
                    .font(.system(size: 22))
                    .tracking(5)

                Text("Brilliant - 2 clues")
                    .font(ThreadFont.body(11.5, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ThreadPalette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ThreadPalette.border, lineWidth: 1)
            )
        }
    }
}

private struct TutorialSectionCard<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let content: Content

    init(
        icon: String,
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        ThreadCard {
            Text(icon)
                .font(.system(size: 22))

            Text(title)
                .font(ThreadFont.display(24.5, weight: .semibold))
                .foregroundStyle(ThreadPalette.ink)

            Text(description)
                .font(ThreadFont.body(13.2, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
    }
}
