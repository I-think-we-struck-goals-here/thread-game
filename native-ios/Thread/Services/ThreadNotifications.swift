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
}

struct ThreadReminderContext: Sendable {
    let currentStreak: Int
    let hasSolvedToday: Bool
    let nextDailyRefreshDate: Date?
    let now: Date
}

actor ThreadNotificationService: ThreadNotificationManaging {
    private enum Identifier {
        static let morning = "thread.daily-reminder.morning"
        static let evening = "thread.daily-reminder.evening"

        static let all = [morning, evening]
    }

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
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
                bySettingHour: 21,
                minute: 0,
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
