import Foundation
import InterviewBank

/// What a run of `interview` printed and how it ended.
public struct ToolOutput: Equatable, Sendable {
    public var status: Int32
    public var standardOutput: String
    public var standardError: String
}

/// The `interview` command, separated from the process so tests can run it.
public struct InterviewTool: Sendable {
    public var currentDirectory: URL
    /// Called for a quiz without `--seed`; the seed is printed so the quiz can be repeated.
    public var makeSeed: @Sendable () -> UInt64

    public init(currentDirectory: URL, makeSeed: @escaping @Sendable () -> UInt64 = { UInt64.random(in: 0...UInt64.max) }) {
        self.currentDirectory = currentDirectory
        self.makeSeed = makeSeed
    }

    static let usage = """
        Usage: interview <command> [options]

        Commands:
          list                 List questions (ID, level, topic, question)
          show <ID>            Print one question with its answer and references
          quiz                 Pick random questions; add --answers to print the answers
          stats                Count questions per track and level
          lint                 Check the question files; exits with 1 on any problem

        Options:
          --bank <folder>      Question folder (default: ./questions)
          --track <track>      ios, android, flutter, react-native, system-design, behavioral
          --level <level>      junior, mid or senior
          --topic <topic>      A file title, such as "Swift concurrency"
          --search <text>      Text in the ID, question or answer
          --count <n>          Questions in a quiz, 1 to 50 (default: 5)
          --seed <n>           Repeat a quiz: the same seed picks the same questions
          --answers            Print the answers after the quiz questions

        Examples:
          swift run interview quiz --track ios --level senior --count 3
          swift run interview show IOS-012
        """

    public func run(_ arguments: [String]) -> ToolOutput {
        let parsed: Arguments
        do {
            parsed = try Arguments.parse(arguments)
        } catch {
            return ToolOutput(status: 2, standardOutput: "", standardError: "error: \(error.message)\n\nRun `interview --help` for usage.\n")
        }
        if parsed.command == .help {
            return ToolOutput(status: 0, standardOutput: Self.usage + "\n", standardError: "")
        }
        let folder = parsed.bank.map { URL(fileURLWithPath: $0, relativeTo: currentDirectory) }
            ?? currentDirectory.appendingPathComponent("questions")
        let bank: QuestionBank
        do {
            bank = try QuestionBank.load(from: folder.standardizedFileURL)
        } catch {
            return ToolOutput(status: 2, standardOutput: "", standardError: "error: \(error)\n")
        }
        var printer = Printer()
        let status = execute(parsed, bank: bank, folder: folder.standardizedFileURL, printer: &printer)
        return ToolOutput(status: status, standardOutput: printer.output, standardError: printer.errors)
    }

    private func execute(_ arguments: Arguments, bank: QuestionBank, folder: URL, printer: inout Printer) -> Int32 {
        switch arguments.command {
        case .list:
            let questions = bank.filter(arguments.filter)
            guard !questions.isEmpty else {
                printer.error("No questions match these filters.")
                return 1
            }
            printer.table(questions.map { [$0.id, $0.level.rawValue, $0.topic, $0.title] })
            printer.line("\n\(questions.count) question\(questions.count == 1 ? "" : "s")")
            return 0
        case .show:
            guard let id = arguments.questionID, let question = bank.question(id: id) else {
                printer.error("No question with the ID `\(arguments.questionID ?? "")`. Run `interview list` to see the IDs.")
                return 1
            }
            printer.question(question, verifiedBy: verificationPath(of: question, folder: folder))
            return 0
        case .quiz:
            return quiz(arguments, bank: bank, folder: folder, printer: &printer)
        case .stats:
            printer.stats(bank.filter(arguments.filter))
            return 0
        case .lint:
            let diagnostics = BankLinter(questionsFolder: folder).lint(bank)
            for diagnostic in diagnostics { printer.line(diagnostic.description) }
            printer.line("\(bank.questions.count) questions, \(diagnostics.count) problem\(diagnostics.count == 1 ? "" : "s")")
            return diagnostics.isEmpty ? 0 : 1
        case .help:
            return 0
        }
    }

