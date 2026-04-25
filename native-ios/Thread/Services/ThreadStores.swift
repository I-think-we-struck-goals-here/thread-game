import Foundation

@MainActor
final class LocalThreadStore {
    private enum Keys {
        static let tutorialCompleted = "thread.native.tutorialCompleted"
        static let history = "thread.native.history"
        static let snapshots = "thread.native.snapshots"
        static let installationID = "thread.native.installationID"
        static let preferences = "thread.native.preferences"
        static let notificationPromptState = "thread.native.notificationPromptState"
        static let hasSolvedPracticeRound = "thread.native.hasSolvedPracticeRound"
        static let firstDailyNudgeStage = "thread.native.firstDailyNudgeStage"
        static let firstDailyNudgeDateKey = "thread.native.firstDailyNudgeDateKey"
    }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    var tutorialCompleted: Bool {
        get { defaults.bool(forKey: Keys.tutorialCompleted) }
        set { defaults.set(newValue, forKey: Keys.tutorialCompleted) }
    }

    var installationID: String {
        if let existing = defaults.string(forKey: Keys.installationID), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: Keys.installationID)
        return newID
    }

    var preferences: ThreadPreferences {
        get {
            guard let data = defaults.data(forKey: Keys.preferences) else {
                return .default
            }

            return (try? decoder.decode(ThreadPreferences.self, from: data)) ?? .default
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: Keys.preferences)
        }
    }

    func replacePreferences(_ preferences: ThreadPreferences) {
        self.preferences = preferences
    }

    var notificationPromptState: ThreadNotificationPromptState {
        get {
            guard let data = defaults.data(forKey: Keys.notificationPromptState) else {
                return .default
            }

            return (try? decoder.decode(ThreadNotificationPromptState.self, from: data)) ?? .default
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            defaults.set(data, forKey: Keys.notificationPromptState)
        }
    }

    var hasSolvedPracticeRound: Bool {
        get { defaults.bool(forKey: Keys.hasSolvedPracticeRound) }
        set { defaults.set(newValue, forKey: Keys.hasSolvedPracticeRound) }
    }

    var firstDailyNudgeStage: ThreadFirstDailyNudgeStage {
        get {
            guard let rawValue = defaults.string(forKey: Keys.firstDailyNudgeStage),
                  let stage = ThreadFirstDailyNudgeStage(rawValue: rawValue) else {
                return .unseen
            }
            return stage
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.firstDailyNudgeStage)
        }
    }

    var firstDailyNudgeDateKey: String? {
        get { defaults.string(forKey: Keys.firstDailyNudgeDateKey) }
        set { defaults.set(newValue, forKey: Keys.firstDailyNudgeDateKey) }
    }

    @discardableResult
    func recordAppOpenDay(_ dateKey: String) -> ThreadNotificationPromptState {
        var state = notificationPromptState
        if !state.seenDateKeys.contains(dateKey) {
            state.seenDateKeys.append(dateKey)
            state.seenDateKeys.sort()
            if state.seenDateKeys.count > 30 {
                state.seenDateKeys.removeFirst(state.seenDateKeys.count - 30)
            }
            notificationPromptState = state
        }
        return state
    }

    @discardableResult
    func markNotificationPromptShown(at date: Date = .now) -> ThreadNotificationPromptState {
        var state = notificationPromptState
        state.promptCount += 1
        state.lastPromptAt = date
        notificationPromptState = state
        return state
    }

    func loadHistory() -> [DailyHistoryEntry] {
        guard let data = defaults.data(forKey: Keys.history) else { return [] }

        do {
            return try decoder.decode([DailyHistoryEntry].self, from: data)
                .sorted { $0.dateKey > $1.dateKey }
        } catch {
            return []
        }
    }

    @discardableResult
    func upsertHistoryEntry(_ entry: DailyHistoryEntry) -> [DailyHistoryEntry] {
        var entries = loadHistory().filter { $0.dateKey != entry.dateKey }
        entries.append(entry)
        let sorted = entries.sorted { $0.dateKey > $1.dateKey }

        if let data = try? encoder.encode(sorted) {
            defaults.set(data, forKey: Keys.history)
        }

        return sorted
    }

    func replaceHistory(_ entries: [DailyHistoryEntry]) {
        let sorted = entries.sorted { $0.dateKey > $1.dateKey }

        if let data = try? encoder.encode(sorted) {
            defaults.set(data, forKey: Keys.history)
        }
    }

    func loadSnapshot(for dateKey: String, roundID: Int) -> GameSnapshot? {
        loadSnapshotMap()[dateKey].flatMap { snapshot in
            snapshot.roundID == roundID ? snapshot : nil
        }
    }

    func loadAllSnapshots() -> [String: GameSnapshot] {
        loadSnapshotMap()
    }

    func saveSnapshot(_ snapshot: GameSnapshot) {
        guard let dateKey = snapshot.dateKey else { return }
        var snapshots = loadSnapshotMap()
        snapshots[dateKey] = snapshot
        persistSnapshotMap(snapshots)
    }

    func replaceSnapshots(_ snapshots: [String: GameSnapshot]) {
        persistSnapshotMap(snapshots)
    }

    func clearSnapshot(for dateKey: String) {
        var snapshots = loadSnapshotMap()
        snapshots.removeValue(forKey: dateKey)
        persistSnapshotMap(snapshots)
    }

    func clearAllSnapshots() {
        defaults.removeObject(forKey: Keys.snapshots)
    }

    func clearHistory() {
        defaults.removeObject(forKey: Keys.history)
    }

    func clearGameplayProgress() {
        clearHistory()
        clearAllSnapshots()
    }

    func resetForFreshLaunch() {
        resetTutorial()
        clearGameplayProgress()
        hasSolvedPracticeRound = false
        firstDailyNudgeStage = .unseen
        firstDailyNudgeDateKey = nil
    }

    func resetTutorial() {
        defaults.set(false, forKey: Keys.tutorialCompleted)
        hasSolvedPracticeRound = false
        firstDailyNudgeStage = .unseen
        firstDailyNudgeDateKey = nil
    }

    private func loadSnapshotMap() -> [String: GameSnapshot] {
        guard let data = defaults.data(forKey: Keys.snapshots) else { return [:] }

        do {
            return try decoder.decode([String: GameSnapshot].self, from: data)
        } catch {
            return [:]
        }
    }

    private func persistSnapshotMap(_ snapshots: [String: GameSnapshot]) {
        guard let data = try? encoder.encode(snapshots) else { return }
        defaults.set(data, forKey: Keys.snapshots)
    }
}
