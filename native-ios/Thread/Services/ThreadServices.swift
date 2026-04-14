import Foundation
import OSLog

protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

struct AnalyticsEvent: Hashable, Sendable {
    let name: String
    let properties: [String: String]

    init(_ name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }

    static func bootstrapped(
        defaultScreen: String,
        tutorialCompleted: Bool,
        remindersEnabled: Bool,
        aggregateSharingEnabled: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            "app_bootstrapped",
            properties: [
                "default_screen": defaultScreen,
                "tutorial_completed": analyticsBool(tutorialCompleted),
                "daily_reminders_enabled": analyticsBool(remindersEnabled),
                "aggregate_sharing_enabled": analyticsBool(aggregateSharingEnabled),
            ]
        )
    }

    static func appSessionStarted(screenName: String) -> AnalyticsEvent {
        AnalyticsEvent(
            "app_session_started",
            properties: ["screen_name": screenName]
        )
    }

    static func appSessionEnded(durationSeconds: Int, lastScreenName: String) -> AnalyticsEvent {
        AnalyticsEvent(
            "app_session_ended",
            properties: [
                "session_duration_seconds": "\(durationSeconds)",
                "screen_name": lastScreenName,
            ]
        )
    }

    static func tutorialStarted(roundCount: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            "tutorial_started",
            properties: ["practice_round_count": "\(roundCount)"]
        )
    }

    static func tutorialSkipped() -> AnalyticsEvent {
        AnalyticsEvent("tutorial_skipped")
    }

    static func tutorialCompleted(totalRounds: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            "tutorial_completed",
            properties: ["practice_round_count": "\(totalRounds)"]
        )
    }

    static func roundStarted(
        mode: String,
        roundID: Int,
        roundNumber: Int? = nil,
        dateKey: String? = nil,
        practiceIndex: Int? = nil,
        resumedSavedProgress: Bool = false,
        currentStreak: Int? = nil
    ) -> AnalyticsEvent {
        var properties: [String: String] = [
            "mode": mode,
            "round_id": "\(roundID)",
            "resumed_saved_progress": analyticsBool(resumedSavedProgress),
        ]
        if let roundNumber {
            properties["round_number"] = "\(roundNumber)"
        }
        if let dateKey {
            properties["date_key"] = dateKey
        }
        if let practiceIndex {
            properties["practice_index"] = "\(practiceIndex)"
        }
        if let currentStreak {
            properties["current_streak_bucket"] = streakBucket(currentStreak)
            properties["current_streak_count"] = "\(currentStreak)"
        }
        return AnalyticsEvent("round_started", properties: properties)
    }

    static func roundFinished(
        mode: String,
        result: String,
        roundID: Int,
        roundNumber: Int? = nil,
        dateKey: String? = nil,
        practiceIndex: Int? = nil,
        currentStreak: Int? = nil,
        completion: ThreadRoundCompletion
    ) -> AnalyticsEvent {
        var properties: [String: String] = [
            "mode": mode,
            "result": result,
            "round_id": "\(roundID)",
            "clues_used": "\(completion.cluesUsed)",
            "wrong_guess_count": "\(completion.wrongGuessCount)",
            "total_guess_count": "\(completion.totalGuessCount)",
            "solve_duration_seconds": "\(completion.solveDurationSeconds)",
            "resumed_saved_progress": analyticsBool(completion.resumedSavedProgress),
        ]
        if let roundNumber {
            properties["round_number"] = "\(roundNumber)"
        }
        if let dateKey {
            properties["date_key"] = dateKey
        }
        if let practiceIndex {
            properties["practice_index"] = "\(practiceIndex)"
        }
        if let currentStreak {
            properties["current_streak_bucket"] = streakBucket(currentStreak)
            properties["current_streak_count"] = "\(currentStreak)"
        }
        if let score = completion.score {
            properties["score"] = "\(score)"
        }
        if let timeToFirstGuessSeconds = completion.timeToFirstGuessSeconds {
            properties["time_to_first_guess_seconds"] = "\(timeToFirstGuessSeconds)"
        }
        return AnalyticsEvent("round_finished", properties: properties)
    }

    static func statsOpened() -> AnalyticsEvent {
        AnalyticsEvent("stats_opened")
    }

    static func settingsOpened() -> AnalyticsEvent {
        AnalyticsEvent("settings_opened")
    }

    static func supportOpened() -> AnalyticsEvent {
        AnalyticsEvent("support_opened")
    }

    static func privacyOpened() -> AnalyticsEvent {
        AnalyticsEvent("privacy_opened")
    }

    static func preferenceChanged(key: String, enabled: Bool) -> AnalyticsEvent {
        AnalyticsEvent(
            "preference_changed",
            properties: [
                "preference_key": key,
                "enabled": analyticsBool(enabled),
            ]
        )
    }

    static func resultShared(
        roundID: Int,
        roundNumber: Int,
        dateKey: String,
        score: Int?
    ) -> AnalyticsEvent {
        var properties: [String: String] = [
            "mode": "daily",
            "round_id": "\(roundID)",
            "round_number": "\(roundNumber)",
            "date_key": dateKey,
        ]
        if let score {
            properties["score"] = "\(score)"
        }
        return AnalyticsEvent("result_shared", properties: properties)
    }

    static func notificationPromptShown(kind: String, promptCount: Int) -> AnalyticsEvent {
        AnalyticsEvent(
            "notification_prompt_shown",
            properties: [
                "prompt_kind": kind,
                "prompt_count": "\(promptCount)",
            ]
        )
    }

    static func notificationPermissionResult(status: ThreadNotificationAuthorizationStatus) -> AnalyticsEvent {
        AnalyticsEvent(
            "notification_permission_result",
            properties: ["authorization_status": status.rawValue]
        )
    }

    static func notificationSettingsOpened() -> AnalyticsEvent {
        AnalyticsEvent("notification_settings_opened")
    }
}

