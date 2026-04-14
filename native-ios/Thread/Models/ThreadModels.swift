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
        dailyRemindersEnabled: Bool = true,
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
