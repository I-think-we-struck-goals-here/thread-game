import Foundation
import UIKit

struct AnalyticsServiceConfiguration: Sendable {
    let baseURL: URL
    let apiKey: String?
    let buildChannel: String

    static func fromEnvironment(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> AnalyticsServiceConfiguration? {
        let baseURLString = (
            processInfo.environment["THREAD_ANALYTICS_BASE_URL"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadAnalyticsBaseURL") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let baseURLString,
            let baseURL = URL(string: baseURLString),
            !baseURLString.isEmpty
        else {
            return nil
        }

        let apiKey = (
            processInfo.environment["THREAD_ANALYTICS_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadAnalyticsAPIKey") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let buildChannel = (
            processInfo.environment["THREAD_ANALYTICS_BUILD_CHANNEL"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadAnalyticsBuildChannel") as? String
            ?? "release"
        )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AnalyticsServiceConfiguration(
            baseURL: baseURL,
            apiKey: apiKey,
            buildChannel: buildChannel.isEmpty ? "release" : buildChannel
        )
    }
}

struct AnalyticsEventPayload: Codable, Sendable {
    let sessionID: String
    let event: String
    let properties: [String: String]
    let occurredAt: Date
    let appVersion: String
    let platform: String
    let deviceClass: String
}

enum AnalyticsServiceFactory {
    @MainActor
    static func make(
        sessionID: String = UUID().uuidString,
        bundle: Bundle = .main
    ) -> AnalyticsTracking {
        guard let configuration = AnalyticsServiceConfiguration.fromEnvironment(bundle: bundle) else {
            return LocalAnalyticsClient()
        }

        return RemoteAnalyticsClient(
            sessionID: sessionID,
            worker: RemoteAnalyticsClientWorker(
                configuration: configuration,
                deviceClass: currentDeviceClass()
            )
        )
    }

    @MainActor
    private static func currentDeviceClass() -> String {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return "ipad"
        case .phone:
            return "iphone"
        default:
            return "other"
        }
    }
}

struct RemoteAnalyticsClient: AnalyticsTracking, Sendable {
    private let sessionID: String
    private let worker: RemoteAnalyticsClientWorker

    init(
        sessionID: String,
        worker: RemoteAnalyticsClientWorker
    ) {
        self.sessionID = sessionID
        self.worker = worker
    }

    func track(_ event: AnalyticsEvent) {
        Task {
            await worker.send(event: event, sessionID: sessionID)
        }
    }
}

actor RemoteAnalyticsClientWorker {
    private let configuration: AnalyticsServiceConfiguration
    private let deviceClass: String
    private let session: URLSession
    private let encoder = JSONEncoder()

    init(
        configuration: AnalyticsServiceConfiguration,
        deviceClass: String,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.deviceClass = deviceClass
        self.session = session
        encoder.dateEncodingStrategy = .iso8601
    }

    func send(event: AnalyticsEvent, sessionID: String) async {
        let payload = AnalyticsEventPayload(
            sessionID: sessionID,
            event: event.name,
            properties: event.properties.merging(["build_channel": configuration.buildChannel]) { current, _ in current },
            occurredAt: .now,
            appVersion: appVersion,
            platform: "ios",
            deviceClass: deviceClass
        )

        guard let body = try? encoder.encode(payload) else {
            return
        }

        do {
            let request = try makeRequest(
                path: "/v1/events",
                method: "POST",
                body: body
            )
            _ = try await session.data(for: request)
        } catch {
            return
        }
    }

    private func makeRequest(
        path: String,
        method: String,
        body: Data? = nil
    ) throws -> URLRequest {
        let url = configuration.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Thread-iOS/\(appVersion)", forHTTPHeaderField: "User-Agent")

        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version)-\(build)"
    }
}
