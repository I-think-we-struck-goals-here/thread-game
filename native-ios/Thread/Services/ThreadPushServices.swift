import Foundation

struct ThreadPushServiceConfiguration: Sendable, Hashable {
    let isEnabled: Bool
    let baseURL: URL?
    let apiKey: String?

    static func fromEnvironment(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> ThreadPushServiceConfiguration {
        let isEnabled = (
            processInfo.environment["THREAD_ENABLE_REMOTE_PUSH"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadEnableRemotePush") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let baseURLString = (
            processInfo.environment["THREAD_PUSH_BASE_URL"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadPushBaseURL") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let apiKey = (
            processInfo.environment["THREAD_PUSH_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadPushAPIKey") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ThreadPushServiceConfiguration(
            isEnabled: ["1", "true", "yes"].contains(isEnabled ?? ""),
            baseURL: baseURLString.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            apiKey: apiKey?.isEmpty == false ? apiKey : nil
        )
    }

    var backendConfigured: Bool {
        baseURL != nil
    }
}

enum ThreadRemotePushStatus: Hashable, Sendable {
    case disabled
    case awaitingAuthorization
    case registering
    case backendMissing
    case synced
    case failed

    var summary: String {
        switch self {
        case .disabled:
            return "Broadcast push is inactive in this build."
        case .awaitingAuthorization:
            return "Broadcast push is ready, but notification permission has not been granted yet."
        case .registering:
            return "Broadcast push is enabled and waiting for device registration."
        case .backendMissing:
            return "Broadcast push plumbing is wired, but no backend endpoint is configured yet."
        case .synced:
            return "Broadcast push is ready for future one-off announcements."
        case .failed:
            return "Broadcast push registration needs another pass before launch."
        }
    }
}

struct ThreadPushSubscriptionPayload: Codable, Sendable {
    let installationID: String
    let deviceToken: String
    let remindersEnabled: Bool
    let authorizationStatus: String
    let locale: String
    let timeZone: String
    let appVersion: String
    let platform: String
}

protocol ThreadPushRegistrationSending: Sendable {
    func upsertSubscription(
        installationID: String,
        deviceToken: String,
        remindersEnabled: Bool,
        authorizationStatus: ThreadNotificationAuthorizationStatus
    ) async -> Bool
}

struct NoopThreadPushRegistrationClient: ThreadPushRegistrationSending {
    func upsertSubscription(
        installationID: String,
        deviceToken: String,
        remindersEnabled: Bool,
        authorizationStatus: ThreadNotificationAuthorizationStatus
    ) async -> Bool {
        false
    }
}

enum ThreadPushServiceFactory {
    static func make(
        configuration: ThreadPushServiceConfiguration,
        bundle: Bundle = .main
    ) -> any ThreadPushRegistrationSending {
        guard configuration.backendConfigured, let baseURL = configuration.baseURL else {
            return NoopThreadPushRegistrationClient()
        }

        return RemoteThreadPushRegistrationClient(
            configuration: configuration,
            baseURL: baseURL,
            bundle: bundle
        )
    }
}

actor RemoteThreadPushRegistrationClient: ThreadPushRegistrationSending {
    private let configuration: ThreadPushServiceConfiguration
    private let baseURL: URL
    private let bundle: Bundle
    private let session: URLSession
    private let encoder = JSONEncoder()

    init(
        configuration: ThreadPushServiceConfiguration,
        baseURL: URL,
        bundle: Bundle = .main,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.baseURL = baseURL
        self.bundle = bundle
        self.session = session
    }

    func upsertSubscription(
        installationID: String,
        deviceToken: String,
        remindersEnabled: Bool,
        authorizationStatus: ThreadNotificationAuthorizationStatus
    ) async -> Bool {
        let payload = ThreadPushSubscriptionPayload(
            installationID: installationID,
            deviceToken: deviceToken,
            remindersEnabled: remindersEnabled,
            authorizationStatus: authorizationStatus.rawValue,
            locale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier,
            appVersion: appVersion,
            platform: "ios"
        )

        guard let body = try? encoder.encode(payload) else {
            return false
        }

        do {
            var request = URLRequest(url: baseURL.appending(path: "/v1/push/installations"))
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Thread-iOS/\(appVersion)", forHTTPHeaderField: "User-Agent")
            if let apiKey = configuration.apiKey, !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = body

            let (_, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            return (200...299).contains(statusCode)
        } catch {
            return false
        }
    }

    private var appVersion: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version)-\(build)"
    }
}
