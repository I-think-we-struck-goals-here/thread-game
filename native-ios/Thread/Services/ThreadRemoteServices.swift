import Foundation

struct AggregateServiceConfiguration: Sendable {
    let baseURL: URL
    let apiKey: String?

    static func fromEnvironment(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> AggregateServiceConfiguration? {
        let baseURLString = (
            processInfo.environment["THREAD_AGGREGATE_BASE_URL"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadAggregateBaseURL") as? String
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
            processInfo.environment["THREAD_AGGREGATE_API_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "ThreadAggregateAPIKey") as? String
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return AggregateServiceConfiguration(
            baseURL: baseURL,
            apiKey: apiKey
        )
    }
}

struct AggregateSubmissionPayload: Codable, Sendable {
    let installationID: String
    let roundID: Int
    let dateKey: String
    let score: Int?
    let appVersion: String
    let platform: String
}

struct AggregateHistogramResponse: Codable, Sendable {
    let roundID: Int
    let totalSubmissions: Int
    let buckets: [AggregateHistogramBucketResponse]
}

struct AggregateHistogramBucketResponse: Codable, Sendable {
    let bucket: Int
    let count: Int
}

enum AggregateServiceFactory {
    static func make(bundle: Bundle = .main) -> any AggregateStatsProviding {
        guard let configuration = AggregateServiceConfiguration.fromEnvironment(bundle: bundle) else {
            return NoopAggregateStatsClient()
        }

        return RemoteAggregateStatsClient(configuration: configuration)
    }
}

actor RemoteAggregateStatsClient: AggregateStatsProviding {
    private let configuration: AggregateServiceConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        configuration: AggregateServiceConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func submitDailyResult(
        installationID: String,
        roundID: Int,
        dateKey: String,
        score: Int?
    ) async -> Bool {
        let payload = AggregateSubmissionPayload(
            installationID: installationID,
            roundID: roundID,
            dateKey: dateKey,
            score: score,
            appVersion: appVersion,
            platform: "ios"
        )

        guard let body = try? encoder.encode(payload) else {
            return false
        }

        do {
            let request = try makeRequest(
                path: "/v1/daily-results",
                method: "POST",
                body: body
            )
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 202
        } catch {
            return false
        }
    }

    func fetchHistogram(roundID: Int) async -> AggregateHistogram? {
        do {
            let request = try makeRequest(
                path: "/v1/histograms/\(roundID)",
                method: "GET"
            )
            let (data, response) = try await session.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return nil
            }

            let decoded = try decoder.decode(AggregateHistogramResponse.self, from: data)
            return AggregateHistogram(
                roundID: decoded.roundID,
                totalSubmissions: decoded.totalSubmissions,
                buckets: decoded.buckets.map {
                    AggregateHistogramBucket(bucket: $0.bucket, count: $0.count)
                }
            )
        } catch {
            return nil
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
