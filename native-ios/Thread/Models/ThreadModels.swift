import Foundation

struct RoundClue: Codable, Hashable, Identifiable {
    let word: String
    let connection: String

    var id: String { "\(word)|\(connection)" }
}

struct ThreadRound: Codable, Hashable, Identifiable {
    let id: Int
    let sourcePool: String
    let answer: String
    let acceptedAnswers: [String]
    let clues: [RoundClue]

    var normalizedAcceptedAnswers: Set<String> {
        Set(acceptedAnswers.map(GuessNormalizer.normalize))
    }
}

struct GameSnapshot: Codable, Hashable {
    let roundID: Int
    let dateKey: String?
    var revealedClueCount: Int
    var guess: String
    var attempts: [String]
    var isSolved: Bool
    var isFailed: Bool
    var startedAt: Date? = nil
    var firstSubmittedGuessAt: Date? = nil
    var updatedAt: Date? = nil

    static func initial(roundID: Int, dateKey: String? = nil) -> GameSnapshot {
        GameSnapshot(
            roundID: roundID,
            dateKey: dateKey,
            revealedClueCount: 1,
            guess: "",
            attempts: [],
            isSolved: false,
            isFailed: false,
            startedAt: .now,
            firstSubmittedGuessAt: nil,
            updatedAt: .now
        )
    }
}

struct ThreadPreferences: Codable, Hashable {
    var analyticsEnabled: Bool
    var aggregateSharingEnabled: Bool
    var hapticsEnabled: Bool
    var dailyRemindersEnabled: Bool
    var updatedAt: Date?

    static let `default` = ThreadPreferences(
        analyticsEnabled: true,
        aggregateSharingEnabled: true,
        hapticsEnabled: true,
        dailyRemindersEnabled: false
    )

    private enum CodingKeys: String, CodingKey {
        case analyticsEnabled
        case aggregateSharingEnabled
        case hapticsEnabled
        case dailyRemindersEnabled
        case updatedAt
    }

    init(
        analyticsEnabled: Bool,
        aggregateSharingEnabled: Bool,
        hapticsEnabled: Bool,
        dailyRemindersEnabled: Bool = Self.default.dailyRemindersEnabled,
        updatedAt: Date? = nil
    ) {
        self.analyticsEnabled = analyticsEnabled
        self.aggregateSharingEnabled = aggregateSharingEnabled
        self.hapticsEnabled = hapticsEnabled
        self.dailyRemindersEnabled = dailyRemindersEnabled
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        analyticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .analyticsEnabled) ?? Self.default.analyticsEnabled
        aggregateSharingEnabled = try container.decodeIfPresent(Bool.self, forKey: .aggregateSharingEnabled) ?? Self.default.aggregateSharingEnabled
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? Self.default.hapticsEnabled
        dailyRemindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyRemindersEnabled) ?? Self.default.dailyRemindersEnabled
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(analyticsEnabled, forKey: .analyticsEnabled)
        try container.encode(aggregateSharingEnabled, forKey: .aggregateSharingEnabled)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(dailyRemindersEnabled, forKey: .dailyRemindersEnabled)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    func markedUpdated(at date: Date = .now) -> ThreadPreferences {
        var copy = self
        copy.updatedAt = date
        return copy
    }
}

struct ThreadNotificationPromptState: Codable, Hashable {
    var seenDateKeys: [String]
    var promptCount: Int
    var lastPromptAt: Date?

    static let `default` = ThreadNotificationPromptState(
        seenDateKeys: [],
        promptCount: 0,
        lastPromptAt: nil
    )

    private enum CodingKeys: String, CodingKey {
        case seenDateKeys
        case promptCount
        case lastPromptAt
    }

    init(
        seenDateKeys: [String],
        promptCount: Int,
        lastPromptAt: Date?
    ) {
        self.seenDateKeys = seenDateKeys
        self.promptCount = promptCount
        self.lastPromptAt = lastPromptAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seenDateKeys = try container.decodeIfPresent([String].self, forKey: .seenDateKeys) ?? []
        promptCount = try container.decodeIfPresent(Int.self, forKey: .promptCount) ?? 0
        lastPromptAt = try container.decodeIfPresent(Date.self, forKey: .lastPromptAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seenDateKeys, forKey: .seenDateKeys)
        try container.encode(promptCount, forKey: .promptCount)
        try container.encodeIfPresent(lastPromptAt, forKey: .lastPromptAt)
    }
}

enum ThreadFirstDailyNudgeStage: String, Codable, Hashable {
    case unseen
    case initial
    case followup
    case completed
}

enum ThreadStreakBadgeMilestone: Int, CaseIterable, Codable, Hashable, Identifiable {
    case day7 = 7
    case day14 = 14
    case day30 = 30
    case day50 = 50
    case day100 = 100
    case day200 = 200
    case day365 = 365

    var id: Int { rawValue }

    var days: Int { rawValue }

    var assetName: String {
        switch self {
        case .day7: return "StreakBadge7"
        case .day14: return "StreakBadge14"
        case .day30: return "StreakBadge30"
        case .day50: return "StreakBadge50"
        case .day100: return "StreakBadge100"
        case .day200: return "StreakBadge200"
        case .day365: return "StreakBadge365"
        }
    }

