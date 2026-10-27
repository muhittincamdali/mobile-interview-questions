/// The result of reading one question file.
public struct ParsedFile: Sendable {
    /// The file's `# ` heading, used as the topic of its questions.
    public var topic: String?
    public var questions: [Question]
    public var diagnostics: [Diagnostic]
}

/// Reads the Markdown format described in `questions/README.md`:
///
/// ```markdown
/// # Swift language
///
/// ## IOS-001: What is the difference between a struct and a class?
///
/// **Level:** junior · **Verified by:** [ValueSemanticsTests](../../Tests/AnswerTests/ValueSemanticsTests.swift)
///
/// The answer, in Markdown.
///
/// **Reference:** [Structures and Classes](https://docs.swift.org/...)
/// ```
///
/// The parser never throws: everything it cannot read becomes a ``Diagnostic`` with a line
/// number, so one run reports every problem in a file, up to `maxDiagnostics` of them.
public enum QuestionParser {
    static let levelPrefix = "**Level:** "
    static let verifiedPrefix = "**Verified by:** "
    static let referencePrefixes = ["**Reference:** ", "**References:** "]
    static let separator = " · "
    /// Longest topic kept from a `# ` heading, in Unicode scalars. The topic is printed with every
    /// question of the file, so an unbounded heading multiplied the output of `interview list` by
    /// up to 500 questions; the longest topic in the bank has 29 scalars. Scalars, not Characters:
    /// one Character can hold any number of combining marks, so a limit in Characters let a 1 MB
    /// heading through as a single Character.
    public static let maximumTopicLength = 100

    public static func parse(
        _ text: String,
        track: Track,
        file: String,
        maxQuestions: Int = BankLimits.default.maxQuestionsPerFile,
        maxDiagnostics: Int = BankLimits.default.maxDiagnosticsPerFile
    ) -> ParsedFile {
        var parsed = ParsedFile(topic: nil, questions: [], diagnostics: [])
        var log = DiagnosticLog(limit: maxDiagnostics)
        let lines = splitLines(text)
        var fence = FenceTracker()
        var current: QuestionDraft?

        func finish() {
            guard let draft = current else { return }
            current = nil
            if let question = draft.build(track: track, topic: parsed.topic ?? "", file: file, diagnostics: &log) {
                parsed.questions.append(question)
            }
        }

        for (offset, line) in lines.enumerated() {
            let number = offset + 1
            let location = SourceLocation(file: file, line: number)
            if fence.consume(line) {
                current?.body.append((number, line))
                continue
            }
            if line.hasPrefix("# ") {
                if parsed.topic == nil && current == nil && parsed.questions.isEmpty {
                    let topic = line.dropFirst(2).trimmingSpaces()
                    let scalars = topic.unicodeScalars
                    if scalars.count > maximumTopicLength {
                        log.append(Diagnostic("the `# ` heading is longer than \(maximumTopicLength) Unicode scalars; the topic was cut", at: location))
                    }
                    parsed.topic = String(String.UnicodeScalarView(scalars.prefix(maximumTopicLength)))
                } else {
                    log.append(Diagnostic("only one `# ` heading is allowed, before the first question", at: location))
                }
                continue
            }
            if line.hasPrefix("## ") {
                finish()
                if parsed.questions.count >= maxQuestions {
                    log.append(Diagnostic("more than \(maxQuestions) questions in one file; the rest were not read", at: location))
                    parsed.diagnostics = log.entries
                    return parsed
                }
                if parsed.topic == nil {
                    log.append(Diagnostic("the file needs a `# Topic` heading before its first question", at: location))
                    parsed.topic = ""
                }
                guard let (id, title) = parseHeading(line.dropFirst(3)) else {
                    log.append(Diagnostic("question headings look like `## IOS-001: Question?`", at: location))
                    continue
                }
                current = QuestionDraft(id: id, title: title, line: number)
                continue
            }
            current?.body.append((number, line))
        }
        if fence.isOpen {
            log.append(Diagnostic("a code block is not closed", at: SourceLocation(file: file, line: lines.count)))
        }
        finish()
        parsed.diagnostics = log.entries
        return parsed
    }

    /// Splits on `\n`, `\r\n` and `\r`, and drops a byte order mark.
    static func splitLines(_ text: String) -> [Substring] {
        var body = Substring(text)
        if body.first == "\u{FEFF}" { body = body.dropFirst() }
        return body.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }


    /// `IOS-001: Question?` → ("IOS-001", "Question?").
    static func parseHeading(_ heading: Substring) -> (String, String)? {
        guard let colon = heading.firstIndex(of: ":") else { return nil }
        let id = heading[..<colon]
        let title = heading[heading.index(after: colon)...].trimmingSpaces()
        guard isValidID(id), !title.isEmpty else { return nil }
        return (String(id), title)
    }

    /// Two to four capital letters, a hyphen and three digits.
    static func isValidID(_ id: Substring) -> Bool {
        let parts = id.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let letters = parts[0]
        let digits = parts[1]
        return (2...4).contains(letters.count)
            && letters.allSatisfy { $0.isASCII && $0.isUppercase }
            && digits.count == 3
            && digits.allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// The destinations of the Markdown links in a line: `[text](url)`, `[text](<url>)`, and
    /// URLs with balanced parentheses such as `.../init(exactly:)`.
    static func linkTargets(_ line: Substring) -> [String] {
        var targets: [String] = []
        var rest = line[...]
        while let open = rest.range(of: "](") {
            var cursor = open.upperBound
            if cursor < rest.endIndex, rest[cursor] == "<" {
                let start = rest.index(after: cursor)
                guard let close = rest[start...].firstIndex(of: ">") else { break }
                targets.append(String(rest[start..<close]))
                rest = rest[rest.index(after: close)...]
                continue
            }
            var depth = 0
            var end: Substring.Index?
            while cursor < rest.endIndex {
                let character = rest[cursor]
                if character == "(" { depth += 1 }
                if character == ")" {
                    if depth == 0 { end = cursor; break }
                    depth -= 1
                }
                cursor = rest.index(after: cursor)
            }
            guard let end else { break }
            targets.append(String(rest[open.upperBound..<end]))
            rest = rest[rest.index(after: end)...]
        }
        return targets
    }
}

/// The lines of a question until the next heading.
private struct QuestionDraft {
    var id: String
    var title: String
    var line: Int
    var body: [(Int, Substring)] = []

