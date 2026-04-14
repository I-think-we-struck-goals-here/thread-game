import SwiftUI

struct PracticeSummaryView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let rounds: [ThreadRound]
    let scores: [Int?]
    let onContinue: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                trailing: [ThreadBarAction(systemName: "gearshape", label: "Settings", action: onOpenSettings)]
            )

            ThreadCard(alignment: .center) {
                Text("👏")
                    .font(.system(size: 50))

                Text("You've got the idea")
                    .font(ThreadFont.display(28))
                    .foregroundStyle(ThreadPalette.ink)
                    .multilineTextAlignment(.center)

                Text("Practice is done. Now try today's puzzle. This one counts.")
                    .font(ThreadFont.body(16, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill((scores[safe: index] ?? nil) == nil ? ThreadPalette.failureSoft : ThreadPalette.accentSoft)
                                    .frame(width: 42, height: 42)
                                Text(scoreBadge(at: index))
                                    .font(ThreadFont.body(15, weight: .bold))
                                    .foregroundStyle((scores[safe: index] ?? nil) == nil ? ThreadPalette.failure : ThreadPalette.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(round.answer)
                                    .font(ThreadFont.display(26, weight: .semibold))
                                    .tracking(2.4)
                                    .foregroundStyle(ThreadPalette.ink)

                                Text(scoreCaption(at: index))
                                    .font(ThreadFont.body(13, weight: .medium))
                                    .foregroundStyle(ThreadPalette.muted)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(16)
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
            .frame(maxWidth: horizontalSizeClass == .regular ? 460 : 360)

            VStack(spacing: 12) {
                Button("Play today's thread", action: onContinue)
                    .threadButton(.primary)
            }
        }
    }

    private func scoreBadge(at index: Int) -> String {
        if let score = scores[safe: index], let score {
            return "\(score)"
        }
        return "×"
    }

    private func scoreCaption(at index: Int) -> String {
        guard let score = scores[safe: index], let score, let tier = ScoreTier(rawValue: score) else {
            return "Missed"
        }

        return "\(tier.title) - \(score) clue\(score == 1 ? "" : "s")"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