struct ThreadRoundCompletion: Hashable, Sendable {
    let score: Int?
    let cluesUsed: Int
    let wrongGuessCount: Int
    let totalGuessCount: Int
    let solveDurationSeconds: Int
    let timeToFirstGuessSeconds: Int?
    let resumedSavedProgress: Bool
}

private func analyticsBool(_ value: Bool) -> String {
    value ? "true" : "false"
}

private func streakBucket(_ streak: Int) -> String {
    switch streak {
    case ..<1:
        return "0"
    case 1:
        return "1"
    case 2...3:
        return "2-3"
    case 4...6:
        return "4-6"
    case 7...13:
        return "7-13"
    default:
        return "14+"
    }
}

struct NoopAnalyticsClient: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
}

struct LocalAnalyticsClient: AnalyticsTracking {
    private let logger = Logger(subsystem: "co.dailythread.threadapp", category: "analytics")

    func track(_ event: AnalyticsEvent) {
        logger.log("event=\(event.name, privacy: .public) properties=\(event.properties.description, privacy: .public)")
    }
}

protocol AggregateStatsProviding: Sendable {
    func submitDailyResult(
        installationID: String,
        roundID: Int,
        dateKey: String,
        score: Int?
    ) async -> Bool

    func fetchHistogram(roundID: Int) async -> AggregateHistogram?
}

actor NoopAggregateStatsClient: AggregateStatsProviding {
    func submitDailyResult(
        installationID: String,
        roundID: Int,
        dateKey: String,
        score: Int?
    ) async -> Bool {
        false
    }

    func fetchHistogram(roundID: Int) async -> AggregateHistogram? {
        nil
    }
}

struct ThreadExternalLinks: Hashable, Sendable {
    let supportURL: URL?
    let supportEmailAddress: String?
    let privacyPolicyURL: URL?
    let appStoreURL: URL?