    private func quiz(_ arguments: Arguments, bank: QuestionBank, folder: URL, printer: inout Printer) -> Int32 {
        let pool = bank.filter(arguments.filter)
        guard !pool.isEmpty else {
            printer.error("No questions match these filters.")
            return 1
        }
        let seed = arguments.seed ?? makeSeed()
        let picked = Quiz.pick(arguments.count, from: pool, seed: seed)
        printer.line("Quiz: \(picked.count) of \(pool.count) questions · seed \(seed)\n")
        for (index, question) in picked.enumerated() {
            printer.line("\(index + 1). [\(question.id) · \(question.level.rawValue) · \(question.topic)] \(question.title)")
        }
        if arguments.showAnswers {
            for question in picked {
                printer.line("\n" + String(repeating: "─", count: 60))
                printer.question(question, verifiedBy: verificationPath(of: question, folder: folder))
            }
        } else {
            printer.line("\nAnswers: interview show <ID>, or repeat with --seed \(seed) --answers")
        }
        return 0
    }

    /// The Verified-by test as a path from the current directory, such as
    /// `Tests/AnswerTests/MemoryTests.swift` from the repository root. The link in the file is
    /// relative to the question file (`../../Tests/...`), which is not where the reader is.
    func verificationPath(of question: Question, folder: URL) -> String? {
        guard let target = question.verifiedBy else { return nil }
        guard !target.contains("://"), !target.hasPrefix("/") else { return target }
        let resolved = folder
            .appendingPathComponent(question.location.file)
            .deletingLastPathComponent()
            .appendingPathComponent(target)
            .standardizedFileURL
            .path
        let here = currentDirectory.standardizedFileURL.path
        let prefix = here.hasSuffix("/") ? here : here + "/"
        return resolved.hasPrefix(prefix) ? String(resolved.dropFirst(prefix.count)) : resolved
    }
}

/// Collects the text a command prints.
///
/// Question files can come from any folder passed with `--bank`, so everything is printed through
/// ``terminalSafe(_:)``: an escape sequence in a title or an answer must not reach the terminal.
struct Printer {
    private(set) var output = ""
    private(set) var errors = ""

    mutating func line(_ text: String) {
        output += Self.terminalSafe(text) + "\n"
    }

    mutating func error(_ text: String) {
        errors += Self.terminalSafe(text) + "\n"
    }

    /// Removes control characters (C0, DEL and C1, which include ESC and CSI) except line feed and
    /// tab, so printed text cannot move the cursor, clear the screen or set the window title.
    static func terminalSafe(_ text: String) -> String {
        let isUnsafe: (Unicode.Scalar) -> Bool = { scalar in
            scalar.properties.generalCategory == .control && scalar != "\n" && scalar != "\t"
        }
        guard text.unicodeScalars.contains(where: isUnsafe) else { return text }
        var scalars = String.UnicodeScalarView()
        scalars.append(contentsOf: text.unicodeScalars.filter { !isUnsafe($0) })
        return String(scalars)
    }

    /// Left-aligned columns; the last column is not padded.
    mutating func table(_ rows: [[String]]) {
        // Cleaned before measuring, so removed characters do not throw the columns off.
        let rows = rows.map { $0.map(Self.terminalSafe) }
        guard let columns = rows.first?.count else { return }
        let widths = (0..<columns).map { column in rows.map { $0[column].count }.max() ?? 0 }
        for row in rows {
            let cells = row.enumerated().map { index, cell in
                index == columns - 1 ? cell : cell.padding(toLength: widths[index], withPad: " ", startingAt: 0)
            }
            line(cells.joined(separator: "  "))
        }
    }

    /// The question with its answer and sources; `verifiedBy` is the test path to print.
    mutating func question(_ question: Question, verifiedBy: String?) {
        line("\(question.id): \(question.title)")
        line("\(question.track.displayName) · \(question.topic) · \(question.level.rawValue)\n")
        line(question.answer)
        if !question.references.isEmpty {
            line("\nReferences:")
            for reference in question.references { line("  \(reference)") }
        }
        if let verifiedBy {
            line("Verified by: \(verifiedBy)")
        }
    }

    mutating func stats(_ questions: [Question]) {
        var rows = [["Track", "junior", "mid", "senior", "total"]]
        for track in Track.allCases {
            let inTrack = questions.filter { $0.track == track }
            guard !inTrack.isEmpty else { continue }
            let counts = Level.allCases.map { level in String(inTrack.count { $0.level == level }) }
            rows.append([track.displayName] + counts + [String(inTrack.count)])
        }
        let totals = Level.allCases.map { level in String(questions.count { $0.level == level }) }
        rows.append(["All"] + totals + [String(questions.count)])
        let verified = questions.count { $0.verifiedBy != nil }
        table(rows)
        line("\n\(verified) of \(questions.count) answers have code checked by a test")
    }
}
