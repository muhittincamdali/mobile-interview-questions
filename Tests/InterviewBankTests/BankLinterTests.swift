import Foundation
import Testing
@testable import InterviewBank

@Suite("Linter")
struct BankLinterTests {
    private func lint(_ files: [String: String]) throws -> [Diagnostic] {
        let folder = try TemporaryFolder()
        for (path, text) in files { try folder.write(path, text) }
        let questions = folder.url.appendingPathComponent("questions")
        let bank = try QuestionBank.load(from: questions)
        return BankLinter(questionsFolder: questions, repositoryRoot: folder.url).lint(bank)
    }

    @Test func acceptsAValidBank() throws {
        let diagnostics = try lint([
            "questions/ios/a.md": "# A\n\n" + TemporaryFolder.question("IOS-001", meta: " · **Verified by:** [T](../../Tests/T.swift)"),
            "questions/behavioral/b.md": "# B\n\n" + TemporaryFolder.question("BHV-001", reference: nil),
            "Tests/T.swift": "@Test(\"IOS-001: checks it\") func check() {}",
        ])
        #expect(diagnostics.isEmpty)
    }

    @Test func reportsDuplicateIDsAcrossFiles() throws {
        let diagnostics = try lint([
            "questions/ios/a.md": "# A\n\n" + TemporaryFolder.question("IOS-001"),
            "questions/ios/b.md": "# B\n\n" + TemporaryFolder.question("IOS-001"),
        ])
        #expect(diagnostics.map(\.message) == ["IOS-001 is already used at ios/a.md:3"])
        #expect(diagnostics.first?.location.file == "ios/b.md")
    }

    @Test func reportsAnIDFromAnotherTrack() throws {
        let diagnostics = try lint(["questions/flutter/a.md": "# A\n\n" + TemporaryFolder.question("IOS-001")])
        #expect(diagnostics.map(\.message) == ["IOS-001 is in the flutter track, so its ID must start with FLT-"])
    }

    @Test func requiresAnAnswerAndAReferenceForTechnicalTracks() throws {
        let diagnostics = try lint([
            "questions/android/a.md": "# A\n\n## AND-001: Q?\n\n**Level:** mid\n",
        ])
        #expect(diagnostics.map(\.message) == [
            "AND-001 has no answer",
            "AND-001 needs a **Reference:** line with a primary source",
        ])
    }

    @Test(arguments: ["http://developer.android.com/x", "ftp://a.example/x", "developer.android.com", "https://", "https://a.example/with space"])
    func rejectsReferencesThatAreNotHTTPS(reference: String) throws {
        let diagnostics = try lint(["questions/android/a.md": "# A\n\n" + TemporaryFolder.question("AND-001", reference: reference)])
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.message.contains("must be an https URL") == true)
    }

    @Test func reportsAVerificationFileThatIsMissingOrDoesNotNameTheQuestion() throws {
        let diagnostics = try lint([
            "questions/ios/a.md": "# A\n\n"
                + TemporaryFolder.question("IOS-001", meta: " · **Verified by:** [T](../../Tests/Missing.swift)") + "\n"
                + TemporaryFolder.question("IOS-002", meta: " · **Verified by:** [T](../../Tests/T.swift)"),
            "Tests/T.swift": "// checks IOS-0021 and XIOS-002, but not the question itself",
        ])
        #expect(diagnostics.map(\.message) == [
            "IOS-001: **Verified by** file `../../Tests/Missing.swift` does not exist or cannot be read",
            "IOS-002: `../../Tests/T.swift` has no test named after IOS-002",
        ])
    }

    @Test(arguments: ["../../../outside.swift", "/etc/hosts", "https://example.com/T.swift"])
    func rejectsVerificationLinksOutsideTheRepository(target: String) throws {
        let diagnostics = try lint(["questions/ios/a.md": "# A\n\n" + TemporaryFolder.question("IOS-001", meta: " · **Verified by:** [T](\(target))")])
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first.map { $0.message.contains("outside the repository") || $0.message.contains("relative path") } == true)
    }

    @Test func matchesIDsOnlyAsWholeWords() {
        #expect(BankLinter.mentions("@Test(\"IOS-001: x\")", id: "IOS-001"))
        #expect(BankLinter.mentions("IOS-001", id: "IOS-001"))
        #expect(!BankLinter.mentions("IOS-0011 XIOS-001 IOS-001-b", id: "IOS-001"))
        #expect(BankLinter.mentions("IOS-0011 then (IOS-001)", id: "IOS-001"))
    }
}

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

@Suite("Answer blocks")
struct AnswerBlockTests {
    @Test func splitsProseAndCodeInOrder() {
        let blocks = AnswerBlock.split("First paragraph.\n\n```swift\nlet a = 1\n\nlet b = 2\n```\n\n- a list\n\n~~~\nplain\n~~~")
        #expect(blocks == [
            .text("First paragraph."),
            .code(language: "swift", source: "let a = 1\n\nlet b = 2"),
            .text("- a list"),
            .code(language: nil, source: "plain"),
        ])
    }

    @Test func keepsAnUnclosedBlockAsCode() {
        #expect(AnswerBlock.split("Intro\n```kotlin\nval x = 1") == [.text("Intro"), .code(language: "kotlin", source: "val x = 1")])
    }

    @Test func keepsInnerFencesInsideALongerFence() {
        #expect(AnswerBlock.split("````md\n```swift\nx\n```\n````") == [.code(language: "md", source: "```swift\nx\n```")])
    }

    @Test func readsPipeTablesWithAlignmentAndPaddingRows() {
        let blocks = AnswerBlock.split("Before.\n\n| Tool | Use |\n| :--- | ---: |\n| `a \\| b` | x |\n| c |\n\nAfter.")
        #expect(blocks == [
            .text("Before."),
            .table(header: ["Tool", "Use"], rows: [["`a | b`", "x"], ["c", ""]]),
            .text("After."),
        ])
    }

    @Test func keepsBackslashesThatDoNotEscapeAPipe() {
        #expect(AnswerBlock.cells("| a\\*b | c\\ |") == ["a\\*b", "c\\"])
    }

    @Test func keepsPipesWithoutASeparatorRowAsProse() {
        #expect(AnswerBlock.split("| not | a table |\nnext line") == [.text("| not | a table |\nnext line")])
        #expect(AnswerBlock.split("| a | b |\n| --- |") == [.text("| a | b |\n| --- |")], "column counts must match")
    }

    @Test func dropsBlankProse() {
        #expect(AnswerBlock.split("\n\n   \n").isEmpty)
    }
}
