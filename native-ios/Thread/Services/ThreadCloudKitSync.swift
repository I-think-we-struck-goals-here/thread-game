import CloudKit
import Foundation

struct ThreadCloudSyncState: Sendable {
    var preferences: ThreadPreferences
    var history: [DailyHistoryEntry]
    var snapshots: [String: GameSnapshot]
}

protocol ThreadPrivateCloudSyncing: Sendable {
    func synchronize(localState: ThreadCloudSyncState) async -> ThreadCloudSyncState
    func upsertPreferences(_ preferences: ThreadPreferences) async
    func upsertHistoryEntry(_ entry: DailyHistoryEntry) async
    func saveSnapshot(_ snapshot: GameSnapshot) async
    func deleteSnapshot(for dateKey: String) async
    func clearHistoryAndSnapshots(historyDateKeys: [String], snapshotDateKeys: [String]) async
}

actor NoopThreadPrivateCloudSyncService: ThreadPrivateCloudSyncing {
    func synchronize(localState: ThreadCloudSyncState) async -> ThreadCloudSyncState { localState }
    func upsertPreferences(_ preferences: ThreadPreferences) async {}
    func upsertHistoryEntry(_ entry: DailyHistoryEntry) async {}
    func saveSnapshot(_ snapshot: GameSnapshot) async {}
    func deleteSnapshot(for dateKey: String) async {}
    func clearHistoryAndSnapshots(historyDateKeys: [String], snapshotDateKeys: [String]) async {}
}

enum ThreadCloudKitConfiguration {
    static func isEnabled(bundle: Bundle = .main) -> Bool {
        if let boolValue = bundle.object(forInfoDictionaryKey: "ThreadEnableICloudSync") as? Bool {
            return boolValue
        }

        if let rawValue = bundle.object(forInfoDictionaryKey: "ThreadEnableICloudSync") as? String {
            switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "yes", "true", "1":
                return true
            default:
                return false
            }
        }

        return false
    }

    static func containerIdentifier(bundle: Bundle = .main) -> String? {
        (bundle.object(forInfoDictionaryKey: "ThreadICloudContainerIdentifier") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .cloudKitNilIfEmpty
    }
}

enum ThreadCloudSyncMerger {
    static func merge(local: ThreadCloudSyncState, remote: ThreadCloudSyncState) -> ThreadCloudSyncState {
        merge(
            local: local,
            remotePreferences: remote.preferences,
            remoteHistory: remote.history,
            remoteSnapshots: remote.snapshots
        )
    }

    static func merge(
        local: ThreadCloudSyncState,
        remotePreferences: ThreadPreferences?,
        remoteHistory: [DailyHistoryEntry],
        remoteSnapshots: [String: GameSnapshot]
    ) -> ThreadCloudSyncState {
        let mergedPreferences = merge(local: local.preferences, remote: remotePreferences)

        let localHistory = Dictionary(uniqueKeysWithValues: local.history.map { ($0.dateKey, $0) })
        let remoteHistory = Dictionary(uniqueKeysWithValues: remoteHistory.map { ($0.dateKey, $0) })
        let allHistoryKeys = Set(localHistory.keys).union(remoteHistory.keys)
        let mergedHistory = allHistoryKeys.compactMap { key -> DailyHistoryEntry? in
            switch (localHistory[key], remoteHistory[key]) {
            case let (localEntry?, remoteEntry?):
                return merge(local: localEntry, remote: remoteEntry)
            case let (localEntry?, nil):
                return localEntry
            case let (nil, remoteEntry?):
                return remoteEntry
            default:
                return nil
            }
        }
        .sorted { $0.dateKey > $1.dateKey }

        let allSnapshotKeys = Set(local.snapshots.keys).union(remoteSnapshots.keys)
        let mergedSnapshots = allSnapshotKeys.reduce(into: [String: GameSnapshot]()) { partialResult, key in
            let merged = merge(local: local.snapshots[key], remote: remoteSnapshots[key])
            if let merged {
                partialResult[key] = merged
            }
        }
        .filter { key, _ in
            !mergedHistory.contains(where: { $0.dateKey == key })
        }

        return ThreadCloudSyncState(
            preferences: mergedPreferences,
            history: mergedHistory,
            snapshots: mergedSnapshots
        )
    }

