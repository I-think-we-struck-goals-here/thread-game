import Foundation

enum ThreadRepositoryError: LocalizedError {
    case missingResource(String)
    case invalidResource(String, String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing bundled resource: \(name)"
        case .invalidResource(let name, let reason):
            return "Invalid bundled resource \(name): \(reason)"
        }
    }
}

struct ThreadRepository {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.decoder = JSONDecoder()
    }

    func loadPracticeRounds() throws -> [ThreadRound] {
        try decode(fileName: "practice-rounds")
    }

    func loadDailyRounds() throws -> [ThreadRound] {
        try decode(fileName: "daily-rounds")
    }

    private func decode(fileName: String) throws -> [ThreadRound] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw ThreadRepositoryError.missingResource(fileName)
        }

        let data = try Data(contentsOf: url)
        let rounds = try decoder.decode([ThreadRound].self, from: data)
        try ThreadRoundValidator.validate(rounds, sourceName: fileName)
        return rounds
    }
}

enum ThreadRoundValidator {
    static func validate(_ rounds: [ThreadRound], sourceName: String) throws {
        guard !rounds.isEmpty else {
            throw ThreadRepositoryError.invalidResource(sourceName, "no rounds found")
        }

        var seenIDs = Set<Int>()

        for round in rounds {
            if round.id <= 0 {
                throw ThreadRepositoryError.invalidResource(sourceName, "round ID must be positive: \(round.id)")
            }

            if !seenIDs.insert(round.id).inserted {
                throw ThreadRepositoryError.invalidResource(sourceName, "duplicate round ID \(round.id)")
            }

            if round.sourcePool.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) has empty sourcePool")
            }

            let normalizedAnswer = GuessNormalizer.normalize(round.answer)
            if normalizedAnswer.isEmpty {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) has empty answer")
            }

            let normalizedAcceptedAnswers = round.acceptedAnswers
                .map(GuessNormalizer.normalize)
                .filter { !$0.isEmpty }

            if normalizedAcceptedAnswers.isEmpty {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) has no accepted answers")
            }

            if Set(normalizedAcceptedAnswers).count != normalizedAcceptedAnswers.count {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) has duplicate accepted answers")
            }

            if !Set(normalizedAcceptedAnswers).contains(normalizedAnswer) {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) answer is not in accepted answers")
            }

            if round.clues.count != 5 {
                throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) does not have exactly 5 clues")
            }

            var seenClueWords = Set<String>()

            for (index, clue) in round.clues.enumerated() {
                let word = GuessNormalizer.normalize(clue.word)
                if word.isEmpty {
                    throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) clue \(index + 1) has empty word")
                }

                if !seenClueWords.insert(word).inserted {
                    throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) has duplicate clue word \(word)")
                }

                if clue.connection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw ThreadRepositoryError.invalidResource(sourceName, "round \(round.id) clue \(index + 1) has empty connection")
                }
            }
        }
    }
}
