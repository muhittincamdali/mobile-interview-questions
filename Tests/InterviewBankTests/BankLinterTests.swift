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
        #expect(BankLinter.questionIDs(in: "@Test(\"IOS-001: x\")") == ["IOS-001"])
        #expect(BankLinter.questionIDs(in: "IOS-001") == ["IOS-001"])
        #expect(!BankLinter.questionIDs(in: "IOS-0011 XIOS-001 IOS-001-b -IOS-001 IOS-001x").contains("IOS-001"))
        #expect(BankLinter.questionIDs(in: "IOS-0011 then (IOS-001), test_FLT-002_case") == ["IOS-001", "FLT-002"])
    }

    /// Before the IDs were collected once per file, 1000 questions linking a 1 MiB test file took
    /// about 14 seconds in a release build, because the file was searched again for each question.
    @Test func scansALinkedTestFileOncePerFile() throws {
        // The file and the number of questions that link it grow together: a search of the file
        // for every question makes the work quadratic in `scale`.
        func lintLinkedQuestions(scale: Int) throws -> [Diagnostic] {
            let filler = String(repeating: "// padding line without question IDs\n", count: 3_375 * scale)
            let ids = (0..<(125 * scale)).map { String(format: "IOS-%03d", $0) }
            var files = ["Tests/Big.swift": filler + ids.map { "@Test(\"\($0)\") func t() {}" }.joined(separator: "\n")]
            let middle = ids.count / 2
            for (half, slice) in [ids[..<middle], ids[middle...]].enumerated() {
                let meta = " · **Verified by:** [T](../../Tests/Big.swift)"
                files["questions/ios/\(half).md"] = "# T\n\n" + slice.map { TemporaryFolder.question($0, meta: meta) }.joined(separator: "\n")
            }
            #expect(files["Tests/Big.swift"]!.utf8.count < BankLimits.default.maxFileBytes)
            return try lint(files)
        }

        var diagnostics: [Diagnostic] = []
        let growth = try growthFactor(smallSize: 1) { diagnostics = try lintLinkedQuestions(scale: $0) }
        #expect(diagnostics.isEmpty)
        #expect(growth < maximumLinearGrowth, "8 times the questions took \(growth) times as long")
    }

    @Test func sharesTheDiagnosticLimitOfAFileWithTheLoader() throws {
        let folder = try TemporaryFolder()
        // One format problem from the loader, then two content problems for each question.
        let questions = (1...10).map { TemporaryFolder.question(String(format: "FLT-%03d", $0), answer: " ") }
        try folder.write("questions/ios/a.md", "# A\n\n## bad\n\n" + questions.joined(separator: "\n"))
        try folder.write("questions/ios/b.md", "# B\n\n" + TemporaryFolder.question("IOS-001", answer: " "))
        let questionsFolder = folder.url.appendingPathComponent("questions")
        let limits = BankLimits(maxFileBytes: 1 << 20, maxFiles: 10, maxQuestionsPerFile: 50, maxDiagnosticsPerFile: 4)
        let bank = try QuestionBank.load(from: questionsFolder, limits: limits)

        let diagnostics = BankLinter(questionsFolder: questionsFolder, repositoryRoot: folder.url, limits: limits).lint(bank)

        #expect(diagnostics.filter { $0.location.file == "ios/a.md" }.count == 5)
        #expect(diagnostics.last { $0.location.file == "ios/a.md" }?.message == "more than 4 problems in this file; the rest were not reported")
        #expect(diagnostics.filter { $0.location.file == "ios/b.md" }.map(\.message) == ["IOS-001 has no answer"])
    }

    @Test(arguments: [0, -1])
    func reportsThatProblemsWereHiddenWhenTheLimitIsZeroOrNegative(limit: Int) throws {
        let folder = try TemporaryFolder()
        try folder.write("questions/ios/a.md", "# A\n\n" + TemporaryFolder.question("IOS-001", answer: " "))
        let questionsFolder = folder.url.appendingPathComponent("questions")
        let limits = BankLimits(maxFileBytes: 1 << 20, maxFiles: 10, maxQuestionsPerFile: 50, maxDiagnosticsPerFile: limit)
        let bank = try QuestionBank.load(from: questionsFolder, limits: limits)

        let diagnostics = BankLinter(questionsFolder: questionsFolder, repositoryRoot: folder.url, limits: limits).lint(bank)

        #expect(diagnostics.map(\.message) == ["more than 0 problems in this file; the rest were not reported"])
    }
}
