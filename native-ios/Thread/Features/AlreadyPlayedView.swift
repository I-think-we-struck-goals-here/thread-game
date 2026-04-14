import SwiftUI

struct AlreadyPlayedView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let round: ThreadRound
    let roundNumber: Int
    let appShareURL: URL?
    let appShareLabel: String
    let entry: DailyHistoryEntry
    let nextUnlockDate: Date?
    let hapticsEnabled: Bool
    let onViewStats: () -> Void
    let onShare: () -> Void
    let onOpenSettings: () -> Void

    @State private var shareSheetPayload: ShareSheetPayload?

    var body: some View {
        GeometryReader { proxy in
            ThreadScreenContainer {
                VStack(spacing: 12) {
                    ThreadTopBar(
                        trailing: [
                            ThreadBarAction(systemName: "chart.bar.xaxis", label: "Stats", action: onViewStats),
                            ThreadBarAction(systemName: "gearshape", label: "Settings", action: onOpenSettings),
                        ]
                    )

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        compactResultsContent

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: availableContentHeight(for: proxy.size.height))
                }
            }
        }
        .sheet(item: $shareSheetPayload) { payload in
            ActivitySheet(items: payload.items)
        }
    }

    private var compactResultsContent: some View {
        VStack(spacing: 14) {
            Text("Puzzle #\(roundNumber)")
                .font(ThreadFont.body(10, weight: .semibold))
                .tracking(3.3)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.muted)

            VStack(spacing: 10) {
                Text(round.answer)
                    .font(ThreadFont.display(46, weight: .bold))
                    .tracking(5.5)
                    .foregroundStyle(entry.score == nil ? ThreadPalette.failure : ThreadPalette.accent)
                    .multilineTextAlignment(.center)

                Text(resultCopy)
                    .font(ThreadFont.body(12.5, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: contentWidth)

            VStack(spacing: 10) {
                Button("Share your result") {
                    ThreadHaptics.tap(enabled: hapticsEnabled)
                    onShare()
                    shareSheetPayload = ShareSheetPayload(
                        items: [ShareTextBuilder.resultText(roundNumber: roundNumber, score: entry.score)]
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

                Text("Come back tomorrow for a new thread")
                    .font(ThreadFont.body(11, weight: .medium))
                    .foregroundStyle(ThreadPalette.faint)
                    .padding(.top, 4)
            }
            .frame(maxWidth: contentWidth)
            .padding(.top, 2)
        }
        .padding(.top, -8)
    }

    private var resultCopy: String {
        guard let score = entry.score, let tier = ScoreTier(rawValue: score) else {
            return "Come back tomorrow for a new thread."
        }
        return "\(tier.title) - \(score) clue\(score == 1 ? "" : "s")"
    }

    private var contentWidth: CGFloat {
        horizontalSizeClass == .regular ? 500 : 380
    }

    private func availableContentHeight(for viewportHeight: CGFloat) -> CGFloat {
        let reservedChromeHeight: CGFloat = horizontalSizeClass == .regular ? 110 : 96
        return max(0, viewportHeight - reservedChromeHeight)
    }
}
