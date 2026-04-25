import SwiftUI

struct ThreadRoundView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let kicker: String
    let prompt: String
    let completionButtonTitle: String
    let autoAdvanceOnFailure: Bool
    let hapticsEnabled: Bool
    let onRoundStarted: ((Bool) -> Void)?
    let firstDailyNudgeStage: ThreadFirstDailyNudgeStage?
    let onFirstDailyNudgeSubmission: ((GuessSubmissionOutcome) -> Void)?
    let onComplete: (ThreadRoundCompletion) -> Void
    let onViewStats: (() -> Void)?
    let onOpenSettings: (() -> Void)?
    let secondaryActionTitle: String?
    let onSecondaryAction: (() -> Void)?

    @StateObject private var viewModel: ThreadGameViewModel
    @State private var hasTrackedRoundStart = false

    private var usesTabletLayout: Bool {
        horizontalSizeClass == .regular
    }

    init(
        round: ThreadRound,
        dateKey: String? = nil,
        snapshot: GameSnapshot? = nil,
        kicker: String,
        prompt: String = "Find the connection",
        completionButtonTitle: String,
        autoAdvanceOnFailure: Bool = false,
        hapticsEnabled: Bool = true,
        onPersistSnapshot: @escaping (GameSnapshot) -> Void = { _ in },
        onRoundStarted: ((Bool) -> Void)? = nil,
        firstDailyNudgeStage: ThreadFirstDailyNudgeStage? = nil,
        onFirstDailyNudgeSubmission: ((GuessSubmissionOutcome) -> Void)? = nil,
        onComplete: @escaping (ThreadRoundCompletion) -> Void,
        onViewStats: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.kicker = kicker
        self.prompt = prompt
        self.completionButtonTitle = completionButtonTitle
        self.autoAdvanceOnFailure = autoAdvanceOnFailure
        self.hapticsEnabled = hapticsEnabled
        self.onRoundStarted = onRoundStarted
        self.firstDailyNudgeStage = firstDailyNudgeStage
        self.onFirstDailyNudgeSubmission = onFirstDailyNudgeSubmission
        self.onComplete = onComplete
        self.onViewStats = onViewStats
        self.onOpenSettings = onOpenSettings
        self.secondaryActionTitle = secondaryActionTitle
        self.onSecondaryAction = onSecondaryAction
        _viewModel = StateObject(
            wrappedValue: ThreadGameViewModel(
                round: round,
                dateKey: dateKey,
                snapshot: snapshot,
                persistSnapshot: onPersistSnapshot
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
            let headerTopPadding: CGFloat = usesTabletLayout ? 22 : 28
            let contentTopPadding: CGFloat = usesTabletLayout ? 92 : 110

            ZStack {
                ThreadBackground()

                if usesTabletLayout {
                    ipadRoundLayout(bottomInset: bottomInset, headerTopPadding: headerTopPadding, contentTopPadding: contentTopPadding)
                } else {
                    phoneRoundLayout(bottomInset: bottomInset, headerTopPadding: headerTopPadding, contentTopPadding: contentTopPadding)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !viewModel.isComplete && !usesTabletLayout {
                    composerBar(bottomInset: bottomInset)
                }
            }
        }
        .onChange(of: viewModel.guess) { _, _ in
            viewModel.clearFeedbackForActiveEditing()
            viewModel.persist()
        }
        .onChange(of: viewModel.revealedClueCount) { _, _ in
            viewModel.persist()
        }
        .onChange(of: viewModel.isSolved) { _, _ in
            viewModel.persist()
        }
        .onChange(of: viewModel.isFailed) { _, _ in
            viewModel.persist()
        }
        .task {
            if !hasTrackedRoundStart {
                hasTrackedRoundStart = true
                onRoundStarted?(viewModel.resumedFromSavedProgress)
            }
        }
    }

    @ViewBuilder
    private func phoneRoundLayout(bottomInset: CGFloat, headerTopPadding: CGFloat, contentTopPadding: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            roundContent
                .frame(maxWidth: contentWidth, alignment: .leading)
                .padding(.top, contentTopPadding)
                .padding(.horizontal, 18)
                .padding(.bottom, viewModel.isComplete ? max(18, bottomInset + 16) : 16)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .overlay(alignment: .top) {
            topBar
                .frame(maxWidth: contentWidth)
                .padding(.top, 6)
                .padding(.horizontal, 18)
        }
        .overlay(alignment: .top) {
            headerCluster
                .frame(maxWidth: .infinity)
                .padding(.top, headerTopPadding)
        }
    }

    @ViewBuilder
    private func ipadRoundLayout(bottomInset: CGFloat, headerTopPadding: CGFloat, contentTopPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                topBar
                    .frame(maxWidth: stageWidth)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                headerCluster
                    .padding(.top, headerTopPadding)
            }
            .frame(height: 82)

            VStack(spacing: 0) {
                roundContent
                    .frame(maxWidth: contentWidth, alignment: .leading)
                    .padding(.top, contentTopPadding - 82)
                    .frame(maxWidth: .infinity, alignment: .top)

                Spacer(minLength: 30)

                if !viewModel.isComplete {
                    composerBar(bottomInset: max(10, bottomInset + 8))
                        .frame(maxWidth: stageWidth)
                }
            }
            .frame(maxWidth: stageWidth, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }

    private var topBar: some View {
        ThreadTopBar(
            trailing: [
                onViewStats.map {
                    ThreadBarAction(systemName: "chart.bar.xaxis", label: "Stats", action: $0)
                },
                onOpenSettings.map {
                    ThreadBarAction(systemName: "gearshape", label: "Settings", action: $0)
                },
            ].compactMap { $0 }
        )
    }

    private var headerCluster: some View {
        VStack(spacing: 6) {
            Text(kicker)
                .font(ThreadFont.body(10, weight: .medium))
                .tracking(4)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.muted)

            ProgressDotsView(
                total: 5,
                activeCount: viewModel.revealedClueCount,
                color: viewModel.isSolved ? ThreadPalette.accent : ThreadPalette.ink
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var roundContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let secondaryActionTitle, let onSecondaryAction {
                Button(action: onSecondaryAction) {
                    Text(secondaryActionTitle)
                        .font(ThreadFont.body(11, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(ThreadPalette.surface)
                        )
                        .overlay(
                            Capsule()
                                .stroke(ThreadPalette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 18)
            }

            if let firstDailyNudgeStage {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    FirstDailyNudgeCard(stage: firstDailyNudgeStage)
                }
                .padding(.bottom, 14)
                .transition(ThreadMotion.revealTransition)
            }

            Text(prompt)
                .font(ThreadFont.body(12, weight: .medium))
                .tracking(2.5)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, usesTabletLayout ? 24 : 20)

            VStack(spacing: usesTabletLayout ? 13 : 11) {
                ForEach(Array(viewModel.visibleClues.enumerated()), id: \.element.id) { index, clue in
                    let isNewest = index == viewModel.visibleClues.count - 1 && !viewModel.isComplete

                    VStack(alignment: .leading, spacing: viewModel.isComplete ? 3 : 0) {
                        Text(clue.word)
                            .font(
                                ThreadFont.display(
                                    isNewest ? (usesTabletLayout ? 34 : 28) : (usesTabletLayout ? 24 : 20),
                                    weight: isNewest ? .medium : .light
                                )
                            )
                            .tracking(isNewest ? 2.4 : 1.5)
                            .foregroundStyle(
                                viewModel.isComplete
                                ? ThreadPalette.muted
                                : (isNewest ? ThreadPalette.ink : Color(red: 0.42, green: 0.39, blue: 0.35))
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        if viewModel.isComplete {
                            Text(clue.connection)
                                .font(ThreadFont.body(10.5, weight: .regular))
                                .italic()
                                .foregroundStyle(ThreadPalette.faint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(ThreadMotion.revealTransition)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(clueAccessibilityLabel(index: index, clue: clue))
                }
            }
            .frame(maxWidth: contentWidth)
            .frame(minHeight: usesTabletLayout ? 250 : 150, alignment: .topLeading)
            .padding(.bottom, viewModel.isComplete ? (usesTabletLayout ? 26 : 20) : 0)
            .animation(ThreadMotion.defaultSpring, value: viewModel.revealedClueCount)

            if viewModel.isComplete {
                VStack(spacing: 10) {
                    Text(viewModel.round.answer)
                        .font(ThreadFont.display(usesTabletLayout ? 46 : 38, weight: .bold))
                        .tracking(4)
                        .foregroundStyle(viewModel.score == nil ? ThreadPalette.failure : ThreadPalette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Text(resultLine)
                        .font(ThreadFont.body(12.5, weight: .regular))
                        .foregroundStyle(ThreadPalette.muted)
                        .multilineTextAlignment(.center)

                    Button(completionButtonTitle) {
                        onComplete(viewModel.completionSummary())
                    }
                    .threadButton(.primary)
                }
                .frame(maxWidth: contentWidth)
                .padding(.top, 4)
                .transition(ThreadMotion.revealTransition)
            }
        }
    }

    private var canSubmit: Bool {
        !GuessNormalizer.normalize(viewModel.guess).isEmpty && !viewModel.isComplete
    }

    private var resultLine: String {
        guard let score = viewModel.score, let tier = ScoreTier(rawValue: score) else {
            return "The thread was \(viewModel.round.answer.capitalized)."
        }
        return "\(tier.title) - \(score) clue\(score == 1 ? "" : "s")"
    }

    @ViewBuilder
    private func composerBar(bottomInset: CGFloat) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                CenteredGuessComposerView(guess: viewModel.guess)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Your guess")
                    .accessibilityValue(viewModel.guess.isEmpty ? "Empty" : viewModel.guess)
                    .accessibilityHint("Type using the keyboard below.")
                .frame(height: 34)

                composerUnderline
            }
            .frame(maxWidth: contentWidth)

            Button("Submit", action: handleSubmit)
                .threadButton(.primary)
                .disabled(!canSubmit)
                .frame(maxWidth: contentWidth)

            feedbackRow
                .frame(maxWidth: contentWidth)

            attemptsView
                .frame(maxWidth: contentWidth)

            keyboardView
                .frame(maxWidth: keyboardWidth)
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 28 : 18)
        .padding(.top, 12)
        .padding(.bottom, max(6, bottomInset - 2))
        .frame(maxWidth: .infinity)
        .background(ThreadPalette.background)
    }

    private func handleSubmit() {
        let hadSubmittedGuessBefore = viewModel.hasSubmittedGuess
        let outcome = viewModel.submitGuess()

        switch outcome {
        case .ignored, .alreadyComplete:
            break
        case .solved:
            ThreadHaptics.success(enabled: hapticsEnabled)
        case .revealedNextClue:
            ThreadHaptics.tap(enabled: hapticsEnabled)
        case .duplicate:
            ThreadHaptics.warning(enabled: hapticsEnabled)
        case .failed:
            ThreadHaptics.warning(enabled: hapticsEnabled)
            if autoAdvanceOnFailure {
                onComplete(viewModel.completionSummary())
            }
        }

        if !hadSubmittedGuessBefore {
            onFirstDailyNudgeSubmission?(outcome)
        }
    }

    private var feedbackRow: some View {
        Group {
            if let feedback = viewModel.feedback {
                Text(feedback.text)
                    .font(ThreadFont.body(11.5, weight: .medium))
                    .italic()
                    .foregroundStyle(feedback.tone == .warning ? ThreadPalette.failure : ThreadPalette.muted)
                    .multilineTextAlignment(.center)
                    .accessibilityElement(children: .combine)
            } else {
                Color.clear
            }
        }
        .frame(height: viewModel.feedback == nil ? 0 : 18)
    }

    private var attemptsView: some View {
        Group {
            if viewModel.attempts.isEmpty {
                Color.clear
            } else {
                attemptsLine
                    .font(ThreadFont.body(12, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(ThreadPalette.faint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: attemptsAreaHeight, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Previous guesses")
        .accessibilityValue(viewModel.attempts.isEmpty ? "None" : viewModel.attempts.joined(separator: ", "))
    }

    private var keyboardView: some View {
        VStack(spacing: 8) {
            keyboardRow([.letter("Q"), .letter("W"), .letter("E"), .letter("R"), .letter("T"), .letter("Y"), .letter("U"), .letter("I"), .letter("O"), .letter("P")])
            keyboardRow([.letter("A"), .letter("S"), .letter("D"), .letter("F"), .letter("G"), .letter("H"), .letter("J"), .letter("K"), .letter("L")])
                .padding(.horizontal, horizontalSizeClass == .regular ? 28 : 18)
            keyboardRow([.submit, .letter("Z"), .letter("X"), .letter("C"), .letter("V"), .letter("B"), .letter("N"), .letter("M"), .delete])
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Keyboard")
    }

    private func keyboardRow(_ keys: [ThreadKeyboardKey]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                Button {
                    handleKeyboardKey(key)
                } label: {
                    Group {
                        switch key {
                        case .letter(let letter):
                            Text(letter)
                        case .submit:
                            Text("ENTER")
                        case .delete:
                            Image(systemName: "delete.left")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .font(ThreadFont.body(key.isAction ? 12 : 16, weight: .bold))
                    .tracking(key.isAction ? 0.8 : 0.2)
                    .foregroundStyle(ThreadPalette.ink)
                    .frame(maxWidth: key.isAction ? nil : .infinity)
                    .frame(minHeight: 44)
                    .frame(width: key.isAction ? 62 : nil)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(key.isAction ? ThreadPalette.surfaceMuted : ThreadPalette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(key.isAction ? ThreadPalette.border : ThreadPalette.border.opacity(0.82), lineWidth: 1)
                    )
                }
                .buttonStyle(ThreadKeyboardButtonStyle())
                .disabled(key == .submit ? !canSubmit : viewModel.isComplete)
                .opacity(key == .submit && !canSubmit ? 0.42 : 1)
                .accessibilityLabel(key.accessibilityLabel)
            }
        }
    }

    private func handleKeyboardKey(_ key: ThreadKeyboardKey) {
        guard !viewModel.isComplete else { return }

        switch key {
        case .letter(let letter):
            ThreadHaptics.selection(enabled: hapticsEnabled)
            appendLetter(letter)
        case .delete:
            ThreadHaptics.selection(enabled: hapticsEnabled)
            deleteBackward()
        case .submit:
            handleSubmit()
        }
    }

    private func appendLetter(_ letter: String) {
        guard viewModel.guess.count < maxGuessLength else { return }
        viewModel.guess.append(letter)
    }

    private func deleteBackward() {
        guard !viewModel.guess.isEmpty else { return }
        viewModel.guess.removeLast()
    }

    private var maxGuessLength: Int {
        ThreadGuessLengthPolicy.maxGuessLength(for: viewModel.round)
    }

    private var attemptsAreaHeight: CGFloat {
        viewModel.feedback == nil ? 46 : 28
    }

    private var composerUnderline: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        ThreadPalette.ink.opacity(viewModel.guess.isEmpty ? 0.55 : 0.72),
                        ThreadPalette.ink,
                        ThreadPalette.ink.opacity(viewModel.guess.isEmpty ? 0.55 : 0.72),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .shadow(
                color: ThreadPalette.glow.opacity(viewModel.guess.isEmpty ? 0.82 : 0.45),
                radius: viewModel.guess.isEmpty ? 8 : 4,
                x: 0,
                y: 0
            )
    }

    private var attemptsLine: Text {
        viewModel.attempts.enumerated().reduce(Text("")) { partial, item in
            let (index, attempt) = item
            let word = Text(verbatim: attempt).strikethrough()

            if index == 0 {
                return partial + word
            }

            return partial + Text(verbatim: "   ") + word
        }
    }

    private var contentWidth: CGFloat {
        horizontalSizeClass == .regular ? 640 : 380
    }

    private var keyboardWidth: CGFloat {
        horizontalSizeClass == .regular ? 700 : 420
    }

    private var stageWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : 420
    }

    private func clueAccessibilityLabel(index: Int, clue: RoundClue) -> String {
        if viewModel.isComplete {
            return "Clue \(index + 1). \(clue.word). \(clue.connection)."
        }
        return "Clue \(index + 1). \(clue.word)."
    }
}

private struct FirstDailyNudgeCard: View {
    let stage: ThreadFirstDailyNudgeStage

    private var title: String {
        switch stage {
        case .initial:
            return "Take a guess"
        case .followup:
            return "Find it quickly"
        case .unseen, .completed:
            return ""
        }
    }

    private var bodyText: String {
        switch stage {
        case .initial:
            return "Misses reveal the next clue"
        case .followup:
            return "Fewer clues score better"
        case .unseen, .completed:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ThreadFont.display(18, weight: .regular))
                .foregroundStyle(ThreadPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Text(bodyText)
                .font(ThreadFont.body(11.5, weight: .regular))
                .foregroundStyle(ThreadPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: 184, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThreadPalette.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ThreadPalette.border.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: ThreadPalette.ink.opacity(0.07), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }
}

private struct CenteredGuessComposerView: View {
    let guess: String

    @State private var renderedGuessWidth: CGFloat = 0

    private let displaySize: CGFloat = 24
    private let tracking: CGFloat = 3
    private let caretGap: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            let resolvedGuessWidth = min(renderedGuessWidth, max(0, proxy.size.width - 10))
            let caretOffset = guess.isEmpty ? 0 : min((resolvedGuessWidth / 2) + caretGap, (proxy.size.width / 2) - 4)

            ZStack {
                if !guess.isEmpty {
                    Text(verbatim: guess)
                        .font(ThreadFont.display(displaySize, weight: .light))
                        .tracking(tracking)
                        .foregroundStyle(ThreadPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .background(
                            GeometryReader { textProxy in
                                Color.clear.preference(key: ComposerGuessWidthPreferenceKey.self, value: textProxy.size.width)
                            }
                        )
                }

                TimelineView(.periodic(from: .now, by: 0.6)) { context in
                    let pulseVisible = Int(context.date.timeIntervalSinceReferenceDate / 0.6).isMultiple(of: 2)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(ThreadPalette.ink)
                        .frame(width: 1.5, height: 26)
                        .shadow(color: ThreadPalette.glow.opacity(0.9), radius: 4, x: 0, y: 0)
                        .opacity(pulseVisible ? 0.94 : 0)
                        .offset(x: caretOffset, y: -1)
                        .animation(.linear(duration: 0.16), value: pulseVisible)
                }
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(ComposerGuessWidthPreferenceKey.self) { width in
            renderedGuessWidth = width
        }
    }
}

private struct ComposerGuessWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ThreadKeyboardButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(color: ThreadPalette.ink.opacity(isEnabled ? 0.06 : 0), radius: 4, x: 0, y: 1.5)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.972 : 1)
            .opacity(isEnabled ? 1 : 0.44)
            .animation(ThreadMotion.quickSpring, value: configuration.isPressed)
    }
}

private enum ThreadKeyboardKey: Hashable {
    case letter(String)
    case submit
    case delete

    var isAction: Bool {
        switch self {
        case .submit, .delete:
            return true
        case .letter:
            return false
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .letter(let letter):
            return letter
        case .submit:
            return "Enter"
        case .delete:
            return "Delete"
        }
    }
}