    func build(track: Track, topic: String, file: String, diagnostics: inout DiagnosticLog) -> Question? {
        let headingLocation = SourceLocation(file: file, line: line)
        guard let metaIndex = body.firstIndex(where: { !$0.1.trimmingSpaces().isEmpty }) else {
            diagnostics.append(Diagnostic("\(id) has no level line and no answer", at: headingLocation))
            return nil
        }
        let (metaLine, metaText) = body[metaIndex]
        let metaLocation = SourceLocation(file: file, line: metaLine)
        guard let (level, verifiedBy) = parseMeta(metaText, location: metaLocation, diagnostics: &diagnostics) else {
            return nil
        }

        var answerLines: [Substring] = []
        var references: [String] = []
        var fence = FenceTracker()
        for (number, text) in body[(metaIndex + 1)...] {
            if !fence.consume(text), let prefix = QuestionParser.referencePrefixes.first(where: { text.hasPrefix($0) }) {
                let links = QuestionParser.linkTargets(text.dropFirst(prefix.count))
                if links.isEmpty {
                    diagnostics.append(Diagnostic("a reference line needs at least one `[title](https://…)` link", at: SourceLocation(file: file, line: number)))
                }
                references += links
                continue
            }
            answerLines.append(text)
        }
        // Slicing instead of `removeFirst()` in a loop: one question followed by a megabyte of
        // blank lines would otherwise shift the array once per line.
        let isBlank: (Substring) -> Bool = { $0.allSatisfy(\.isWhitespace) }
        let answer: String
        if let first = answerLines.firstIndex(where: { !isBlank($0) }),
           let last = answerLines.lastIndex(where: { !isBlank($0) }) {
            answer = answerLines[first...last].joined(separator: "\n")
        } else {
            answer = ""
        }

        return Question(
            id: id,
            track: track,
            topic: topic,
            title: title,
            level: level,
            answer: answer,
            references: references,
            verifiedBy: verifiedBy,
            location: headingLocation
        )
    }

    /// `**Level:** senior · **Verified by:** [Name](path)`.
    private func parseMeta(_ text: Substring, location: SourceLocation, diagnostics: inout DiagnosticLog) -> (Level, String?)? {
        let parts = text.trimmingSpaces().components(separatedBy: QuestionParser.separator)
        guard let first = parts.first, first.hasPrefix(QuestionParser.levelPrefix) else {
            diagnostics.append(Diagnostic("\(id) must start with `**Level:** junior`, `mid` or `senior`", at: location))
            return nil
        }
        let levelName = first.dropFirst(QuestionParser.levelPrefix.count)
        guard let level = Level(rawValue: String(levelName)) else {
            diagnostics.append(Diagnostic("\(id) has an unknown level `\(levelName)`; use junior, mid or senior", at: location))
            return nil
        }
        guard parts.count > 1 else { return (level, nil) }
        let verified = parts[1]
        guard parts.count == 2, verified.hasPrefix(QuestionParser.verifiedPrefix),
              let target = QuestionParser.linkTargets(Substring(verified)).first, !target.isEmpty else {
            diagnostics.append(Diagnostic("\(id): after the level only `· **Verified by:** [Test](path)` may follow", at: location))
            return nil
        }
        return (level, target)
    }
}

/// The problems of one file: at most `limit`, then one line that says the rest were not
/// reported, so a file of the same mistake on every line cannot fill memory with diagnostics.
struct DiagnosticLog {
    let limit: Int
    private(set) var entries: [Diagnostic] = []
    private var isFull = false

    init(limit: Int) {
        self.limit = max(limit, 0)
    }

    mutating func append(_ diagnostic: Diagnostic) {
        guard !isFull else { return }
        guard entries.count < limit else {
            isFull = true
            entries.append(Self.overflow(limit: limit, at: diagnostic.location))
            return
        }
        entries.append(diagnostic)
    }

    static func overflow(limit: Int, at location: SourceLocation) -> Diagnostic {
        Diagnostic("more than \(limit) problems in this file; the rest were not reported", at: location)
    }
}

/// Follows fenced code blocks (three or more backticks or tildes) so that headings and
/// reference lines inside code are read as code.
struct FenceTracker {
    private var open: Substring?

    var isOpen: Bool { open != nil }

    /// Returns `true` when the line opens, closes or is inside a code block.
    mutating func consume(_ line: Substring) -> Bool {
        let trimmed = line.drop { $0 == " " }
        guard let first = trimmed.first, first == "`" || first == "~" else { return isOpen }
        let run = trimmed.prefix { $0 == first }
        guard run.count >= 3 else { return isOpen }
        guard let opener = open else {
            open = run
            return true
        }
        // A closing fence uses the same character, is at least as long and has no info string.
        if opener.first == first && run.count >= opener.count && trimmed.dropFirst(run.count).allSatisfy(\.isWhitespace) {
            open = nil
        }
        return true
    }
}

extension StringProtocol {
    func trimmingSpaces() -> String {
        String(drop(while: \.isWhitespace).reversed().drop(while: \.isWhitespace).reversed())
    }
}
