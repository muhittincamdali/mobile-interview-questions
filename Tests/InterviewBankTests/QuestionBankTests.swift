import Foundation
import Testing
@testable import InterviewBank

@Suite("Loading the bank")
struct QuestionBankTests {
    @Test func loadsTracksInNameOrderAndSkipsOtherFiles() throws {
        let folder = try TemporaryFolder()
        try folder.write("questions/ios/b-second.md", "# Second\n\n" + TemporaryFolder.question("IOS-002"))
        try folder.write("questions/ios/a-first.md", "# First\n\n" + TemporaryFolder.question("IOS-001"))
        try folder.write("questions/flutter/dart.md", "# Dart\n\n" + TemporaryFolder.question("FLT-001"))
        try folder.write("questions/ios/notes.txt", "not markdown")
        try folder.write("questions/README.md", "# Index")
        try folder.write("questions/.hidden/x.md", "# Hidden\n\n" + TemporaryFolder.question("IOS-099"))

        let bank = try QuestionBank.load(from: folder.url.appendingPathComponent("questions"))

        #expect(bank.diagnostics.isEmpty)
        #expect(bank.questions.map(\.id) == ["FLT-001", "IOS-001", "IOS-002"])
        #expect(bank.questions.map(\.location.file) == ["flutter/dart.md", "ios/a-first.md", "ios/b-second.md"])
        #expect(bank.topics(in: .ios) == ["First", "Second"])
    }

    @Test func throwsForAMissingFolder() throws {
        let folder = try TemporaryFolder()
        let missing = folder.url.appendingPathComponent("nope")
        #expect(throws: BankError.folderNotFound(missing.path)) {
            try QuestionBank.load(from: missing)
        }
    }

    @Test func reportsFoldersThatAreNotTracks() throws {
        let folder = try TemporaryFolder()
        try folder.write("questions/kotlin/k.md", "# K\n\n" + TemporaryFolder.question("AND-001"))
        let bank = try QuestionBank.load(from: folder.url.appendingPathComponent("questions"))
        #expect(bank.questions.isEmpty)
        #expect(bank.diagnostics.count == 1)
        #expect(bank.diagnostics.first?.message.contains("`kotlin` is not a track folder") == true)
    }

    @Test func skipsFilesOverTheSizeLimit() throws {
        let folder = try TemporaryFolder()
        let small = "# S\n\n" + TemporaryFolder.question("IOS-001")
        try folder.write("questions/ios/a.md", small)
        try folder.write("questions/ios/b.md", "# Big\n\n" + TemporaryFolder.question("IOS-002", answer: String(repeating: "x", count: 4_000)))
        let limits = BankLimits(maxFileBytes: small.utf8.count, maxFiles: 10, maxQuestionsPerFile: 10)

        let bank = try QuestionBank.load(from: folder.url.appendingPathComponent("questions"), limits: limits)

        #expect(bank.questions.map(\.id) == ["IOS-001"], "a file of exactly the limit is still read")
        #expect(bank.diagnostics.map(\.location.file) == ["ios/b.md"])
    }

    @Test func stopsAtTheFileLimit() throws {
        let folder = try TemporaryFolder()
        for number in 1...4 {
            try folder.write("questions/ios/\(number).md", "# T\(number)\n\n" + TemporaryFolder.question(String(format: "IOS-%03d", number)))
        }
        let limits = BankLimits(maxFileBytes: 1 << 20, maxFiles: 2, maxQuestionsPerFile: 10)
        let bank = try QuestionBank.load(from: folder.url.appendingPathComponent("questions"), limits: limits)
        #expect(bank.questions.count == 2)
        #expect(bank.diagnostics.count == 1)
        #expect(bank.diagnostics.first?.message.contains("more than 2 question files") == true)
    }

    @Test func skipsSymbolicLinksAndInvalidText() throws {
        let folder = try TemporaryFolder()
        let outside = try folder.write("outside.md", "# Outside\n\n" + TemporaryFolder.question("IOS-050"))
        try FileManager.default.createDirectory(at: folder.url.appendingPathComponent("questions/ios"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: folder.url.appendingPathComponent("questions/ios/link.md"), withDestinationURL: outside)
        try Data([0x23, 0x20, 0xFF, 0xFE, 0x0A]).write(to: folder.url.appendingPathComponent("questions/ios/binary.md"))

        let bank = try QuestionBank.load(from: folder.url.appendingPathComponent("questions"))

        #expect(bank.questions.isEmpty)
        #expect(Set(bank.diagnostics.map(\.location.file)) == ["ios/binary.md", "ios/link.md"])
    }

    @Test(arguments: [-1, Int.max])
    func readTextRejectsLimitsThatCannotBeRead(limit: Int) throws {
        let folder = try TemporaryFolder()
        let file = try folder.write("a.md", "text")
        #expect(QuestionBank.readText(at: file, limit: limit) == nil)
    }

    @Test func readTextReadsAnEmptyFile() throws {
        let folder = try TemporaryFolder()
        let file = try folder.write("empty.md", "")
        #expect(QuestionBank.readText(at: file, limit: 10) == "")
    }
}

@Suite("Filtering")
struct QuestionFilterTests {
    private let bank = QuestionBank(questions: [
        Question(id: "IOS-001", track: .ios, topic: "Swift language", title: "What is a struct?", level: .junior, answer: "A value type.", location: SourceLocation(file: "a", line: 1)),
        Question(id: "IOS-002", track: .ios, topic: "Swift concurrency", title: "What is an actor?", level: .senior, answer: "Isolation for mutable state.", location: SourceLocation(file: "a", line: 2)),
        Question(id: "FLT-001", track: .flutter, topic: "Widgets", title: "What is a Key?", level: .mid, answer: "Identity for an element. Café.", location: SourceLocation(file: "b", line: 1)),
    ])

    @Test func combinesFilters() {
        #expect(bank.filter(QuestionFilter(track: .ios)).map(\.id) == ["IOS-001", "IOS-002"])
        #expect(bank.filter(QuestionFilter(track: .ios, level: .senior)).map(\.id) == ["IOS-002"])
        #expect(bank.filter(QuestionFilter(topic: "swift LANGUAGE")).map(\.id) == ["IOS-001"])
        #expect(bank.filter(QuestionFilter(track: .flutter, level: .junior)).isEmpty)
    }

    @Test func searchesIDsTitlesAndAnswersIgnoringCaseAndAccents() {
        #expect(bank.filter(QuestionFilter(search: "ACTOR")).map(\.id) == ["IOS-002"])
        #expect(bank.filter(QuestionFilter(search: "value type")).map(\.id) == ["IOS-001"])
        #expect(bank.filter(QuestionFilter(search: "cafe")).map(\.id) == ["FLT-001"])
        #expect(bank.filter(QuestionFilter(search: "flt-001")).map(\.id) == ["FLT-001"])
        #expect(bank.filter(QuestionFilter(search: "   ")).count == 3, "a blank search matches everything")
    }

    @Test func findsAQuestionByIDIgnoringCase() {
        #expect(bank.question(id: "ios-002")?.title == "What is an actor?")
        #expect(bank.question(id: "IOS-404") == nil)
    }
}
