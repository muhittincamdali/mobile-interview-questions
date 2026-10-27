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
        let filler = String(repeating: "// padding line without question IDs\n", count: 27_000)
        let ids = (0..<1000).map { String(format: "IOS-%03d", $0) }
        var files = ["Tests/Big.swift": filler + ids.map { "@Test(\"\($0)\") func t() {}" }.joined(separator: "\n")]
        for (half, slice) in [ids[..<500], ids[500...]].enumerated() {
            let meta = " · **Verified by:** [T](../../Tests/Big.swift)"
            files["questions/ios/\(half).md"] = "# T\n\n" + slice.map { TemporaryFolder.question($0, meta: meta) }.joined(separator: "\n")
        }
        #expect(files["Tests/Big.swift"]!.utf8.count < BankLimits.default.maxFileBytes)

        let clock = ContinuousClock()
        var diagnostics: [Diagnostic] = []
        let elapsed = try clock.measure { diagnostics = try lint(files) }
        #expect(diagnostics.isEmpty)
        #expect(elapsed < .seconds(5), "lint took \(elapsed)")
    }
}
