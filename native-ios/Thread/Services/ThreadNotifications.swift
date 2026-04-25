import Foundation
import UserNotifications

enum ThreadNotificationAuthorizationStatus: String, Codable, Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    case unsupported

    var isGranted: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
}

struct ThreadNotificationPrompt: Identifiable, Equatable {
    enum Kind: Equatable {
        case requestAuthorization
        case openSettings
    }

    let id: String
    let kind: Kind
    let title: String
    let message: String
    let confirmTitle: String
}

protocol ThreadNotificationManaging: Sendable {
    func authorizationStatus() async -> ThreadNotificationAuthorizationStatus
    func requestAuthorization() async -> ThreadNotificationAuthorizationStatus
    func scheduleDailyReminders(context: ThreadReminderContext) async
    func removeDailyReminders() async
    func debugPendingRequests() async -> [ThreadDebugNotificationRequest]
    func scheduleDebugReminder(after seconds: TimeInterval) async
}

struct ThreadReminderContext: Sendable {
    let currentStreak: Int
    let hasSolvedToday: Bool
    let nextDailyRefreshDate: Date?
    let now: Date
}

struct ThreadReminderSchedule {
    let finalReminderHour: Int
    let finalReminderMinute: Int

    static let `default` = ThreadReminderSchedule(
        finalReminderHour: 21,
        finalReminderMinute: 0
    )

    static func fromBundle(_ bundle: Bundle = .main) -> ThreadReminderSchedule {
        ThreadReminderSchedule(
            finalReminderHour: value(for: "ThreadFinalReminderHour", defaultValue: Self.default.finalReminderHour, bundle: bundle),
            finalReminderMinute: value(for: "ThreadFinalReminderMinute", defaultValue: Self.default.finalReminderMinute, bundle: bundle)
        )
    }

    private static func value(for key: String, defaultValue: Int, bundle: Bundle) -> Int {
        if let number = bundle.object(forInfoDictionaryKey: key) as? NSNumber {
            return number.intValue
        }

        if let rawValue = bundle.object(forInfoDictionaryKey: key) as? String,
           let parsed = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return parsed
        }

        return defaultValue
    }
}

struct ThreadDebugNotificationRequest: Sendable, Equatable {
    let identifier: String
    let title: String
    let body: String
    let nextTriggerDate: Date?
}

actor ThreadNotificationService: ThreadNotificationManaging {
    private enum Identifier {
        static let morning = "thread.daily-reminder.morning"
        static let evening = "thread.daily-reminder.evening"

        static let all = [morning, evening]
    }

    private let center: UNUserNotificationCenter
    private let schedule: ThreadReminderSchedule

    init(
        center: UNUserNotificationCenter = .current(),
        schedule: ThreadReminderSchedule = .fromBundle()
    ) {
        self.center = center
        self.schedule = schedule
    }

    func authorizationStatus() async -> ThreadNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return map(settings.authorizationStatus)
    }

    func requestAuthorization() async -> ThreadNotificationAuthorizationStatus {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return await authorizationStatus()
        }

        return await authorizationStatus()
    }

    func scheduleDailyReminders(context: ThreadReminderContext) async {
        guard await authorizationStatus().isGranted else { return }

        await removeDailyReminders()

        let morningContent = UNMutableNotificationContent()
        morningContent.title = "A new Thread is live"
        morningContent.body = "Today's puzzle is ready."
        morningContent.sound = .default

        let morningTrigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: 9, minute: 0),
            repeats: true
        )

        let morningRequest = UNNotificationRequest(
            identifier: Identifier.morning,
            content: morningContent,
            trigger: morningTrigger
        )

        try? await center.add(morningRequest)

        guard !context.hasSolvedToday else { return }
        guard let eveningTrigger = eveningTrigger(from: context) else { return }

        let eveningContent = UNMutableNotificationContent()
        if context.currentStreak >= 10 {
            eveningContent.title = "Keep your \(context.currentStreak)-day run alive"
        } else {
            eveningContent.title = "Still time to solve"
        }
        eveningContent.body = "Today's Thread is still waiting."
        eveningContent.sound = .default

        let eveningRequest = UNNotificationRequest(
            identifier: Identifier.evening,
            content: eveningContent,
            trigger: eveningTrigger
        )

        try? await center.add(eveningRequest)
    }

    func removeDailyReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.all)
        center.removeDeliveredNotifications(withIdentifiers: Identifier.all)
    }

    func debugPendingRequests() async -> [ThreadDebugNotificationRequest] {
        let requests = await center.pendingNotificationRequests()
        return requests.map { request in
            ThreadDebugNotificationRequest(
                identifier: request.identifier,
                title: request.content.title,
                body: request.content.body,
                nextTriggerDate: debugNextTriggerDate(for: request.trigger)
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.nextTriggerDate, rhs.nextTriggerDate) {
            case let (left?, right?):
                return left < right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.identifier < rhs.identifier
            }
        }
    }

    func scheduleDebugReminder(after seconds: TimeInterval) async {
        guard await authorizationStatus().isGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Thread debug reminder"
        content.body = "If you can see this, local notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: "thread.debug-reminder.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func debugNextTriggerDate(for trigger: UNNotificationTrigger?) -> Date? {
        switch trigger {
        case let calendarTrigger as UNCalendarNotificationTrigger:
            return calendarTrigger.nextTriggerDate()
        case let timeIntervalTrigger as UNTimeIntervalNotificationTrigger:
            return timeIntervalTrigger.nextTriggerDate()
        default:
            return nil
        }
    }

    private func map(_ status: UNAuthorizationStatus) -> ThreadNotificationAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .unsupported
        }
    }

    private func eveningTrigger(from context: ThreadReminderContext) -> UNCalendarNotificationTrigger? {
        let calendar = Calendar.autoupdatingCurrent
        let now = context.now

        guard
            let eveningToday = calendar.date(
                bySettingHour: schedule.finalReminderHour,
                minute: schedule.finalReminderMinute,
                second: 0,
                of: now
            )
        else {
            return nil
        }

        guard now < eveningToday else { return nil }

        if let nextDailyRefreshDate = context.nextDailyRefreshDate, eveningToday >= nextDailyRefreshDate {
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eveningToday)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
