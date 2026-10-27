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