    static func fromBundle(_ bundle: Bundle = .main) -> ThreadExternalLinks {
        let supportURL = (bundle.object(forInfoDictionaryKey: "ThreadSupportURL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .flatMap(URL.init(string:))
        let rawSupportEmail = bundle.object(forInfoDictionaryKey: "ThreadSupportEmail") as? String
        let supportEmailAddress = rawSupportEmail?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let privacyPolicyURL = (bundle.object(forInfoDictionaryKey: "ThreadPrivacyPolicyURL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .flatMap(URL.init(string:))
        let appStoreURL = (bundle.object(forInfoDictionaryKey: "ThreadAppStoreURL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
            .flatMap(URL.init(string:))

        return ThreadExternalLinks(
            supportURL: supportURL,
            supportEmailAddress: supportEmailAddress,
            privacyPolicyURL: privacyPolicyURL,
            appStoreURL: appStoreURL
        )
    }

    var supportEmailURL: URL? {
        guard let supportEmailAddress else { return nil }
        return URL(string: "mailto:\(supportEmailAddress)")
    }

    var hasAnyLink: Bool {
        supportURL != nil || supportEmailURL != nil || privacyPolicyURL != nil
    }

    var websiteURL: URL? {
        if let supportURL, var components = URLComponents(url: supportURL, resolvingAgainstBaseURL: false) {
            components.path = ""
            components.query = nil
            components.fragment = nil
            return components.url
        }
        return URL(string: "https://daily-thread.co/")
    }

    var shareAppURL: URL? {
        appStoreURL ?? websiteURL
    }

    var shareAppLinkTitle: String {
        appStoreURL == nil ? "Share website link" : "Share app link"
    }
}

enum ThreadLaunchConfiguration {
    static func shouldResetProgressOnLaunch(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        if processInfo.arguments.contains("-ThreadKeepSavedDataOnLaunch") {
            return false
        }

        if processInfo.arguments.contains("-ThreadResetProgressOnLaunch") {
            return true
        }

        if let boolValue = bundle.object(forInfoDictionaryKey: "ThreadResetProgressOnLaunch") as? Bool {
            return boolValue
        }

        if let rawValue = bundle.object(forInfoDictionaryKey: "ThreadResetProgressOnLaunch") as? String {
            switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "yes", "true", "1":
                return true
            default:
                return false
            }
        }

        return false
    }
}

struct DailyScheduler {
    let rounds: [ThreadRound]
    let timeZone: TimeZone
    let calendar: Calendar
    let anchorDate: Date
    let roundSelectionAnchorDate: Date
    private let scheduledRounds: [ThreadRound]
    private let usesFutureSchedule: Bool

    init(
        rounds: [ThreadRound],
        timeZoneID: String = "Europe/London",
        anchorComponents: DateComponents = DateComponents(year: 2026, month: 2, day: 16),
        roundSelectionAnchorComponents: DateComponents = DateComponents(year: 2026, month: 3, day: 31),
        futureShuffleSeed: UInt64 = 20_260_331
    ) {
        self.rounds = rounds
        self.timeZone = TimeZone(identifier: timeZoneID) ?? .gmt

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = self.timeZone
        self.calendar = calendar
        self.anchorDate = calendar.date(from: anchorComponents) ?? .now
        self.roundSelectionAnchorDate = calendar.date(from: roundSelectionAnchorComponents) ?? .now

        let futureRounds = rounds.filter { $0.sourcePool == "futureDaily" }
        if futureRounds.isEmpty {
            self.scheduledRounds = rounds
            self.usesFutureSchedule = false
        } else {
            self.scheduledRounds = Self.seededShuffle(futureRounds, seed: futureShuffleSeed)
            self.usesFutureSchedule = true
        }
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func dayNumber(now: Date = .now) -> Int {
        guard !rounds.isEmpty else { return 1 }
        let anchor = startOfDay(for: anchorDate)
        let today = startOfDay(for: now)
        let diff = calendar.dateComponents([.day], from: anchor, to: today).day ?? 0
        return max(1, diff + 1)
    }

    func roundForToday(now: Date = .now) -> ThreadRound {
        precondition(!scheduledRounds.isEmpty, "DailyScheduler requires at least one round")
        let cycleDayNumber = usesFutureSchedule ? roundSelectionDayNumber(now: now) : dayNumber(now: now)
        return scheduledRounds[(cycleDayNumber - 1) % scheduledRounds.count]
    }

    func todayDateKey(now: Date = .now) -> String {
        DateKeyFormatter.storage.string(from: now, timeZone: timeZone)
    }

    func nextUnlockDate(now: Date = .now) -> Date {
        let today = startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
    }

    private func roundSelectionDayNumber(now: Date = .now) -> Int {
        let anchor = startOfDay(for: roundSelectionAnchorDate)
        let today = startOfDay(for: now)
        let diff = calendar.dateComponents([.day], from: anchor, to: today).day ?? 0
        return max(1, diff + 1)
    }

    private static func seededShuffle(_ rounds: [ThreadRound], seed: UInt64) -> [ThreadRound] {
        guard rounds.count > 1 else { return rounds }

        var state = UInt32(truncatingIfNeeded: seed)
        var shuffled = rounds

        func nextUnit() -> Double {
            state = state &* 1_664_525 &+ 1_013_904_223
            return Double(state) / 4_294_967_296.0
        }

        for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let swapIndex = Int(floor(nextUnit() * Double(index + 1)))
            shuffled.swapAt(index, swapIndex)
        }

        return shuffled
    }
}

enum ShareTextBuilder {
    static func emojiRow(score: Int?) -> String {
        (0..<5).map { index in
            guard let score else { return "⚫" }
            return index < score ? "🟢" : "⚪"
        }.joined()
    }

    static func resultText(roundNumber: Int, score: Int?) -> String {
        let resultLine: String
        if let score, let tier = ScoreTier(rawValue: score) {
            resultLine = "\(tier.title) - \(score) clue\(score == 1 ? "" : "s")"
        } else {
            resultLine = "Missed today's thread"
        }

        return [
            "🧵 THREAD #\(roundNumber)",
            emojiRow(score: score),
            resultLine,
        ].joined(separator: "\n")
    }
}

enum DateKeyFormatter {
    static let storage = DateKeyFormatterFactory(
        dateFormat: "yyyy-MM-dd",
        locale: Locale(identifier: "en_GB_POSIX")
    )

    static let shortDisplay = DateKeyFormatterFactory(
        dateFormat: "MMM d",
        locale: Locale(identifier: "en_GB_POSIX")
    )

    static func formatForDisplay(_ dateKey: String) -> String {
        guard let date = storage.parse(dateKey, timeZone: .gmt) else {
            return dateKey
        }
        return shortDisplay.string(from: date, timeZone: .gmt)
    }

    static func dayDiff(from: String, to: String) -> Int {
        guard
            let start = storage.parse(from, timeZone: .gmt),
            let end = storage.parse(to, timeZone: .gmt)
        else {
            return 0
        }

        let seconds = end.timeIntervalSince(start)
        return Int(round(seconds / 86_400))
    }
}

struct DateKeyFormatterFactory {
    let dateFormat: String
    let locale: Locale

    func formatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = dateFormat
        return formatter
    }

    func string(from date: Date, timeZone: TimeZone) -> String {
        formatter(timeZone: timeZone).string(from: date)
    }

    func parse(_ raw: String, timeZone: TimeZone) -> Date? {
        formatter(timeZone: timeZone).date(from: raw)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

enum ThreadStatisticsBuilder {
    static func build(history: [DailyHistoryEntry], todayKey: String) -> ThreadStatsSummary {
        let ordered = history.sorted { $0.dateKey > $1.dateKey }
        let totalPlayed = ordered.count
        let solvedEntries = ordered.filter { $0.score != nil }
        let solvedCount = solvedEntries.count
        let missedCount = totalPlayed - solvedCount
        let solveRate = totalPlayed == 0 ? 0 : Int((Double(solvedCount) / Double(totalPlayed)) * 100)
        let averageClues = solvedEntries.isEmpty
            ? nil
            : Double(solvedEntries.compactMap(\.score).reduce(0, +)) / Double(solvedEntries.count)
        let bestScore = solvedEntries.compactMap(\.score).min()

        var scoreCounts = Dictionary(uniqueKeysWithValues: (1...5).map { ($0, 0) })
        for score in solvedEntries.compactMap(\.score) {
            scoreCounts[score, default: 0] += 1
        }

        let ascendingDates = Array(Set(ordered.map(\.dateKey))).sorted()

        var bestStreak = 0
        var runningStreak = 0
        var previousDate: String?

        for date in ascendingDates {
            if let previousDate, DateKeyFormatter.dayDiff(from: previousDate, to: date) == 1 {
                runningStreak += 1
            } else {
                runningStreak = 1
            }

            bestStreak = max(bestStreak, runningStreak)
            previousDate = date
        }

        let currentStreak: Int
        if let lastPlayed = ascendingDates.last, DateKeyFormatter.dayDiff(from: lastPlayed, to: todayKey) <= 1 {
            currentStreak = runningStreak
        } else {
            currentStreak = 0
        }

        return ThreadStatsSummary(
            totalPlayed: totalPlayed,
            solvedCount: solvedCount,
            missedCount: missedCount,
            solveRate: solveRate,
            averageClues: averageClues,
            bestScore: bestScore,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            scoreCounts: scoreCounts,
            recent: Array(ordered.prefix(14))
        )
    }
}
