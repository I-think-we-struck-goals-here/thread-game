import Charts
import SwiftUI
import UIKit

struct ThreadBackground: View {
    var body: some View {
        ThreadPalette.background
            .ignoresSafeArea()
    }
}

struct ThreadScreenContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ThreadBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    content
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? ThreadMetrics.wideContentWidth : ThreadMetrics.maxContentWidth)
                .padding(.horizontal, horizontalSizeClass == .regular ? 28 : 20)
                .padding(.top, horizontalSizeClass == .regular ? 14 : 6)
                .padding(.bottom, horizontalSizeClass == .regular ? 40 : 28)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ThreadCard<Content: View>: View {
    private let alignment: HorizontalAlignment
    private let content: Content

    init(alignment: HorizontalAlignment = .leading, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ThreadMetrics.cardCornerRadius, style: .continuous)
                .fill(ThreadPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThreadMetrics.cardCornerRadius, style: .continuous)
                .stroke(ThreadPalette.border, lineWidth: 1)
        )
    }
}

struct ThreadMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.976, green: 0.965, blue: 0.941), Color(red: 0.925, green: 0.894, blue: 0.847)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(ThreadPalette.ink, lineWidth: size * 0.04)
                )
                .frame(width: size, height: size)

            Path { path in
                let inset = size * 0.2
                let stemWidth = size * 0.16
                let topWidth = size * 0.54
                let topHeight = size * 0.13
                path.addRoundedRect(
                    in: CGRect(x: inset, y: inset, width: topWidth, height: topHeight),
                    cornerSize: CGSize(width: topHeight / 2, height: topHeight / 2)
                )
                path.addRoundedRect(
                    in: CGRect(x: inset + (topWidth - stemWidth) / 2, y: inset + topHeight, width: stemWidth, height: size * 0.42),
                    cornerSize: CGSize(width: stemWidth / 2, height: stemWidth / 2)
                )
            }
            .fill(ThreadPalette.ink)
            .frame(width: size, height: size)

            Circle()
                .fill(ThreadPalette.accent)
                .frame(width: size * 0.17, height: size * 0.17)
                .offset(x: size * 0.06, y: -size * 0.06)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ThreadWordmark: View {
    var eyebrow: String? = "Daily Word Puzzle"
    var subtitle: String? = nil
    var showsMark: Bool = false

    var body: some View {
        VStack(spacing: showsMark ? 12 : 6) {
            if showsMark {
                ThreadMark(size: 72)
            }

            if let eyebrow {
                Text(eyebrow)
                    .font(ThreadFont.body(9.5, weight: .semibold))
                    .tracking(3.3)
                    .foregroundStyle(ThreadPalette.muted)
                    .textCase(.uppercase)
            }

            Text("Thread")
                .font(ThreadFont.display(34, weight: .semibold))
                .tracking(5.2)
                .foregroundStyle(ThreadPalette.ink)
                .textCase(.uppercase)

            if let subtitle {
                Text(subtitle)
                    .font(ThreadFont.body(11.5, weight: .medium))
                    .foregroundStyle(ThreadPalette.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum ThreadButtonVariant {
    case primary
    case accent
    case secondary
}

struct ThreadButtonStyle: ButtonStyle {
    let variant: ThreadButtonVariant
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThreadFont.body(12, weight: .semibold))
            .tracking(1.15)
            .textCase(.uppercase)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 9.5)
            .frame(maxWidth: .infinity)
            .background(background(configuration: configuration))
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
            )
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return isEnabled ? .white : .white.opacity(0.9)
        case .accent:
            return isEnabled ? .white : .white.opacity(0.9)
        case .secondary:
            return isEnabled ? ThreadPalette.muted : ThreadPalette.faint
        }
    }

    private var borderColor: Color {
        variant == .secondary ? (isEnabled ? ThreadPalette.border : ThreadPalette.border.opacity(0.65)) : .clear
    }

    private func background(configuration: Configuration) -> some ShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(ThreadPalette.ink.opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1) : 0.7))
        case .accent:
            return AnyShapeStyle(ThreadPalette.accent.opacity(isEnabled ? (configuration.isPressed ? 0.92 : 1) : 0.72))
        case .secondary:
            return AnyShapeStyle(ThreadPalette.surface)
        }
    }
}

extension View {
    func threadButton(_ variant: ThreadButtonVariant = .primary) -> some View {
        buttonStyle(ThreadButtonStyle(variant: variant))
    }
}

