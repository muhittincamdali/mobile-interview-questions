import Foundation
import Testing
@testable import InterviewBank

/// Runs the linter on this repository's own `questions` folder, so a pull request that breaks the
/// format, a reference or a Verified-by link fails `swift test`.
@Suite("Repository question bank")
struct RepositoryBankTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    static let questions = root.appendingPathComponent("questions")

    @Test func theBankHasNoLintProblems() throws {
        let bank = try QuestionBank.load(from: Self.questions)
        let problems = BankLinter(questionsFolder: Self.questions, repositoryRoot: Self.root).lint(bank)
        #expect(problems.isEmpty, "\(problems.map(\.description).joined(separator: "\n"))")
        for track in Track.allCases {
            #expect(bank.questions.contains { $0.track == track }, "no questions in \(track.rawValue)")
        }
    }

    @Test func everyVerifiedAnswerPointsAtATestFolder() throws {
        let bank = try QuestionBank.load(from: Self.questions)
        let testFolders = ["../../Tests/AnswerTests/", "../../answers/flutter/test/", "../../answers/react-native/test/"]
        for question in bank.questions {
            guard let target = question.verifiedBy else { continue }
            #expect(testFolders.contains { target.hasPrefix($0) }, "\(question.id) links to \(target)")
        }
    }

    /// The topic table in questions/README.md must list every file with its real count.
    @Test func theTopicIndexMatchesTheFiles() throws {
        let bank = try QuestionBank.load(from: Self.questions)
        let index = try String(contentsOf: Self.questions.appendingPathComponent("README.md"), encoding: .utf8)
        // Rows look like `| iOS | [Swift language](ios/swift-language.md) | 15 |`, padded or not.
        var listed: [String: (topic: String, count: String)] = [:]
        for line in index.split(separator: "\n") where line.hasPrefix("|") {
            let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count == 3, let file = QuestionParser.linkTargets(Substring(cells[1])).first else { continue }
            let topic = cells[1].dropFirst().prefix { $0 != "]" }
            listed[file] = (String(topic), cells[2])
        }
        let byFile = Dictionary(grouping: bank.questions, by: \.location.file)
        #expect(!byFile.isEmpty)
        #expect(Set(listed.keys) == Set(byFile.keys), "questions/README.md must list exactly the topic files")
        for (file, questions) in byFile {
            #expect(listed[file]?.topic == questions[0].topic, "\(file): the index shows another title")
            #expect(listed[file]?.count == String(questions.count), "\(file) has \(questions.count) questions")
        }
    }

    /// The README states the number of questions and verified answers; keep it honest.
    @Test func theReadmeCountsMatchTheBank() throws {
        let bank = try QuestionBank.load(from: Self.questions)
        let readme = try String(contentsOf: Self.root.appendingPathComponent("README.md"), encoding: .utf8)
        let verified = bank.questions.count { $0.verifiedBy != nil }
        #expect(readme.contains("\(bank.questions.count) questions"), "README.md should say \(bank.questions.count) questions")
        #expect(readme.contains("\(verified) answers"), "README.md should say \(verified) answers")
    }
}
