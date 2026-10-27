import Foundation
import Testing
@testable import InterviewBank

@Suite("Question parser")
struct QuestionParserTests {
    private let sample = """
        # Swift language

        Intro text before the first question is allowed.

        ## IOS-001: What is a struct?

        **Level:** junior · **Verified by:** [ValueTests](../../Tests/AnswerTests/ValueTests.swift)

        A value type.

        ```swift
        ## Not a heading inside code
        **Reference:** [not a reference](https://example.com/inside-code)
        ```

        **Reference:** [Structures and Classes](https://docs.swift.org/swift-book/)

        ## IOS-002: What is an actor?

        **Level:** senior

        An isolated reference type.

        **References:** [Concurrency](https://docs.swift.org/a) · [SE-0306](https://github.com/swiftlang/swift-evolution/b)
        """

    @Test func readsTopicQuestionsAndMetadata() throws {
        let parsed = QuestionParser.parse(sample, track: .ios, file: "ios/swift.md")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.topic == "Swift language")
        try #require(parsed.questions.count == 2)

        let first = parsed.questions[0]
        #expect(first.id == "IOS-001")
        #expect(first.title == "What is a struct?")
        #expect(first.level == .junior)
        #expect(first.topic == "Swift language")
        #expect(first.verifiedBy == "../../Tests/AnswerTests/ValueTests.swift")
        #expect(first.references == ["https://docs.swift.org/swift-book/"])
        #expect(first.location == SourceLocation(file: "ios/swift.md", line: 5))
        #expect(first.answer.hasPrefix("A value type."))
        #expect(first.answer.contains("## Not a heading inside code"))
        #expect(first.answer.contains("inside-code"), "a reference line inside a code block stays code")

