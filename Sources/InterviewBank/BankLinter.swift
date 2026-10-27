import Foundation

/// Checks the content rules that `swift run interview lint` and CI enforce.
///
/// On top of the format problems the loader reports, every question must have:
/// - an ID that is unique in the bank and starts with its track's prefix (`IOS-`, `AND-`, …),
/// - a non-empty answer,
/// - at least one `https` reference, except in the behavioral track,
/// - when it has a **Verified by** link, a test file inside the repository that names its ID.
public struct BankLinter: Sendable {
    /// The `questions` folder the bank was loaded from.
    public var questionsFolder: URL
    /// Verified-by links may not point outside this folder.
    public var repositoryRoot: URL
    public var limits: BankLimits

    public init(questionsFolder: URL, repositoryRoot: URL? = nil, limits: BankLimits = .default) {
        self.questionsFolder = questionsFolder.standardizedFileURL
        self.repositoryRoot = (repositoryRoot ?? questionsFolder.deletingLastPathComponent()).standardizedFileURL
        self.limits = limits
    }

    /// The loader's diagnostics followed by the content problems, in file order, with at most
    /// ``BankLimits/maxDiagnosticsPerFile`` problems for each file.
    public func lint(_ bank: QuestionBank) -> [Diagnostic] {
        var diagnostics = bank.diagnostics
        // A file's count starts at what the loader reported for it, so loader and linter share
        // one limit per file.
        var reported = Dictionary(bank.diagnostics.map { ($0.location.file, 1) }, uniquingKeysWith: +)
        func report(_ message: String, at location: SourceLocation) {
            let count = reported[location.file, default: 0]
            reported[location.file] = count + 1
            if count < limits.maxDiagnosticsPerFile {
                diagnostics.append(Diagnostic(message, at: location))
            } else if count == limits.maxDiagnosticsPerFile {
                diagnostics.append(DiagnosticLog.overflow(limit: limits.maxDiagnosticsPerFile, at: location))
            }
        }
        var firstUse: [String: SourceLocation] = [:]
        // The question IDs each linked test file names, read and scanned once per file.
        var testFiles: [String: Set<String>?] = [:]

        for question in bank.questions {
            let location = question.location
            if let earlier = firstUse[question.id] {
                report("\(question.id) is already used at \(earlier)", at: location)
            } else {
                firstUse[question.id] = location
            }
            if !question.id.hasPrefix(question.track.idPrefix + "-") {
                report("\(question.id) is in the \(question.track.rawValue) track, so its ID must start with \(question.track.idPrefix)-", at: location)
            }
            if question.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                report("\(question.id) has no answer", at: location)
            }
            if question.track.requiresReference && question.references.isEmpty {
                report("\(question.id) needs a **Reference:** line with a primary source", at: location)
            }
            for reference in question.references where !Self.isSecureLink(reference) {
                report("\(question.id): reference `\(reference)` must be an https URL", at: location)
            }
            if let target = question.verifiedBy {
                if let problem = checkVerification(of: question, target: target, cache: &testFiles) {
                    report(problem, at: location)
                }
            }
        }
        return diagnostics
    }

    static func isSecureLink(_ link: String) -> Bool {
        guard let url = URL(string: link), url.scheme == "https", let host = url.host, !host.isEmpty else { return false }
        return !link.contains(where: \.isWhitespace)
    }

    /// `nil` when the link resolves inside the repository to a file that names the question.
    private func checkVerification(of question: Question, target: String, cache: inout [String: Set<String>?]) -> String? {
        if target.contains("://") || target.hasPrefix("/") {
            return "\(question.id): **Verified by** must be a relative path to a test file"
        }
        let fileFolder = questionsFolder.appendingPathComponent(question.location.file).deletingLastPathComponent()
        let resolved = fileFolder.appendingPathComponent(target).standardizedFileURL.resolvingSymlinksInPath()
        let root = repositoryRoot.resolvingSymlinksInPath().path
        guard resolved.path.hasPrefix(root + "/") else {
            return "\(question.id): **Verified by** points outside the repository"
        }
        let key = resolved.path
        if cache[key] == nil {
            cache[key] = .some(QuestionBank.readText(at: resolved, limit: limits.maxFileBytes).map(Self.questionIDs))
        }
        guard let namedIDs = cache[key] ?? nil else {
            return "\(question.id): **Verified by** file `\(target)` does not exist or cannot be read"
        }
        guard namedIDs.contains(question.id) else {
            return "\(question.id): `\(target)` has no test named after \(question.id)"
        }
        return nil
    }

    /// The question IDs that appear as whole words in `text`, so `IOS-001` is found in
    /// `@Test("IOS-001: …")` but not in `IOS-0012` or `XIOS-001`.
    ///
    /// Many questions can link the same test file, so the file is scanned once and each question
    /// is a set lookup; searching the text again for every question made the time grow with
    /// questions times file size.
    static func questionIDs(in text: String) -> Set<String> {
        let isWordCharacter: (Character) -> Bool = { $0.isLetter || $0.isNumber || $0 == "-" }
        var ids = Set<String>()
        var wordStart: String.Index?
        for index in text.indices {
            if isWordCharacter(text[index]) {
                if wordStart == nil { wordStart = index }
            } else if let start = wordStart {
                insertIfID(text[start..<index], into: &ids)
                wordStart = nil
            }
        }
        if let start = wordStart {
            insertIfID(text[start...], into: &ids)
        }
        return ids
    }

    private static func insertIfID(_ word: Substring, into ids: inout Set<String>) {
        // The longest ID is eight characters (`ABCD-123`); skipping longer words keeps a long run
        // of letters from being split and checked.
        guard word.utf8.count <= 8, QuestionParser.isValidID(word) else { return }
        ids.insert(String(word))
    }
}
