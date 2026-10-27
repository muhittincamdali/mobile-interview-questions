import Foundation
import Testing
@testable import InterviewCLI

@Suite("interview command")
struct InterviewToolTests {
    /// A repository with three questions, removed after the test.
    final class Fixture {
        let root: URL
        let tool: InterviewTool

        init(extra: [String: String] = [:]) throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent("InterviewCLITests-\(UUID().uuidString)")
            var files = [
                "questions/ios/swift.md": """
                    # Swift language

                    ## IOS-001: What is a struct?

                    **Level:** junior · **Verified by:** [T](../../Tests/T.swift)

                    A value type.

                    **Reference:** [Swift](https://docs.swift.org/swift-book/)

                    ## IOS-002: What is an actor?

                    **Level:** senior

                    A reference type that isolates its state.

                    **Reference:** [Swift](https://docs.swift.org/swift-book/)
                    """,
                "questions/flutter/widgets.md": """
                    # Widgets

                    ## FLT-001: What is a Key?

                    **Level:** mid

                    It keeps an element's identity.

                    **Reference:** [Key](https://api.flutter.dev/flutter/foundation/Key-class.html)
                    """,
                "Tests/T.swift": "@Test(\"IOS-001: copies\") func copies() {}",
            ]
            files.merge(extra) { $1 }
            for (path, text) in files {
                let url = root.appendingPathComponent(path)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(text.utf8).write(to: url)
            }
            tool = InterviewTool(currentDirectory: root, makeSeed: { 99 })
        }

        deinit { try? FileManager.default.removeItem(at: root) }