    static func merge(local: DailyHistoryEntry, remote: DailyHistoryEntry) -> DailyHistoryEntry {
        let mergedScore: Int?
        switch (local.score, remote.score) {
        case let (left?, right?):
            mergedScore = min(left, right)
        case let (left?, nil):
            mergedScore = left
        case let (nil, right?):
            mergedScore = right
        default:
            mergedScore = nil
        }

        let preferred = preferredHistoryEntry(local: local, remote: remote)
        return DailyHistoryEntry(
            dateKey: preferred.dateKey,
            roundID: preferred.roundID,
            answer: preferred.answer,
            score: mergedScore,
            completedAt: min(local.completedAt, remote.completedAt),
            aggregateSubmittedAt: [local.aggregateSubmittedAt, remote.aggregateSubmittedAt]
                .compactMap { $0 }
                .max()
        )
    }

    static func merge(local: ThreadPreferences, remote: ThreadPreferences?) -> ThreadPreferences {
        guard let remote else { return local }

        let localUpdatedAt = local.updatedAt ?? .distantPast
        let remoteUpdatedAt = remote.updatedAt ?? .distantPast

        if localUpdatedAt == remoteUpdatedAt {
            return local
        }

        return remoteUpdatedAt > localUpdatedAt ? remote : local
    }

    static func merge(local: GameSnapshot?, remote: GameSnapshot?) -> GameSnapshot? {
        switch (local, remote) {
        case let (local?, remote?):
            let localUpdatedAt = local.updatedAt ?? .distantPast
            let remoteUpdatedAt = remote.updatedAt ?? .distantPast

            if localUpdatedAt == remoteUpdatedAt {
                if local.isSolved != remote.isSolved {
                    return local.isSolved ? local : remote
                }
                if local.isFailed != remote.isFailed {
                    return local.isFailed ? local : remote
                }
                return local
            }

            return localUpdatedAt >= remoteUpdatedAt ? local : remote
        case let (local?, nil):
            return local
        case let (nil, remote?):
            return remote
        case (nil, nil):
            return nil
        }
    }

    private static func preferredHistoryEntry(local: DailyHistoryEntry, remote: DailyHistoryEntry) -> DailyHistoryEntry {
        switch (local.score, remote.score) {
        case let (left?, right?) where left != right:
            return left < right ? local : remote
        case (_?, nil):
            return local
        case (nil, _?):
            return remote
        default:
            return local.completedAt <= remote.completedAt ? local : remote
        }
    }
}

