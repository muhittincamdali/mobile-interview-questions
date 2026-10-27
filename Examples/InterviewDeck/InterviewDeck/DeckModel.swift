import Foundation
import InterviewBank
import Observation

/// The question bank the app shows, and the current quiz.
@MainActor
@Observable
final class DeckModel {
    private(set) var bank: QuestionBank
    /// Shown instead of the list when the bundled questions could not be read.
    private(set) var loadError: String?
    var quiz: QuizSession?

    init(bank: QuestionBank, loadError: String? = nil) {
        self.bank = bank
        self.loadError = loadError
    }

    /// Loads the `questions` folder that the Xcode project copies into the app bundle.
    static func bundled(_ bundle: Bundle = .main) -> DeckModel {
        guard let folder = bundle.url(forResource: "questions", withExtension: nil) else {
            return DeckModel(bank: QuestionBank(questions: []), loadError: "The app bundle has no questions folder.")
        }
        do {
            let bank = try QuestionBank.load(from: folder)
            let problems = bank.diagnostics.map(\.description)
            return DeckModel(bank: bank, loadError: problems.isEmpty ? nil : problems.joined(separator: "\n"))
        } catch {
            return DeckModel(bank: QuestionBank(questions: []), loadError: String(describing: error))
        }
    }

    var tracks: [Track] {
        Track.allCases.filter { track in bank.questions.contains { $0.track == track } }
    }

    func count(in track: Track) -> Int {
        bank.questions.count { $0.track == track }
    }

    /// The questions of a track grouped by topic, in file order.
    func sections(in track: Track) -> [(topic: String, questions: [Question])] {
        bank.topics(in: track).map { topic in
            (topic, bank.filter(QuestionFilter(track: track, topic: topic)))
        }
    }

    func search(_ text: String) -> [Question] {
        bank.filter(QuestionFilter(search: text))
    }

    func question(id: String) -> Question? {
        bank.question(id: id)
    }

    func startQuiz(track: Track?, level: Level?, count: Int, seed: UInt64) {
        let pool = bank.filter(QuestionFilter(track: track, level: level))
        quiz = QuizSession(questions: Quiz.pick(count, from: pool, seed: seed), poolSize: pool.count, seed: seed)
    }
}

/// A running quiz: the picked questions and which answers are revealed.
struct QuizSession: Equatable {
    let questions: [Question]
    let poolSize: Int
    let seed: UInt64
    var index = 0
    var revealed: Set<String> = []

    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var isRevealed: Bool { current.map { revealed.contains($0.id) } ?? false }

    mutating func reveal() {
        if let current { revealed.insert(current.id) }
    }

    mutating func move(by offset: Int) {
        index = min(max(index + offset, 0), max(questions.count - 1, 0))
    }
}
