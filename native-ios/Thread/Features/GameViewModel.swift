import SwiftUI

enum GuessSubmissionOutcome: Equatable {
    case ignored
    case alreadyComplete(Int?)
    case solved(Int)
    case revealedNextClue
    case duplicate
    case failed
}

struct RoundFeedback: Equatable {
    enum Tone: Equatable {
        case neutral
        case warning
    }

    let text: String
    let tone: Tone
}

@MainActor
final class ThreadGameViewModel: ObservableObject {
    let round: ThreadRound
    let resumedFromSavedProgress: Bool
    private let dateKey: String?
    private let persistSnapshot: (GameSnapshot) -> Void
    private let startedAt: Date
    private var firstSubmittedGuessAt: Date?

    @Published var guess: String
    @Published private(set) var attempts: [String]
    @Published private(set) var revealedClueCount: Int
    @Published private(set) var isSolved: Bool
    @Published private(set) var isFailed: Bool
    @Published private(set) var feedback: RoundFeedback?

    init(
        round: ThreadRound,
        dateKey: String? = nil,
        snapshot: GameSnapshot? = nil,
        persistSnapshot: @escaping (GameSnapshot) -> Void = { _ in }
    ) {
        self.round = round
        self.dateKey = dateKey
        self.persistSnapshot = persistSnapshot

        let restoredSnapshot = snapshot
        let snapshot = snapshot ?? .initial(roundID: round.id, dateKey: dateKey)
        self.guess = snapshot.guess
        self.attempts = snapshot.attempts
        self.revealedClueCount = max(1, min(snapshot.revealedClueCount, round.clues.count))
        self.isSolved = snapshot.isSolved
        self.isFailed = snapshot.isFailed
        self.feedback = nil
        self.startedAt = snapshot.startedAt ?? .now
        self.firstSubmittedGuessAt = snapshot.firstSubmittedGuessAt
        self.resumedFromSavedProgress = restoredSnapshot != nil && (
            !snapshot.attempts.isEmpty
            || snapshot.revealedClueCount > 1
            || !snapshot.guess.isEmpty
            || snapshot.isSolved
            || snapshot.isFailed
        )
    }

    var visibleClues: [RoundClue] {
        Array(round.clues.prefix(revealedClueCount))
    }

    var isComplete: Bool {
        isSolved || isFailed
    }

    var score: Int? {
        isSolved ? revealedClueCount : nil
    }

    func submitGuess() -> GuessSubmissionOutcome {
        let normalizedGuess = GuessNormalizer.normalize(guess)
        guard !normalizedGuess.isEmpty else { return .ignored }
        guard !isComplete else { return .alreadyComplete(score) }

        if attempts.contains(normalizedGuess) {
            withAnimation(ThreadMotion.defaultSpring) {
                feedback = RoundFeedback(
                    text: "You already tried \(normalizedGuess). Try a new angle.",
                    tone: .warning
                )
            }
            return .duplicate
        }

        withAnimation(ThreadMotion.defaultSpring) {
            if firstSubmittedGuessAt == nil {
                firstSubmittedGuessAt = .now
            }

            if round.normalizedAcceptedAnswers.contains(normalizedGuess) {
                isSolved = true
                feedback = nil
            } else {
                attempts.append(normalizedGuess)
                guess = ""

                if revealedClueCount < round.clues.count {
                    revealedClueCount += 1
                    feedback = nil
                } else {
                    isFailed = true
                    feedback = nil
                }
            }
        }

        persist()

        if let score {
            return .solved(score)
        }

        return isFailed ? .failed : .revealedNextClue
    }

    func currentSnapshot() -> GameSnapshot {
        GameSnapshot(
            roundID: round.id,
            dateKey: dateKey,
            revealedClueCount: revealedClueCount,
            guess: guess,
            attempts: attempts,
            isSolved: isSolved,
            isFailed: isFailed,
            startedAt: startedAt,
            firstSubmittedGuessAt: firstSubmittedGuessAt,
            updatedAt: .now
        )
    }

    func completionSummary(now: Date = .now) -> ThreadRoundCompletion {
        let elapsed = max(0, Int(now.timeIntervalSince(startedAt)))
        let timeToFirstGuess = firstSubmittedGuessAt.map { max(0, Int($0.timeIntervalSince(startedAt))) }
        return ThreadRoundCompletion(
            score: score,
            cluesUsed: revealedClueCount,
            wrongGuessCount: attempts.count,
            totalGuessCount: attempts.count + (score == nil ? 0 : 1),
            solveDurationSeconds: elapsed,
            timeToFirstGuessSeconds: timeToFirstGuess,
            resumedSavedProgress: resumedFromSavedProgress
        )
    }

    func persist() {
        guard dateKey != nil else { return }
        persistSnapshot(currentSnapshot())
    }

    func clearFeedbackForActiveEditing() {
        guard feedback != nil else { return }
        guard !GuessNormalizer.normalize(guess).isEmpty else { return }

        withAnimation(.easeOut(duration: 0.16)) {
            feedback = nil
        }
    }
}