actor ThreadCloudKitSyncService: ThreadPrivateCloudSyncing {
    private enum RecordType {
        static let preferences = "UserPreferences"
        static let history = "DailyHistoryEntry"
        static let snapshot = "GameSnapshot"
    }

    private enum FieldKey {
        static let analyticsEnabled = "analyticsEnabled"
        static let aggregateSharingEnabled = "aggregateSharingEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let dailyRemindersEnabled = "dailyRemindersEnabled"
        static let preferencesUpdatedAt = "preferencesUpdatedAt"
        static let dateKey = "dateKey"
        static let roundID = "roundID"
        static let answer = "answer"
        static let score = "score"
        static let completedAt = "completedAt"
        static let aggregateSubmittedAt = "aggregateSubmittedAt"
        static let revealedClueCount = "revealedClueCount"
        static let guess = "guess"
        static let attempts = "attempts"
        static let isSolved = "isSolved"
        static let isFailed = "isFailed"
        static let updatedAt = "updatedAt"
    }

    private enum RecordName {
        static let preferences = "preferences"

        static func history(_ dateKey: String) -> String {
            "history.\(dateKey)"
        }

        static func snapshot(_ dateKey: String) -> String {
            "snapshot.\(dateKey)"
        }
    }

    private struct RemoteState {
        var preferences: ThreadPreferences?
        var history: [String: DailyHistoryEntry]
        var snapshots: [String: GameSnapshot]
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID
    private var didPrepareZone = false

    init(
        containerIdentifier: String? = nil,
        zoneName: String = "ThreadPrivateData"
    ) {
        let resolvedContainer = containerIdentifier.flatMap(CKContainer.init(identifier:)) ?? .default()
        self.container = resolvedContainer
        self.database = resolvedContainer.privateCloudDatabase
        self.zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    func synchronize(localState: ThreadCloudSyncState) async -> ThreadCloudSyncState {
        guard await accountIsAvailable() else { return localState }

        do {
            try await prepareZoneIfNeeded()
            let remoteState = try await fetchRemoteState()
            let mergedState = merge(local: localState, remote: remoteState)
            try await pushDifferences(from: remoteState, mergedState: mergedState)
            return mergedState
        } catch {
            return localState
        }
    }

    func upsertPreferences(_ preferences: ThreadPreferences) async {
        guard await accountIsAvailable() else { return }

        do {
            try await prepareZoneIfNeeded()
            try await savePreferencesRecord(preferences)
        } catch {}
    }

    func upsertHistoryEntry(_ entry: DailyHistoryEntry) async {
        guard await accountIsAvailable() else { return }

        do {
            try await prepareZoneIfNeeded()
            try await saveHistoryRecord(entry)
        } catch {}
    }

    func saveSnapshot(_ snapshot: GameSnapshot) async {
        guard await accountIsAvailable() else { return }
        guard snapshot.dateKey != nil else { return }

        do {
            try await prepareZoneIfNeeded()
            try await saveSnapshotRecord(snapshot)
        } catch {}
    }

    func deleteSnapshot(for dateKey: String) async {
        guard await accountIsAvailable() else { return }

        do {
            try await prepareZoneIfNeeded()
            try await deleteRecord(id: snapshotRecordID(for: dateKey))
        } catch {}
    }

    func clearHistoryAndSnapshots(historyDateKeys: [String], snapshotDateKeys: [String]) async {
        guard await accountIsAvailable() else { return }

        do {
            try await prepareZoneIfNeeded()

            for dateKey in historyDateKeys {
                try await deleteRecord(id: historyRecordID(for: dateKey))
            }

            for dateKey in snapshotDateKeys {
                try await deleteRecord(id: snapshotRecordID(for: dateKey))
            }
        } catch {}
    }

    private func accountIsAvailable() async -> Bool {
        do {
            return try await container.accountStatus() == .available
        } catch {
            return false
        }
    }

    private func prepareZoneIfNeeded() async throws {
        guard !didPrepareZone else { return }
        _ = try await database.save(CKRecordZone(zoneID: zoneID))
        didPrepareZone = true
    }

    private func fetchRemoteState() async throws -> RemoteState {
        async let preferences = fetchPreferencesRecord()
        async let history = fetchHistoryRecords()
        async let snapshots = fetchSnapshotRecords()

        return try await RemoteState(
            preferences: preferences,
            history: Dictionary(uniqueKeysWithValues: history.compactMap { entry in
                (entry.dateKey, entry)
            }),
            snapshots: Dictionary(uniqueKeysWithValues: snapshots.compactMap { snapshot in
                guard let dateKey = snapshot.dateKey else { return nil }
                return (dateKey, snapshot)
            })
        )
    }

    private func fetchPreferencesRecord() async throws -> ThreadPreferences? {
        guard let record = try await fetchRecord(id: preferencesRecordID()) else {
            return nil
        }

        return ThreadPreferences(
            analyticsEnabled: (record[FieldKey.analyticsEnabled] as? NSNumber)?.boolValue ?? ThreadPreferences.default.analyticsEnabled,
            aggregateSharingEnabled: (record[FieldKey.aggregateSharingEnabled] as? NSNumber)?.boolValue ?? ThreadPreferences.default.aggregateSharingEnabled,
            hapticsEnabled: (record[FieldKey.hapticsEnabled] as? NSNumber)?.boolValue ?? ThreadPreferences.default.hapticsEnabled,
            dailyRemindersEnabled: (record[FieldKey.dailyRemindersEnabled] as? NSNumber)?.boolValue ?? ThreadPreferences.default.dailyRemindersEnabled,
            updatedAt: record[FieldKey.preferencesUpdatedAt] as? Date
        )
    }

    private func fetchHistoryRecords() async throws -> [DailyHistoryEntry] {
        try await fetchRecords(ofType: RecordType.history).compactMap(decodeHistoryRecord)
    }

    private func fetchSnapshotRecords() async throws -> [GameSnapshot] {
        try await fetchRecords(ofType: RecordType.snapshot).compactMap(decodeSnapshotRecord)
    }

    private func fetchRecords(ofType recordType: String) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let batch: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)

            if let cursor {
                batch = try await database.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: nil,
                    resultsLimit: CKQueryOperation.maximumResults
                )
            } else {
                batch = try await database.records(
                    matching: query,
                    inZoneWith: zoneID,
                    desiredKeys: nil,
                    resultsLimit: CKQueryOperation.maximumResults
                )
            }

            records.append(contentsOf: batch.matchResults.compactMap { _, result in
                try? result.get()
            })

            cursor = batch.queryCursor
        } while cursor != nil

        return records
    }

    private func fetchRecord(id: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await database.record(for: id)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func savePreferencesRecord(_ preferences: ThreadPreferences) async throws {
        let recordID = preferencesRecordID()
        let record = try await fetchRecord(id: recordID) ?? CKRecord(recordType: RecordType.preferences, recordID: recordID)
        record[FieldKey.analyticsEnabled] = preferences.analyticsEnabled as NSNumber
        record[FieldKey.aggregateSharingEnabled] = preferences.aggregateSharingEnabled as NSNumber
        record[FieldKey.hapticsEnabled] = preferences.hapticsEnabled as NSNumber
        record[FieldKey.dailyRemindersEnabled] = preferences.dailyRemindersEnabled as NSNumber
        record[FieldKey.preferencesUpdatedAt] = (preferences.updatedAt ?? .now) as NSDate
        _ = try await database.save(record)
    }

    private func saveHistoryRecord(_ entry: DailyHistoryEntry) async throws {
        let recordID = historyRecordID(for: entry.dateKey)
        let record = try await fetchRecord(id: recordID) ?? CKRecord(recordType: RecordType.history, recordID: recordID)
        let scoreValue: NSNumber? = entry.score.map { NSNumber(value: $0) }
        let aggregateSubmittedAtValue: NSDate? = entry.aggregateSubmittedAt.map { $0 as NSDate }
        record[FieldKey.dateKey] = entry.dateKey as NSString
        record[FieldKey.roundID] = entry.roundID as NSNumber
        record[FieldKey.answer] = entry.answer as NSString
        record[FieldKey.score] = scoreValue
        record[FieldKey.completedAt] = entry.completedAt as NSDate
        record[FieldKey.aggregateSubmittedAt] = aggregateSubmittedAtValue
        _ = try await database.save(record)
    }

    private func saveSnapshotRecord(_ snapshot: GameSnapshot) async throws {
        guard let dateKey = snapshot.dateKey else { return }
        let recordID = snapshotRecordID(for: dateKey)
        let record = try await fetchRecord(id: recordID) ?? CKRecord(recordType: RecordType.snapshot, recordID: recordID)
        record[FieldKey.dateKey] = dateKey as NSString
        record[FieldKey.roundID] = snapshot.roundID as NSNumber
        record[FieldKey.revealedClueCount] = snapshot.revealedClueCount as NSNumber
        record[FieldKey.guess] = snapshot.guess as NSString
        record[FieldKey.attempts] = snapshot.attempts as NSArray
        record[FieldKey.isSolved] = snapshot.isSolved as NSNumber
        record[FieldKey.isFailed] = snapshot.isFailed as NSNumber
        record[FieldKey.updatedAt] = (snapshot.updatedAt ?? .now) as NSDate
        _ = try await database.save(record)
    }

    private func deleteRecord(id: CKRecord.ID) async throws {
        do {
            _ = try await database.deleteRecord(withID: id)
        } catch let error as CKError where error.code == .unknownItem {
            return
        }
    }

    private func decodeHistoryRecord(_ record: CKRecord) -> DailyHistoryEntry? {
        guard
            let dateKey = record[FieldKey.dateKey] as? String,
            let roundID = (record[FieldKey.roundID] as? NSNumber)?.intValue,
            let answer = record[FieldKey.answer] as? String,
            let completedAt = record[FieldKey.completedAt] as? Date
        else {
            return nil
        }

        return DailyHistoryEntry(
            dateKey: dateKey,
            roundID: roundID,
            answer: answer,
            score: (record[FieldKey.score] as? NSNumber)?.intValue,
            completedAt: completedAt,
            aggregateSubmittedAt: record[FieldKey.aggregateSubmittedAt] as? Date
        )
    }

    private func decodeSnapshotRecord(_ record: CKRecord) -> GameSnapshot? {
        guard
            let dateKey = record[FieldKey.dateKey] as? String,
            let roundID = (record[FieldKey.roundID] as? NSNumber)?.intValue,
            let revealedClueCount = (record[FieldKey.revealedClueCount] as? NSNumber)?.intValue
        else {
            return nil
        }

        return GameSnapshot(
            roundID: roundID,
            dateKey: dateKey,
            revealedClueCount: revealedClueCount,
            guess: record[FieldKey.guess] as? String ?? "",
            attempts: record[FieldKey.attempts] as? [String] ?? [],
            isSolved: (record[FieldKey.isSolved] as? NSNumber)?.boolValue ?? false,
            isFailed: (record[FieldKey.isFailed] as? NSNumber)?.boolValue ?? false,
            updatedAt: record[FieldKey.updatedAt] as? Date
        )
    }

    private func pushDifferences(from remoteState: RemoteState, mergedState: ThreadCloudSyncState) async throws {
        if remoteState.preferences != mergedState.preferences {
            try await savePreferencesRecord(mergedState.preferences)
        }

        for entry in mergedState.history {
            if remoteState.history[entry.dateKey] != entry {
                try await saveHistoryRecord(entry)
            }
        }

        for (dateKey, snapshot) in mergedState.snapshots {
            if remoteState.snapshots[dateKey] != snapshot {
                try await saveSnapshotRecord(snapshot)
            }
        }

        let mergedSnapshotKeys = Set(mergedState.snapshots.keys)
        let staleRemoteSnapshotKeys = Set(remoteState.snapshots.keys).subtracting(mergedSnapshotKeys)

        for dateKey in staleRemoteSnapshotKeys {
            try await deleteRecord(id: snapshotRecordID(for: dateKey))
        }
    }

    private func merge(local: ThreadCloudSyncState, remote: RemoteState) -> ThreadCloudSyncState {
        ThreadCloudSyncMerger.merge(
            local: local,
            remotePreferences: remote.preferences,
            remoteHistory: Array(remote.history.values),
            remoteSnapshots: remote.snapshots
        )
    }

    private func preferencesRecordID() -> CKRecord.ID {
        CKRecord.ID(recordName: RecordName.preferences, zoneID: zoneID)
    }

    private func historyRecordID(for dateKey: String) -> CKRecord.ID {
        CKRecord.ID(recordName: RecordName.history(dateKey), zoneID: zoneID)
    }

    private func snapshotRecordID(for dateKey: String) -> CKRecord.ID {
        CKRecord.ID(recordName: RecordName.snapshot(dateKey), zoneID: zoneID)
    }
}

private extension String {
    var cloudKitNilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