    var title: String {
        "\(days) day streak"
    }
}

struct ThreadStreakBadgeDisplay: Hashable, Identifiable {
    let milestone: ThreadStreakBadgeMilestone
    let isEarned: Bool

    var id: Int { milestone.id }
}

#if DEBUG
struct ThreadDebugBadgePreviewState: Codable, Hashable {
    var currentStreakOverride: Int?
    var bestStreakOverride: Int?
    var unlockPreviewMilestone: ThreadStreakBadgeMilestone?

    static let `default` = ThreadDebugBadgePreviewState(
        currentStreakOverride: nil,
        bestStreakOverride: nil,
        unlockPreviewMilestone: nil
    )

    var hasAnyOverride: Bool {
        currentStreakOverride != nil
            || bestStreakOverride != nil
            || unlockPreviewMilestone != nil
    }
}
#endif

enum ThreadStreakBadgeLogic {
    static func displayItems(bestStreak: Int) -> [ThreadStreakBadgeDisplay] {
        ThreadStreakBadgeMilestone.allCases.map { milestone in
            ThreadStreakBadgeDisplay(
                milestone: milestone,
                isEarned: bestStreak >= milestone.days
            )
        }
    }

    static func newlyUnlockedMilestone(
        projectedSolvedStreak: Int?,
        bestStreakBeforeToday: Int,
        shownMilestones: Set<ThreadStreakBadgeMilestone>
    ) -> ThreadStreakBadgeMilestone? {
        guard let projectedSolvedStreak,
              let milestone = ThreadStreakBadgeMilestone(rawValue: projectedSolvedStreak),
              bestStreakBeforeToday < milestone.days,
              !shownMilestones.contains(milestone) else {
            return nil
        }

        return milestone
    }
}

struct DailyHistoryEntry: Codable, Hashable, Identifiable {
    let dateKey: String
    let roundID: Int
    let answer: String
    let score: Int?
    let completedAt: Date
    let aggregateSubmittedAt: Date?

    var id: String { dateKey }

    func markingAggregateSubmitted(at date: Date) -> DailyHistoryEntry {
        DailyHistoryEntry(
            dateKey: dateKey,
            roundID: roundID,
            answer: answer,
            score: score,
            completedAt: completedAt,
            aggregateSubmittedAt: date
        )
    }
}

struct ThreadArchivePuzzle: Hashable, Identifiable {
    let dateKey: String
    let roundNumber: Int
    let round: ThreadRound

    var id: String { dateKey }
}

struct ThreadArchiveHistoryEntry: Codable, Hashable, Identifiable {
    let dateKey: String
    let roundID: Int
    let answer: String
    let score: Int?
    let completedAt: Date

    var id: String { dateKey }
}

enum ThreadArchiveItemStatus: Hashable {
    case unplayed
    case inProgress(revealedClueCount: Int)
    case finished(score: Int?)
}

struct ThreadArchiveItem: Hashable, Identifiable {
    let puzzle: ThreadArchivePuzzle
    let status: ThreadArchiveItemStatus
    let completedAnswer: String?

    var id: String { puzzle.id }

    var isFinished: Bool {
        if case .finished = status {
            return true
        }
        return false
    }
}

struct AggregateHistogramBucket: Hashable, Identifiable {
    let bucket: Int
    let count: Int

    var id: Int { bucket }
}

struct AggregateHistogram: Hashable {
    let roundID: Int
    let totalSubmissions: Int
    let buckets: [AggregateHistogramBucket]
}

struct ThreadStatsSummary: Hashable {
    let totalPlayed: Int
    let solvedCount: Int
    let missedCount: Int
    let solveRate: Int
    let averageClues: Double?
    let bestScore: Int?
    let currentStreak: Int
    let bestStreak: Int
    let scoreCounts: [Int: Int]
    let recent: [DailyHistoryEntry]
}

enum ScoreTier: Int, CaseIterable, Codable {
    case uncanny = 1
    case brilliant = 2
    case sharp = 3
    case solid = 4
    case gotThere = 5

    var title: String {
        switch self {
        case .uncanny: return "Uncanny"
        case .brilliant: return "Brilliant"
        case .sharp: return "Sharp"
        case .solid: return "Solid"
        case .gotThere: return "Got there"
        }
    }

    var emoji: String {
        switch self {
        case .uncanny: return "🧠"
        case .brilliant: return "🔥"
        case .sharp: return "⚡"
        case .solid: return "👏"
        case .gotThere: return "🤝"
        }
    }
}

enum GuessNormalizer {
    static func normalize(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .uppercased()
    }
}

enum ThreadGuessLengthPolicy {
    static let minimumCap = 12

    static func maxGuessLength(for round: ThreadRound) -> Int {
        let acceptedAnswerLengths = round.acceptedAnswers.map { GuessNormalizer.normalize($0).count }
        let clueWordLengths = round.clues.map { GuessNormalizer.normalize($0.word).count }
        let answerLength = GuessNormalizer.normalize(round.answer).count
        return max(minimumCap, ([answerLength] + acceptedAnswerLengths + clueWordLengths).max() ?? minimumCap)
    }
}