struct ThreadDailyRevealView: View {
    let roundNumber: Int

    var body: some View {
        ZStack {
            ThreadBackground()

            VStack(spacing: 14) {
                Image("ThreadLaunchIcon")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 132, height: 132)

                Text("Thread #\(roundNumber)")
                    .font(ThreadFont.body(12, weight: .semibold))
                    .tracking(3.6)
                    .foregroundStyle(ThreadPalette.muted)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}

struct ThreadAdaptiveSplit<Primary: View, Secondary: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat
    private let primary: Primary
    private let secondary: Secondary

    init(
        spacing: CGFloat = ThreadMetrics.splitSpacing,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.spacing = spacing
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: spacing) {
                primary
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                secondary
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        } else {
            VStack(spacing: spacing) {
                primary
                secondary
            }
        }
    }
}

struct ThreadBarAction: Identifiable {
    let id = UUID()
    let systemName: String
    let label: String
    let action: () -> Void
}

struct ThreadTopBar: View {
    let leading: ThreadBarAction?
    let trailing: [ThreadBarAction]

    init(leading: ThreadBarAction? = nil, trailing: [ThreadBarAction] = []) {
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            if let leading {
                ThreadIconButton(action: leading)
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }

            Spacer(minLength: 0)

            ForEach(trailing) { action in
                ThreadIconButton(action: action)
            }
        }
    }
}

struct ThreadIconButton: View {
    let action: ThreadBarAction

    var body: some View {
        Button(action: action.action) {
            Image(systemName: action.systemName)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(ThreadPalette.ink)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(ThreadPalette.surface)
                )
                .overlay(
                    Circle()
                        .stroke(ThreadPalette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.label)
    }
}

struct ProgressDotsView: View {
    let total: Int
    let activeCount: Int
    var color: Color = ThreadPalette.ink

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < activeCount ? color : ThreadPalette.border)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clues revealed")
        .accessibilityValue("\(activeCount) of \(total)")
    }
}

struct ScoreRowView: View {
    let score: Int?

    var body: some View {
        Text(ShareTextBuilder.emojiRow(score: score))
            .font(.system(size: 28))
            .tracking(4)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(scoreDescription)
    }

    private var scoreDescription: String {
        if let score {
            return "\(score) out of 5 clues"
        }
        return "Missed today's thread"
    }
}

struct ScoreDotsMeterView: View {
    let score: Int?
    var total: Int = 5
    var dotSize: CGFloat = 10
    var spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(fill(for: index))
                    .frame(width: dotSize, height: dotSize)
                    .overlay(
                        Circle()
                            .stroke(ThreadPalette.border.opacity(index < (score ?? 0) || score == nil ? 0 : 1), lineWidth: 1)
                    )
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score == nil ? "Missed today's thread" : "\(score ?? 0) out of \(total) clues")
    }

    private func fill(for index: Int) -> Color {
        guard let score else {
            return ThreadPalette.ink
        }
        return index < score ? ThreadPalette.accent : Color.white
    }
}

struct ThreadInlineLinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ThreadFont.body(11.5, weight: .medium))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.faint)
        }
        .buttonStyle(.plain)
    }
}

