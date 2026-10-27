/// A place in a question file, used for questions and diagnostics.
public struct SourceLocation: Hashable, Sendable, CustomStringConvertible {
    /// The file path as it was given to the parser, usually relative to the repository.
    public var file: String
    /// The 1-based line number.
    public var line: Int

    public init(file: String, line: Int) {
        self.file = file
        self.line = line
    }

    public var description: String { "\(file):\(line)" }
}

/// One interview question with its answer.
public struct Question: Identifiable, Hashable, Sendable {
    /// A stable ID such as `IOS-014`; links and the quiz refer to it.
    public var id: String
    public var track: Track
    /// The title of the file the question is in, such as "Swift concurrency".
    public var topic: String
    /// The question as it is asked.
    public var title: String
    public var level: Level
    /// The answer in Markdown, without the level line and the references.
    public var answer: String
    /// Primary sources for the answer: Apple, Android, Flutter, React Native or language docs.
    public var references: [String]
    /// A path, relative to the question file, to the test that checks the answer's code.
    public var verifiedBy: String?
    public var location: SourceLocation

    public init(
        id: String,
        track: Track,
        topic: String,
        title: String,
        level: Level,
        answer: String,
        references: [String] = [],
        verifiedBy: String? = nil,
        location: SourceLocation
    ) {
        self.id = id
        self.track = track
        self.topic = topic
        self.title = title
        self.level = level
        self.answer = answer
        self.references = references
        self.verifiedBy = verifiedBy
        self.location = location
    }
}

/// A problem found while reading or checking the question bank.
public struct Diagnostic: Hashable, Sendable, CustomStringConvertible {
    public var location: SourceLocation
    public var message: String

    public init(_ message: String, at location: SourceLocation) {
        self.location = location
        self.message = message
    }

    public var description: String { "\(location): \(message)" }
}
