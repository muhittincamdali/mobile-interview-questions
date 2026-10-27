import Foundation
import Testing
@testable import InterviewBank

@Suite("Quiz")
struct QuizTests {
    private let pool = (1...20).map { number in
        Question(id: String(format: "IOS-%03d", number), track: .ios, topic: "T", title: "Q\(number)?", level: .mid, answer: "A", location: SourceLocation(file: "f", line: number))
    }

    @Test func theSameSeedPicksTheSameQuestions() {
        let first = Quiz.pick(5, from: pool, seed: 42)
        #expect(first == Quiz.pick(5, from: pool, seed: 42))
        #expect(first != Quiz.pick(5, from: pool, seed: 43))
    }

    @Test func picksDistinctQuestionsFromThePool() {
        for seed in UInt64(0)..<200 {
            let picked = Quiz.pick(7, from: pool, seed: seed)
            #expect(picked.count == 7)
            #expect(Set(picked.map(\.id)).count == 7)
            #expect(picked.allSatisfy { pool.contains($0) })
        }
    }

    @Test(arguments: [0, -1, Int.min])
    func aCountBelowOneGivesAnEmptyQuiz(count: Int) {
        #expect(Quiz.pick(count, from: pool, seed: 1).isEmpty)
    }

    @Test func aCountAboveThePoolShufflesTheWholePool() {
        let picked = Quiz.pick(Int.max, from: pool, seed: 7)
        #expect(picked.count == pool.count)
        #expect(Set(picked) == Set(pool))
        #expect(Quiz.pick(3, from: [], seed: 7).isEmpty)
    }

    @Test func theGeneratorMatchesTheSplitMix64ReferenceValues() {
        // First outputs of SplitMix64 for seed 0, from the reference C implementation.
        var generator = SeededGenerator(seed: 0)
        #expect(generator.next() == 0xE220_A839_7B1D_CDAF)
        #expect(generator.next() == 0x6E78_9E6A_A1B9_65F4)
        #expect(generator.next() == 0x06C4_5D18_8009_454F)
    }

    @Test func everyQuestionCanBePicked() {
        var seen = Set<String>()
        for seed in UInt64(0)..<500 {
            if let first = Quiz.pick(1, from: pool, seed: seed).first { seen.insert(first.id) }
        }
        #expect(seen.count == pool.count)
    }
}
