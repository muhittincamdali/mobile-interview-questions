import Foundation

/// Upper bounds that keep a damaged or hostile question folder from using unbounded memory.
public struct BankLimits: Sendable, Equatable {
    /// Largest question file that is read, in bytes.
    public var maxFileBytes: Int
    /// Most Markdown files read from the folder. Links and folders that are skipped with a
    /// diagnostic count too, so the number of diagnostics they add is bounded as well.
    public var maxFiles: Int
    /// Most questions read from one file.
    public var maxQuestionsPerFile: Int
    /// Most problems reported for one file; one more line says that the rest were not reported.
    /// Without it, a 1 MiB file of repeated `# a` lines produced 262,144 diagnostics. A negative
    /// value counts as 0: the first problem of a file is then that line.
    public var maxDiagnosticsPerFile: Int

    public init(maxFileBytes: Int, maxFiles: Int, maxQuestionsPerFile: Int, maxDiagnosticsPerFile: Int = 100) {
        self.maxFileBytes = maxFileBytes
        self.maxFiles = maxFiles
        self.maxQuestionsPerFile = maxQuestionsPerFile
        self.maxDiagnosticsPerFile = maxDiagnosticsPerFile
    }

    /// 1 MiB per file, 256 files, 500 questions and 100 reported problems per file: far above
    /// what the bank uses.
    public static let `default` = BankLimits(maxFileBytes: 1 << 20, maxFiles: 256, maxQuestionsPerFile: 500)
}

/// Why a question folder could not be read at all.
public enum BankError: Error, Equatable, CustomStringConvertible {
    case folderNotFound(String)

    public var description: String {
        switch self {
        case .folderNotFound(let path):
            "No question folder at \(path). Run the command from the repository root or pass --bank <folder>."
        }
    }
}

/// The questions of every track, with the problems found while reading them.
public struct QuestionBank: Sendable {
    public private(set) var questions: [Question]
    /// File-level and format problems found by ``load(from:limits:)``; ``BankLinter`` adds the
    /// content checks.
    public private(set) var diagnostics: [Diagnostic]

    public init(questions: [Question], diagnostics: [Diagnostic] = []) {
        self.questions = questions
        self.diagnostics = diagnostics
    }

    /// Reads `<folder>/<track>/<topic>.md` for every ``Track``.
    ///
    /// Files are read in name order so that the bank, and a seeded quiz, are the same on every
    /// machine. Symbolic links, files over ``BankLimits/maxFileBytes`` and folders that are not
    /// a track are reported and skipped; each of them counts against ``BankLimits/maxFiles``.
    public static func load(from folder: URL, limits: BankLimits = .default) throws -> QuestionBank {
        let manager = FileManager.default
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw BankError.folderNotFound(folder.path)
        }
        var bank = QuestionBank(questions: [])
        var entriesUsed = 0
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]

        /// `false`, after reporting it once, when the folder has more entries than the limit.
        func useEntry(at location: SourceLocation) -> Bool {
            guard entriesUsed < limits.maxFiles else {
                bank.diagnostics.append(Diagnostic("more than \(limits.maxFiles) question files (counting skipped links and folders); the rest were not read", at: location))
                return false
            }
            entriesUsed += 1
            return true
        }

        for entry in try sortedContents(of: folder, keys: keys) {
            let values = try entry.resourceValues(forKeys: Set(keys))
            let name = entry.lastPathComponent
            guard values.isDirectory == true else { continue }
            guard values.isSymbolicLink != true, let track = Track(rawValue: name) else {
                guard useEntry(at: SourceLocation(file: name, line: 0)) else { return bank }
                bank.diagnostics.append(Diagnostic("`\(name)` is not a track folder (\(Track.allCases.map(\.rawValue).joined(separator: ", ")))", at: SourceLocation(file: name, line: 0)))
                continue
            }
            for file in try sortedContents(of: entry, keys: keys) where file.pathExtension == "md" {
                let relative = "\(name)/\(file.lastPathComponent)"
                let location = SourceLocation(file: relative, line: 0)
                guard useEntry(at: location) else { return bank }
                let fileValues = try file.resourceValues(forKeys: Set(keys))
                if fileValues.isSymbolicLink == true || fileValues.isDirectory == true {
                    bank.diagnostics.append(Diagnostic("skipped: question files must be regular files", at: location))
                    continue
                }
                guard let text = readText(at: file, limit: limits.maxFileBytes) else {
                    bank.diagnostics.append(Diagnostic("skipped: larger than \(limits.maxFileBytes) bytes or not UTF-8", at: location))
                    continue
                }
                let parsed = QuestionParser.parse(
                    text,
                    track: track,
                    file: relative,
                    maxQuestions: limits.maxQuestionsPerFile,
                    maxDiagnostics: limits.maxDiagnosticsPerFile
                )
                bank.questions += parsed.questions
                bank.diagnostics += parsed.diagnostics
            }
        }
        return bank
    }

    private static func sortedContents(of folder: URL, keys: [URLResourceKey]) throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Reads at most `limit` bytes; a longer file returns `nil` even if it grew after it was
    /// listed.
    static func readText(at url: URL, limit: Int) -> String? {
        // One byte past the limit tells a file of exactly `limit` bytes from a longer one.
        let (probe, overflow) = limit.addingReportingOverflow(1)
        guard limit >= 0, !overflow, let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: probe) ?? Data(), data.count <= limit else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Finding questions

    /// The question with this ID, ignoring case.
    public func question(id: String) -> Question? {
        let wanted = id.uppercased()
        return questions.first { $0.id == wanted }
    }

    /// The topics of a track in file order.
    public func topics(in track: Track) -> [String] {
        var seen = Set<String>()
        return questions.filter { $0.track == track && seen.insert($0.topic).inserted }.map(\.topic)
    }

    /// Questions that match every filter that is not `nil`.
    ///
    /// `search` looks in the ID, the title and the answer, ignoring case and diacritics.
    public func filter(_ filter: QuestionFilter) -> [Question] {
        questions.filter { filter.matches($0) }
    }
}

/// What ``QuestionBank/filter(_:)`` keeps.
public struct QuestionFilter: Sendable, Equatable {
    public var track: Track?
    public var level: Level?
    public var topic: String?
    public var search: String?

    public init(track: Track? = nil, level: Level? = nil, topic: String? = nil, search: String? = nil) {
        self.track = track
        self.level = level
        self.topic = topic
        self.search = search
    }

    public func matches(_ question: Question) -> Bool {
        if let track, question.track != track { return false }
        if let level, question.level != level { return false }
        if let topic, question.topic.compare(topic, options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame {
            return false
        }
        if let search = search?.trimmingCharacters(in: .whitespaces), !search.isEmpty {
            let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
            return [question.id, question.title, question.answer].contains { $0.range(of: search, options: options) != nil }
        }
        return true
    }
}