        let second = parsed.questions[1]
        #expect(second.level == .senior)
        #expect(second.verifiedBy == nil)
        #expect(second.answer == "An isolated reference type.")
        #expect(second.references == ["https://docs.swift.org/a", "https://github.com/swiftlang/swift-evolution/b"])
    }

    @Test func acceptsWindowsLineEndingsAndAByteOrderMark() {
        let text = "\u{FEFF}# Topic\r\n\r\n## RN-001: Why?\r\n\r\n**Level:** mid\r\n\r\nBecause.\r\n"
        let parsed = QuestionParser.parse(text, track: .reactNative, file: "f.md")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.topic == "Topic")
        #expect(parsed.questions.first?.answer == "Because.")
    }

    @Test(arguments: [
        "## IOS-1: Short number?",
        "## ios-001: Lower case?",
        "## IOS-0001: Four digits?",
        "## IOSXY-001: Five letters?",
        "## IOS-001 Missing colon?",
        "## IOS-001:",
        "## Just a section",
    ])
    func rejectsMalformedHeadings(heading: String) {
        let parsed = QuestionParser.parse("# T\n\n\(heading)\n\n**Level:** mid\n\nA.", track: .ios, file: "f.md")
        #expect(parsed.questions.isEmpty)
        #expect(parsed.diagnostics.map(\.location.line) == [3])
    }

    @Test(arguments: [
        ("Answer without a level line.", "must start with `**Level:**"),
        ("**Level:** expert", "unknown level `expert`"),
        ("**Level:** mid · **Tested:** [x](y)", "only `· **Verified by:**"),
        ("**Level:** mid · **Verified by:** no link", "only `· **Verified by:**"),
        ("**Level:** mid · **Verified by:** [x](y) · extra", "only `· **Verified by:**"),
    ])
    func reportsBadLevelLines(meta: String, message: String) {
        let parsed = QuestionParser.parse("# T\n\n## SD-001: Q?\n\n\(meta)\n\nA.", track: .systemDesign, file: "f.md")
        #expect(parsed.questions.isEmpty)
        #expect(parsed.diagnostics.count == 1)
        #expect(parsed.diagnostics.first?.message.contains(message) == true)
        #expect(parsed.diagnostics.first?.location.line == 5)
    }

    @Test func reportsAQuestionWithNothingAfterItsHeading() {
        let parsed = QuestionParser.parse("# T\n\n## FLT-001: Q?\n\n## FLT-002: R?\n\n**Level:** mid\n\nA.", track: .flutter, file: "f.md")
        #expect(parsed.questions.map(\.id) == ["FLT-002"])
        #expect(parsed.diagnostics.map(\.location.line) == [3])
    }

    @Test func reportsAMissingTopicAndASecondTopic() {
        let parsed = QuestionParser.parse("## AND-001: Q?\n\n**Level:** mid\n\nA.\n\n# Late topic", track: .android, file: "f.md")
        #expect(parsed.questions.count == 1)
        #expect(parsed.diagnostics.map(\.location.line) == [1, 7])
    }

    @Test func cutsALongTopicAndReportsIt() {
        let heading = String(repeating: "T", count: QuestionParser.maximumTopicLength + 1)
        let parsed = QuestionParser.parse("# \(heading)\n\n## IOS-001: Q?\n\n**Level:** mid\n\nA.", track: .ios, file: "f.md")
        #expect(parsed.topic == String(heading.dropLast()))
        #expect(parsed.questions.first?.topic == parsed.topic)
        #expect(parsed.diagnostics.map(\.message) == ["the `# ` heading is longer than 100 Unicode scalars; the topic was cut"])
        #expect(parsed.diagnostics.map(\.location.line) == [1])
    }

    /// "T" followed by combining marks is one Character however many marks follow, so a limit
    /// counted in Characters kept a heading of 520,000 marks in full.
    @Test func cutsATopicOfCombiningMarksByScalars() {
        let heading = "T" + String(repeating: "\u{0301}", count: 1_000)
        #expect(heading.count == 1)
        let parsed = QuestionParser.parse("# \(heading)\n\n## IOS-001: Q?\n\n**Level:** mid\n\nA.", track: .ios, file: "f.md")
        #expect(parsed.topic?.unicodeScalars.count == QuestionParser.maximumTopicLength)
        #expect(parsed.topic == "T" + String(repeating: "\u{0301}", count: 99))
        #expect(parsed.diagnostics.map(\.location.line) == [1])
    }

    @Test func reportsAnUnclosedCodeBlockButKeepsTheQuestion() {
        let parsed = QuestionParser.parse("# T\n\n## IOS-003: Q?\n\n**Level:** mid\n\n```swift\nlet x = 1\n## IOS-004: hidden?", track: .ios, file: "f.md")
        #expect(parsed.questions.map(\.id) == ["IOS-003"], "a heading inside the open block is code")
        #expect(parsed.diagnostics.map(\.message) == ["a code block is not closed"])
    }

    @Test func closesAFenceOnlyWithTheSameMarkerAndLength() {
        let text = "# T\n\n## IOS-005: Q?\n\n**Level:** mid\n\n````md\n```swift\n## inside\n```\n````\n\n**Reference:** [R](https://a.example/r)"
        let parsed = QuestionParser.parse(text, track: .ios, file: "f.md")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.questions.first?.answer.contains("## inside") == true)
        #expect(parsed.questions.first?.references == ["https://a.example/r"])
    }

    @Test func reportsAReferenceLineWithoutLinks() {
        let parsed = QuestionParser.parse("# T\n\n## IOS-006: Q?\n\n**Level:** mid\n\nA.\n\n**Reference:** Apple docs", track: .ios, file: "f.md")
        #expect(parsed.questions.first?.references == [])
        #expect(parsed.diagnostics.map(\.location.line) == [9])
    }

    @Test func stopsAtTheQuestionLimitOfAFile() {
        let questions = (1...5).map { "## IOS-\(String(format: "%03d", $0)): Q\($0)?\n\n**Level:** mid\n\nA." }
        let parsed = QuestionParser.parse("# T\n\n" + questions.joined(separator: "\n\n"), track: .ios, file: "f.md", maxQuestions: 3)
        #expect(parsed.questions.count == 3)
        #expect(parsed.diagnostics.count == 1)
        #expect(parsed.diagnostics.first?.message.contains("more than 3 questions") == true)
    }

    /// A file at the 1 MiB limit that is almost all blank lines. Trimming them one
    /// `removeFirst()` at a time took minutes; slicing reads the file in well under a second.
    @Test func trimsAMegabyteOfBlankLinesInLinearTime() throws {
        func parse(blankLineCount: Int) -> ParsedFile {
            let blankLines = String(repeating: "\n", count: blankLineCount)
            let text = "# T\n\n## IOS-007: Q?\n\n**Level:** mid\n" + blankLines + "A.\nB." + blankLines
            return QuestionParser.parse(text, track: .ios, file: "f.md")
        }
        var parsed: ParsedFile?
        let growth = try growthFactor(smallSize: 1 << 16) { parsed = parse(blankLineCount: $0) }
        #expect(parsed?.questions.first?.answer == "A.\nB.")
        #expect(growth < maximumLinearGrowth, "8 times the blank lines took \(growth) times as long")
    }

    /// A 1 MiB file of `# a` lines has 262,144 problems; 32 such files used 1.7 GB of memory
    /// before the number reported per file was limited.
    @Test func reportsAtMostTheDiagnosticLimitOfAFile() {
        let text = String(repeating: "# a\n", count: (1 << 20) / 4)
        let parsed = QuestionParser.parse(text, track: .ios, file: "f.md")
        let limit = BankLimits.default.maxDiagnosticsPerFile
        #expect(parsed.diagnostics.count == limit + 1)
        #expect(parsed.diagnostics.last?.message == "more than \(limit) problems in this file; the rest were not reported")
        #expect(parsed.diagnostics.last?.location.line == limit + 2, "the first problem that was not reported")
    }

    @Test func appliesASmallerDiagnosticLimitToEveryKindOfProblem() {
        let text = "# T\n\n## bad\n\n## IOS-001: Q?\n\n**Level:** expert\n\n## IOS-002: Q?\n\n**Level:** mid\n\n**Reference:** none"
        let parsed = QuestionParser.parse(text, track: .ios, file: "f.md", maxDiagnostics: 2)
        #expect(parsed.diagnostics.map(\.location.line) == [3, 7, 13])
        #expect(parsed.diagnostics.last?.message.hasPrefix("more than 2 problems") == true)
        #expect(parsed.questions.map(\.id) == ["IOS-002"], "questions are still read after the limit")
    }

    @Test func readsAnEmptyFileAsEmpty() {
        let parsed = QuestionParser.parse("", track: .ios, file: "f.md")
        #expect(parsed.topic == nil)
        #expect(parsed.questions.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test func findsLinkTargetsInALine() {
        #expect(QuestionParser.linkTargets("[a](x) and [b](y) · [c](z") == ["x", "y"])
        #expect(QuestionParser.linkTargets("no links") == [])
        #expect(QuestionParser.linkTargets("[init](https://a.example/int/init(exactly:)) · [b](y)") == ["https://a.example/int/init(exactly:)", "y"])
        #expect(QuestionParser.linkTargets("[task](<https://a.example/task(id:_:)>) and [c](z)") == ["https://a.example/task(id:_:)", "z"])
        #expect(QuestionParser.linkTargets("[open](<https://a.example/no-close") == [])
    }
}
