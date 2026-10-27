import Foundation
import Testing
@testable import InterviewCLI

/// The README and the Getting Started article show real output of seeded quizzes. These tests run
/// the same commands on this repository's questions, so the documents fail CI when the bank
/// changes the output instead of silently going stale.
@Suite("Documented output")
struct DocumentedOutputTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func expectDocument(_ path: String, toShowOutputOf arguments: [String]) throws {
        let document = try String(contentsOf: Self.root.appendingPathComponent(path), encoding: .utf8)
        let output = InterviewTool(currentDirectory: Self.root).run(arguments)
        #expect(output.status == 0)
        let lines = output.standardOutput.split(separator: "\n").map(String.init)
        #expect(lines.count > 3)
        for line in lines {
            #expect(document.contains(line), "\(path) is missing this output line: \(line)")
        }
        #expect(document.contains("$ swift run interview \(arguments.joined(separator: " "))"))
    }

    @Test func theReadmeQuizIsRealOutput() throws {
        try expectDocument("README.md", toShowOutputOf: ["quiz", "--track", "ios", "--level", "senior", "--count", "3", "--seed", "7"])
    }

    @Test func theGettingStartedQuizIsRealOutput() throws {
        try expectDocument(
            "Sources/InterviewBank/InterviewBank.docc/GettingStarted.md",
            toShowOutputOf: ["quiz", "--track", "flutter", "--count", "3", "--seed", "42"]
        )
    }
}
