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

    /// The loader's diagnostics followed by the content problems, in file order.
    public func lint(_ bank: QuestionBank) -> [Diagnostic] {
        var diagnostics = bank.diagnostics
        var firstUse: [String: SourceLocation] = [:]
        var testFiles: [String: String?] = [:]

        for question in bank.questions {
            let location = question.location
            if let earlier = firstUse[question.id] {
                diagnostics.append(Diagnostic("\(question.id) is already used at \(earlier)", at: location))
            } else {
                firstUse[question.id] = location
            }
            if !question.id.hasPrefix(question.track.idPrefix + "-") {
                diagnostics.append(Diagnostic("\(question.id) is in the \(question.track.rawValue) track, so its ID must start with \(question.track.idPrefix)-", at: location))
            }
            if question.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                diagnostics.append(Diagnostic("\(question.id) has no answer", at: location))
            }
            if question.track.requiresReference && question.references.isEmpty {
                diagnostics.append(Diagnostic("\(question.id) needs a **Reference:** line with a primary source", at: location))
            }
            for reference in question.references where !Self.isSecureLink(reference) {
                diagnostics.append(Diagnostic("\(question.id): reference `\(reference)` must be an https URL", at: location))
            }
            if let target = question.verifiedBy {
                if let problem = checkVerification(of: question, target: target, cache: &testFiles) {
                    diagnostics.append(Diagnostic(problem, at: location))
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
    private func checkVerification(of question: Question, target: String, cache: inout [String: String?]) -> String? {
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
            cache[key] = .some(QuestionBank.readText(at: resolved, limit: limits.maxFileBytes))
        }
        guard let text = cache[key] ?? nil else {
            return "\(question.id): **Verified by** file `\(target)` does not exist or cannot be read"
        }
        guard Self.mentions(text, id: question.id) else {
            return "\(question.id): `\(target)` has no test named after \(question.id)"
        }
        return nil
    }

    /// True when `id` appears as a whole word, so `IOS-001` does not match `IOS-0012`.
    static func mentions(_ text: String, id: String) -> Bool {
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: id, range: searchRange) {
            let before = found.lowerBound == text.startIndex ? nil : text[text.index(before: found.lowerBound)]
            let after = found.upperBound == text.endIndex ? nil : text[found.upperBound]
            let isBoundary: (Character?) -> Bool = { character in
                guard let character else { return true }
                return !(character.isLetter || character.isNumber || character == "-")
            }
            if isBoundary(before) && isBoundary(after) { return true }
            searchRange = found.upperBound..<text.endIndex
        }
        return false
    }
}