struct MetricTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 7) {
            Text(label)
                .font(ThreadFont.body(11, weight: .semibold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.faint)
            Text(value)
                .font(ThreadFont.display(23, weight: .semibold))
                .foregroundStyle(ThreadPalette.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ThreadPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ThreadPalette.border, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

struct GlobalDistributionCard: View {
    let histogram: AggregateHistogram?
    let userScore: Int?
    let isLoading: Bool
    let isEnabled: Bool

    var body: some View {
        ThreadCard {
            Text("Global distribution")
                .font(ThreadFont.body(12, weight: .semibold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.faint)

            if !isEnabled {
                placeholder(
                    title: "Anonymous compare is off",
                    body: "Enable anonymous score sharing in Settings when you want to compare your result with the wider Thread player base."
                )
            } else if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(ThreadPalette.ink)
                    Text("Checking the latest anonymous distribution…")
                        .font(ThreadFont.body(15, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if let histogram, histogram.totalSubmissions > 0 {
                VStack(alignment: .leading, spacing: 14) {
                    Text("\(histogram.totalSubmissions) anonymous result\(histogram.totalSubmissions == 1 ? "" : "s")")
                        .font(ThreadFont.body(16, weight: .semibold))
                        .foregroundStyle(ThreadPalette.ink)

                    Chart(resolvedBuckets) { bucket in
                        BarMark(
                            x: .value("Bucket", bucketLabel(bucket.bucket)),
                            y: .value("Count", bucket.count)
                        )
                        .foregroundStyle(bucket.bucket == (userScore ?? 0) ? highlightedColor(for: bucket.bucket) : ThreadPalette.border)
                        .cornerRadius(8)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .accessibilityLabel("Global distribution chart")
                    .accessibilityValue(histogramAccessibilitySummary)

                    Text(userScoreCopy)
                        .font(ThreadFont.body(13, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                }
            } else {
                placeholder(
                    title: "Global chart coming next",
                    body: "The app is fully local today. This space is ready for the anonymous score histogram once the lightweight sync service is live."
                )
            }
        }
    }

    private var resolvedBuckets: [AggregateHistogramBucket] {
        let source = Dictionary(uniqueKeysWithValues: (histogram?.buckets ?? []).map { ($0.bucket, $0.count) })
        return [1, 2, 3, 4, 5, 0].map { AggregateHistogramBucket(bucket: $0, count: source[$0, default: 0]) }
    }

    private func bucketLabel(_ bucket: Int) -> String {
        bucket == 0 ? "Missed" : "\(bucket)"
    }

    private func highlightedColor(for bucket: Int) -> Color {
        if bucket == 0 {
            return ThreadPalette.failure
        }
        return ThreadPalette.accent
    }

    private var userScoreCopy: String {
        guard let userScore else {
            return "Your current result sits in the missed bucket."
        }
        return "Your current result sits in the \(userScore)-clue bucket."
    }

    private var histogramAccessibilitySummary: String {
        resolvedBuckets
            .map { bucket in
                "\(bucketLabel(bucket.bucket)): \(bucket.count)"
            }
            .joined(separator: ", ")
    }

    @ViewBuilder
    private func placeholder(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(ThreadFont.display(26))
                .foregroundStyle(ThreadPalette.ink)

            Text(body)
                .font(ThreadFont.body(15, weight: .medium))
                .foregroundStyle(ThreadPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct NextThreadCountdownCard: View {
    let unlockDate: Date?

    var body: some View {
        ThreadCard(alignment: .center) {
            Text("Next thread")
                .font(ThreadFont.body(12, weight: .semibold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(ThreadPalette.faint)

            if let unlockDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = max(0, unlockDate.timeIntervalSince(context.date))

                    VStack(spacing: 10) {
                        Text(timeString(for: remaining))
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(ThreadPalette.ink)

                        Text(remaining > 0 ? "Unlocks at midnight local time." : "Loading the new daily thread…")
                            .font(ThreadFont.body(14, weight: .medium))
                            .foregroundStyle(ThreadPalette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Next thread unlock")
                    .accessibilityValue(accessibilityCountdownText(for: remaining))
                }
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(ThreadPalette.ink)

                    Text("Preparing the next daily reset…")
                        .font(ThreadFont.body(14, weight: .medium))
                        .foregroundStyle(ThreadPalette.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func timeString(for interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func accessibilityCountdownText(for interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if totalSeconds == 0 {
            return "Loading the new daily thread."
        }

        return "\(hours) hours, \(minutes) minutes, \(seconds) seconds remaining. Unlocks at midnight local time."
    }
}

struct NextThreadInlineStatus: View {
    let unlockDate: Date?
    let preface: String

    var body: some View {
        if let unlockDate {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = max(0, unlockDate.timeIntervalSince(context.date))
                Text(remaining > 0 ? "\(preface) \(timeString(for: remaining))" : "Loading the new daily thread…")
                    .font(ThreadFont.body(11.5, weight: .medium))
                    .foregroundStyle(ThreadPalette.faint)
                    .multilineTextAlignment(.center)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Next thread")
                    .accessibilityValue(remaining > 0 ? "\(timeString(for: remaining)) remaining" : "Loading the new daily thread")
            }
        } else {
            Text("Preparing the next daily reset…")
                .font(ThreadFont.body(11.5, weight: .medium))
                .foregroundStyle(ThreadPalette.faint)
                .multilineTextAlignment(.center)
        }
    }

    private func timeString(for interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

@MainActor
enum ThreadHaptics {
    static func selection(enabled: Bool) {
        guard enabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func tap(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning(enabled: Bool) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareSheetPayload: Identifiable {
    let id = UUID()
    let items: [Any]
}
