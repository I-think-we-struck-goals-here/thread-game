import SwiftUI

struct ResultsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let round: ThreadRound
    let roundNumber: Int
    let appShareURL: URL?
    let appShareLabel: String
    let score: Int?
    let nextUnlockDate: Date?
    let hapticsEnabled: Bool
    let onViewStats: () -> Void
    let onShare: () -> Void
    let onOpenSettings: () -> Void

    @State private var shareSheetPayload: ShareSheetPayload?

    var body: some View {
        ThreadScreenContainer {
            VStack(spacing: 12) {
                ThreadTopBar(
                    trailing: [
                        ThreadBarAction(systemName: "chart.bar.xaxis", label: "Stats", action: onViewStats),
                        ThreadBarAction(systemName: "gearshape", label: "Settings", action: onOpenSettings),
                    ]
                )

                VStack(spacing: 14) {
                    Text("Puzzle #\(roundNumber)")
                        .font(ThreadFont.body(10, weight: .semibold))
                        .tracking(3.3)
                        .textCase(.uppercase)
                        .foregroundStyle(ThreadPalette.muted)

                    VStack(spacing: 10) {
                        Text(round.answer)
                            .font(ThreadFont.display(48, weight: .bold))
                            .tracking(5.5)
                            .foregroundStyle(score == nil ? ThreadPalette.failure : ThreadPalette.accent)
                            .multilineTextAlignment(.center)

                        Text(resultCopy)
                            .font(ThreadFont.body(13, weight: .medium))
                            .foregroundStyle(ThreadPalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: contentWidth)

                    ThreadCard {
                        Text("The connections")
                            .font(ThreadFont.body(12, weight: .semibold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(ThreadPalette.faint)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(spacing: 8) {
                            ForEach(round.clues) { clue in
                                HStack(alignment: .center, spacing: 12) {
                                    Text(clue.word)
                                        .font(ThreadFont.display(17, weight: .medium))
                                        .tracking(1.6)
                                        .foregroundStyle(ThreadPalette.ink)
                                        .frame(minWidth: 96, maxWidth: 102, alignment: .leading)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.62)
                                        .layoutPriority(1)

                                    Text(clue.connection)
                                        .font(ThreadFont.body(11.5, weight: .medium))
                                        .italic()
                                        .foregroundStyle(ThreadPalette.muted)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(ThreadPalette.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(ThreadPalette.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: contentWidth)

                    VStack(spacing: 10) {
                        Button("Share your result") {
                            ThreadHaptics.tap(enabled: hapticsEnabled)
                            onShare()
                            shareSheetPayload = ShareSheetPayload(
                                items: [ShareTextBuilder.resultText(roundNumber: roundNumber, score: score)]
                            )
                        }
                        .threadButton(.accent)
                        .frame(maxWidth: 260)

                        if let appShareURL {
                            Button(appShareLabel) {
                                ThreadHaptics.tap(enabled: hapticsEnabled)
                                shareSheetPayload = ShareSheetPayload(items: [appShareURL])
                            }
                            .threadButton(.secondary)
                            .frame(maxWidth: 260)
                        }

                        Button("YOUR STATS", action: onViewStats)
                            .threadButton(.secondary)
                            .frame(maxWidth: 260)

                        Text("New thread at midnight")
                            .font(ThreadFont.body(11, weight: .medium))
                            .foregroundStyle(ThreadPalette.faint)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: contentWidth)
                    .padding(.top, 2)
                }
                .padding(.top, -8)
            }
        }
        .sheet(item: $shareSheetPayload) { payload in
            ActivitySheet(items: payload.items)
        }
    }

    private var resultCopy: String {
        guard let score, let tier = ScoreTier(rawValue: score) else {
            return "You'll get the next one."
        }
        return "\(tier.title) - \(score) clue\(score == 1 ? "" : "s")"
    }

    private var contentWidth: CGFloat {
        horizontalSizeClass == .regular ? 500 : 380
    }
}
