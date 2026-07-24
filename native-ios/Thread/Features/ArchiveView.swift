import SwiftUI

private enum ThreadArchiveFilter: String, CaseIterable, Identifiable {
    case unplayed = "Unplayed"
    case finished = "Finished"
    case all = "All"

    var id: String { rawValue }
}

@MainActor
struct ArchivePaywallView: View {
    @ObservedObject var purchaseController: ThreadArchivePurchaseController
    let onClose: () -> Void
    let onUnlocked: () -> Void

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                leading: purchaseController.isProcessing
                    ? nil
                    : ThreadBarAction(systemName: "xmark", label: "Close", action: onClose)
            )

            ThreadWordmark(
                eyebrow: "Archive",
                subtitle: "Every past Thread, ready when you are."
            )

            VStack(spacing: 18) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(ThreadPalette.accent)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Catch up at your pace")
                        .font(ThreadFont.display(30, weight: .semibold))
                        .foregroundStyle(ThreadPalette.ink)
                        .multilineTextAlignment(.center)

                    Text("Unlock every past Daily Thread with one purchase.")
                        .font(ThreadFont.body(13, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        if purchaseController.product == nil {
                            await purchaseController.retryProductLoad()
                            return
                        }
                        if await purchaseController.purchase() {
                            onUnlocked()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if purchaseController.isLoading || purchaseController.isProcessing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(purchaseButtonTitle)
                    }
                }
                .threadButton(.primary)
                .disabled(purchaseController.isLoading || purchaseController.isProcessing)

                Button("Restore purchase") {
                    Task {
                        if await purchaseController.restore() {
                            onUnlocked()
                        }
                    }
                }
                .threadButton(.secondary)
                .disabled(purchaseController.isProcessing)

                if let message = purchaseController.message {
                    Text(message)
                        .font(ThreadFont.body(11.5, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("One-time purchase. No subscription.")
                    .font(ThreadFont.body(10.5, weight: .medium))
                    .foregroundStyle(ThreadPalette.faint)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .frame(maxWidth: 390)
        }
        .interactiveDismissDisabled(purchaseController.isProcessing)
    }

    private var purchaseButtonTitle: String {
        if let price = purchaseController.product?.displayPrice {
            return "Unlock Archive · \(price)"
        }
        return purchaseController.isLoading ? "Loading" : "Try again"
    }
}

struct ArchiveView: View {
    let items: [ThreadArchiveItem]
    let onBack: () -> Void
    let onSelect: (String) -> Void

    @State private var filter: ThreadArchiveFilter = .unplayed

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                leading: ThreadBarAction(systemName: "chevron.left", label: "Back", action: onBack)
            )

            ThreadWordmark(
                eyebrow: "Archive",
                subtitle: archiveSummary
            )

            Picker("Archive filter", selection: $filter) {
                ForEach(ThreadArchiveFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 390)

            if groupedItems.isEmpty {
                archiveEmptyState
            } else {
                LazyVStack(spacing: 22) {
                    ForEach(groupedItems, id: \.month) { group in
                        VStack(alignment: .leading, spacing: 9) {
                            Text(group.month)
                                .font(ThreadFont.body(11, weight: .semibold))
                                .tracking(2.2)
                                .textCase(.uppercase)
                                .foregroundStyle(ThreadPalette.faint)

                            VStack(spacing: 8) {
                                ForEach(group.items) { item in
                                    Button {
                                        onSelect(item.puzzle.dateKey)
                                    } label: {
                                        archiveRow(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 460)
            }
        }
    }

    private var archiveSummary: String {
        let waitingCount = items.filter { !$0.isFinished }.count
        let finishedCount = items.count - waitingCount

        if waitingCount == 0 {
            return "All \(finishedCount) past Threads finished"
        }
        return "\(waitingCount) waiting · \(finishedCount) finished"
    }

    private var filteredItems: [ThreadArchiveItem] {
        switch filter {
        case .unplayed:
            return items.filter { !$0.isFinished }
        case .finished:
            return items.filter(\.isFinished)
        case .all:
            return items
        }
    }

    private var groupedItems: [(month: String, items: [ThreadArchiveItem])] {
        var monthOrder: [String] = []
        var itemsByMonth: [String: [ThreadArchiveItem]] = [:]

        for item in filteredItems {
            let month = DateKeyFormatter.archiveMonthKey(item.puzzle.dateKey)
            if itemsByMonth[month] == nil {
                monthOrder.append(month)
            }
            itemsByMonth[month, default: []].append(item)
        }

        return monthOrder.map { month in
            (month: month, items: itemsByMonth[month] ?? [])
        }
    }

    @ViewBuilder
    private var archiveEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: filter == .unplayed ? "checkmark.circle" : "calendar")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(ThreadPalette.accent)

            Text(filter == .unplayed ? "You're caught up" : "Nothing here yet")
                .font(ThreadFont.display(28))
                .foregroundStyle(ThreadPalette.ink)

            Text(filter == .unplayed
                 ? "Every past Thread is finished."
                 : "Finished Threads will appear here.")
                .font(ThreadFont.body(13, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 34)
        .frame(maxWidth: 390)
    }

    private func archiveRow(_ item: ThreadArchiveItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Thread #\(item.puzzle.roundNumber)")
                    .font(ThreadFont.body(10.5, weight: .semibold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ThreadPalette.faint)

                Text(item.completedAnswer ?? DateKeyFormatter.formatForArchive(item.puzzle.dateKey))
                    .font(ThreadFont.display(21, weight: .semibold))
                    .tracking(item.completedAnswer == nil ? 0 : 1.2)
                    .foregroundStyle(ThreadPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if item.completedAnswer != nil {
                    Text(DateKeyFormatter.formatForArchive(item.puzzle.dateKey))
                        .font(ThreadFont.body(11, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                }
            }

            Spacer(minLength: 8)

            archiveStatus(item.status)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ThreadPalette.faint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ThreadPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ThreadPalette.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func archiveStatus(_ status: ThreadArchiveItemStatus) -> some View {
        let label: String
        let symbol: String
        let color: Color

        switch status {
        case .unplayed:
            label = "Play"
            symbol = "play.circle.fill"
            color = ThreadPalette.accent
        case .inProgress(let revealedClueCount):
            label = "Continue · \(revealedClueCount)/5"
            symbol = "arrow.right.circle.fill"
            color = ThreadPalette.accent
        case .finished(let score):
            if let score {
                label = "Solved in \(score)"
                symbol = "checkmark.circle.fill"
                color = ThreadPalette.accent
            } else {
                label = "Missed"
                symbol = "xmark.circle.fill"
                color = ThreadPalette.failure
            }
        }

        return Label(label, systemImage: symbol)
            .font(ThreadFont.body(10.5, weight: .semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct ArchiveResultView: View {
    let item: ThreadArchiveItem
    let onBack: () -> Void

    var body: some View {
        ThreadScreenContainer {
            ThreadTopBar(
                leading: ThreadBarAction(systemName: "chevron.left", label: "Back to Archive", action: onBack)
            )

            VStack(spacing: 14) {
                Text("Archived Thread #\(item.puzzle.roundNumber)")
                    .font(ThreadFont.body(10, weight: .semibold))
                    .tracking(2.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ThreadPalette.muted)

                Text(item.completedAnswer ?? item.puzzle.round.answer)
                    .font(ThreadFont.display(46, weight: .bold))
                    .tracking(4.5)
                    .foregroundStyle(resultColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(resultCopy)
                    .font(ThreadFont.body(13, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .multilineTextAlignment(.center)

                ThreadCard {
                    Text("The connections")
                        .font(ThreadFont.body(12, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(ThreadPalette.faint)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 8) {
                        ForEach(item.puzzle.round.clues) { clue in
                            HStack(alignment: .center, spacing: 12) {
                                Text(clue.word)
                                    .font(ThreadFont.display(17, weight: .medium))
                                    .tracking(1.6)
                                    .foregroundStyle(ThreadPalette.ink)
                                    .frame(minWidth: 96, maxWidth: 102, alignment: .leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.62)

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
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(ThreadPalette.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(ThreadPalette.border, lineWidth: 1)
                            )
                        }
                    }
                }
                .frame(maxWidth: 500)

                Button("Back to Archive", action: onBack)
                    .threadButton(.primary)
                    .frame(maxWidth: 260)
                    .padding(.top, 2)
            }
            .padding(.top, -8)
        }
    }

    private var resultScore: Int? {
        guard case .finished(let score) = item.status else { return nil }
        return score
    }

    private var resultCopy: String {
        guard let resultScore, let tier = ScoreTier(rawValue: resultScore) else {
            return "Missed on \(DateKeyFormatter.formatForArchive(item.puzzle.dateKey))"
        }
        return "\(tier.title) · \(resultScore) clue\(resultScore == 1 ? "" : "s") · \(DateKeyFormatter.formatForArchive(item.puzzle.dateKey))"
    }

    private var resultColor: Color {
        resultScore == nil ? ThreadPalette.failure : ThreadPalette.accent
    }
}