        /// Runs the tool while the fixture, and so its folder, is alive.
        func run(_ arguments: [String]) -> ToolOutput {
            tool.run(arguments)
        }
    }

    @Test func listsQuestionsInAlignedColumns() throws {
        let output = try Fixture().run(["list", "--track", "ios"])
        #expect(output.status == 0)
        #expect(output.standardOutput == """
            IOS-001  junior  Swift language  What is a struct?
            IOS-002  senior  Swift language  What is an actor?

            2 questions

            """)
    }

    @Test func listFailsWhenNothingMatches() throws {
        let output = try Fixture().run(["list", "--track", "android"])
        #expect(output.status == 1)
        #expect(output.standardError == "No questions match these filters.\n")
    }

    @Test func showsOneQuestionWithItsAnswerAndSources() throws {
        let output = try Fixture().run(["show", "ios-001"])
        #expect(output.status == 0)
        #expect(output.standardOutput.hasPrefix("IOS-001: What is a struct?\niOS · Swift language · junior\n\nA value type.\n"))
        #expect(output.standardOutput.contains("References:\n  https://docs.swift.org/swift-book/\nVerified by: ../../Tests/T.swift"))
    }

    @Test func showReportsAnUnknownID() throws {
        let output = try Fixture().run(["show", "IOS-999"])
        #expect(output.status == 1)
        #expect(output.standardError.contains("No question with the ID `IOS-999`"))
    }

    @Test func aSeededQuizRepeatsAndCanPrintAnswers() throws {
        let fixture = try Fixture()
        let first = fixture.run(["quiz", "--count", "2", "--seed", "7"])
        let again = fixture.run(["quiz", "--count", "2", "--seed", "7"])
        #expect(first == again)
        #expect(first.standardOutput.hasPrefix("Quiz: 2 of 3 questions · seed 7\n"))
        #expect(first.standardOutput.contains("repeat with --seed 7 --answers"))
        #expect(!first.standardOutput.contains("A value type."))

        let withAnswers = fixture.run(["quiz", "--count", "50", "--seed", "7", "--answers"])
        #expect(withAnswers.standardOutput.hasPrefix("Quiz: 3 of 3 questions · seed 7\n"))
        #expect(withAnswers.standardOutput.contains("A value type."))
        #expect(withAnswers.standardOutput.contains("It keeps an element's identity."))
    }

    @Test func aQuizWithoutASeedPrintsTheSeedItUsed() throws {
        let output = try Fixture().run(["quiz", "--track", "flutter"])
        #expect(output.standardOutput.hasPrefix("Quiz: 1 of 1 questions · seed 99\n"))
        #expect(output.standardOutput.contains("1. [FLT-001 · mid · Widgets] What is a Key?"))
    }

    @Test func statsCountsPerTrackAndLevel() throws {
        let output = try Fixture().run(["stats"])
        #expect(output.status == 0)
        #expect(output.standardOutput == """
            Track    junior  mid  senior  total
            iOS      1       0    1       2
            Flutter  0       1    0       1
            All      1       1    1       3

            1 of 3 answers have code checked by a test

            """)
    }

    @Test func lintPassesACleanBankAndFailsABrokenOne() throws {
        let clean = try Fixture().run(["lint"])
        #expect(clean.status == 0)
        #expect(clean.standardOutput == "3 questions, 0 problems\n")

        let broken = try Fixture(extra: ["questions/android/a.md": "# A\n\n## AND-001: Q?\n\n**Level:** mid\n\nNo source.\n"]).run(["lint"])
        #expect(broken.status == 1)
        #expect(broken.standardOutput == "android/a.md:3: AND-001 needs a **Reference:** line with a primary source\n4 questions, 1 problem\n")
    }

    @Test func readsAnotherFolderWithBank() throws {
        let fixture = try Fixture()
        let moved = fixture.root.appendingPathComponent("copy")
        try FileManager.default.copyItem(at: fixture.root.appendingPathComponent("questions"), to: moved)
        let output = InterviewTool(currentDirectory: fixture.root.appendingPathComponent("Tests")).run(["stats", "--bank", "../copy"])
        #expect(output.status == 0)
        #expect(output.standardOutput.contains("All      1       1    1       3"))
    }

    @Test func aMissingBankExplainsWhatToDo() throws {
        let output = InterviewTool(currentDirectory: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)")).run(["list"])
        #expect(output.status == 2)
        #expect(output.standardError.contains("Run the command from the repository root or pass --bank <folder>."))
    }

    @Test(arguments: [[], ["--help"], ["help"], ["quiz", "-h"]])
    func printsUsage(arguments: [String]) throws {
        let output = try Fixture().run(arguments)
        #expect(output.status == 0)
        #expect(output.standardOutput.hasPrefix("Usage: interview <command> [options]"))
    }

    @Test(arguments: [
        (["quiz", "--count", "0"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--count", "51"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--count", "-3"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--count", "1e3"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--count", "nan"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--count", "99999999999999999999999"], "--count must be a whole number from 1 to 50"),
        (["quiz", "--seed", "-1"], "--seed must be a whole number"),
        (["quiz", "--seed", "18446744073709551616"], "--seed must be a whole number"),
        (["quiz", "--count"], "--count needs a value"),
        (["quiz", "--count", "--seed"], "--count needs a value"),
        (["list", "--track", "kotlin"], "unknown track `kotlin`"),
        (["list", "--level", "lead"], "unknown level `lead`"),
        (["list", "--count", "3"], "--count does not work with `list`"),
        (["list", "--answers"], "--answers only works with `quiz`"),
        (["list", "--verbose"], "unknown option `--verbose`"),
        (["list", "extra"], "unexpected argument `extra`"),
        (["show"], "`show` needs a question ID"),
        (["show", "IOS-001", "IOS-002"], "unexpected argument `IOS-002`"),
        (["serve"], "unknown command `serve`"),
    ])
    func rejectsBadCommandLines(arguments: [String], message: String) throws {
        let output = try Fixture().run(arguments)
        #expect(output.status == 2)
        #expect(output.standardOutput.isEmpty)
        #expect(output.standardError.hasPrefix("error: \(message)"))
    }
}
