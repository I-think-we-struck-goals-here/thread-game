import SwiftUI

struct StatsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let history: [DailyHistoryEntry]
    let todayKey: String
    let onBack: () -> Void
    let onOpenSettings: () -> Void

    private var stats: ThreadStatsSummary {
        ThreadStatisticsBuilder.build(history: history, todayKey: todayKey)
    }

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                leading: ThreadBarAction(systemName: "chevron.left", label: "Back", action: onBack),
                trailing: [ThreadBarAction(systemName: "gearshape", label: "Settings", action: onOpenSettings)]
            )

            ThreadWordmark(subtitle: nil)

            if history.isEmpty {
                ThreadCard(alignment: .center) {
                    Text("📊")
                        .font(.system(size: 48))

                    Text("No games saved yet")
                        .font(ThreadFont.display(32))
                        .foregroundStyle(ThreadPalette.ink)

                    Text("Finish a daily thread and your record will appear here automatically on this device.")
                        .font(ThreadFont.body(16, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .multilineTextAlignment(.center)

                    Button("Back", action: onBack)
                        .threadButton(.primary)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 460 : 360)
            } else {
                VStack(spacing: 14) {
                    LazyVGrid(columns: metricColumns, spacing: 8) {
                        MetricTile(label: "Played", value: "\(stats.totalPlayed)")
                        MetricTile(label: "Solved", value: "\(stats.solveRate)%")
                        MetricTile(label: "Average", value: averageDisplay)
                        MetricTile(label: "Best", value: bestDisplay)
                        MetricTile(label: "Current streak", value: "\(stats.currentStreak)")
                        MetricTile(label: "Best streak", value: "\(stats.bestStreak)")
                    }

                    ThreadCard {
                        Text("Score distribution")
                            .font(ThreadFont.body(12, weight: .semibold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundStyle(ThreadPalette.faint)

                        VStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { score in
                                distributionRow(
                                    label: "\(score) clue",
                                    count: stats.scoreCounts[score, default: 0],
                                    fill: ThreadPalette.accent
                                )
                            }

                            distributionRow(
                                label: "Missed",
                                count: stats.missedCount,
                                fill: ThreadPalette.failure
                            )
                        }
                    }
                    ThreadCard {
                        Text("Recent threads")
                            .font(ThreadFont.body(12, weight: .semibold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundStyle(ThreadPalette.faint)

                        VStack(spacing: 7) {
                            ForEach(stats.recent) { entry in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(DateKeyFormatter.formatForDisplay(entry.dateKey))
                                            .font(ThreadFont.body(11, weight: .semibold))
                                            .tracking(1.6)
                                            .textCase(.uppercase)
                                            .foregroundStyle(ThreadPalette.faint)

                                        Text(entry.answer)
                                            .font(ThreadFont.display(18, weight: .semibold))
                                            .tracking(1.4)
                                            .foregroundStyle(ThreadPalette.ink)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.7)
                                    }

                                    Spacer(minLength: 0)

                                    VStack(alignment: .trailing, spacing: 6) {
                                        ScoreRowView(score: entry.score)
                                        Text(entryCaption(for: entry.score))
                                            .font(ThreadFont.body(12, weight: .medium))
                                            .foregroundStyle(ThreadPalette.muted)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(ThreadPalette.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(ThreadPalette.border, lineWidth: 1)
                                )
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(recentEntryAccessibilityLabel(entry))
                            }
                        }
                    }

                    Button("Back", action: onBack)
                        .threadButton(.primary)
                        .frame(maxWidth: 220)
                        .padding(.top, 4)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 560 : 390)
            }
        }
    }

    private var averageDisplay: String {
        guard let average = stats.averageClues else { return "—" }
        return average.formatted(.number.precision(.fractionLength(0...2)))
    }

    private var metricColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var bestDisplay: String {
        guard let best = stats.bestScore else { return "—" }
        return "\(best) clues"
    }

    private var maxBarCount: Int {
        max(1, stats.missedCount, stats.scoreCounts.values.max() ?? 0)
    }

    private func entryCaption(for score: Int?) -> String {
        guard let score, let tier = ScoreTier(rawValue: score) else {
            return "Missed"
        }
        return "\(tier.title) (\(score))"
    }

    @ViewBuilder
    private func distributionRow(label: String, count: Int, fill: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(ThreadFont.body(12, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .lineLimit(1)
                .frame(width: 58, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(ThreadPalette.border)

                    Capsule(style: .continuous)
                        .fill(fill)
                        .frame(width: count == 0 ? 0 : max(6, geometry.size.width * CGFloat(count) / CGFloat(maxBarCount)))
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(ThreadFont.body(12, weight: .medium))
                .foregroundStyle(ThreadPalette.ink)
                .frame(width: 26, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(count)")
    }

    private func recentEntryAccessibilityLabel(_ entry: DailyHistoryEntry) -> String {
        "\(DateKeyFormatter.formatForDisplay(entry.dateKey)). \(entry.answer). \(entryCaption(for: entry.score))."
    }
}
