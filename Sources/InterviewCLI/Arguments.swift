import InterviewBank

/// A command line that could not be understood; exits with status 2.
struct UsageError: Error, Equatable {
    var message: String
}

/// The parsed command line of `interview`.
struct Arguments: Equatable {
    enum Command: String, CaseIterable {
        case list, show, quiz, stats, lint, help
    }

    static let countRange = 1...50

    var command: Command
    var questionID: String?
    var bank: String?
    var filter = QuestionFilter()
    var count = 5
    var seed: UInt64?
    var showAnswers = false

    /// Options that take a value, and the commands that accept each of them.
    private static let valueOptions: [String: Set<Command>] = [
        "--bank": Set(Command.allCases),
        "--track": [.list, .quiz, .stats],
        "--level": [.list, .quiz],
        "--topic": [.list, .quiz],
        "--search": [.list, .quiz],
        "--count": [.quiz],
        "--seed": [.quiz],
    ]

    static func parse(_ arguments: [String]) throws(UsageError) -> Arguments {
        guard let first = arguments.first else { return Arguments(command: .help) }
        if first == "--help" || first == "-h" { return Arguments(command: .help) }
        guard let command = Command(rawValue: first) else {
            throw UsageError(message: "unknown command `\(first)`")
        }
        var result = Arguments(command: command)
        var rest = arguments.dropFirst()

        while let argument = rest.popFirst() {
            if argument == "--help" || argument == "-h" {
                return Arguments(command: .help)
            }
            if argument == "--answers" {
                guard command == .quiz else { throw UsageError(message: "--answers only works with `quiz`") }
                result.showAnswers = true
                continue
            }
            if let allowed = valueOptions[argument] {
                guard allowed.contains(command) else {
                    throw UsageError(message: "\(argument) does not work with `\(command.rawValue)`")
                }
                guard let value = rest.popFirst(), !value.hasPrefix("--") else {
                    throw UsageError(message: "\(argument) needs a value")
                }
                try result.set(argument, to: value)
                continue
            }
            if argument.hasPrefix("-") {
                throw UsageError(message: "unknown option `\(argument)`")
            }
            guard command == .show, result.questionID == nil else {
                throw UsageError(message: "unexpected argument `\(argument)`")
            }
            result.questionID = argument
        }
        if command == .show && result.questionID == nil {
            throw UsageError(message: "`show` needs a question ID, such as `interview show IOS-001`")
        }
        return result
    }

    private mutating func set(_ option: String, to value: String) throws(UsageError) {
        switch option {
        case "--bank":
            bank = value
        case "--track":
            guard let track = Track(rawValue: value.lowercased()) else {
                throw UsageError(message: "unknown track `\(value)`; use \(Track.allCases.map(\.rawValue).joined(separator: ", "))")
            }
            filter.track = track
        case "--level":
            guard let level = Level(rawValue: value.lowercased()) else {
                throw UsageError(message: "unknown level `\(value)`; use junior, mid or senior")
            }
            filter.level = level
        case "--topic":
            filter.topic = value
        case "--search":
            filter.search = value
        case "--count":
            // Int(_:) rejects "1e3", "2.5", "" and values outside Int, so nothing here traps.
            guard let number = Int(value), Self.countRange.contains(number) else {
                throw UsageError(message: "--count must be a whole number from \(Self.countRange.lowerBound) to \(Self.countRange.upperBound)")
            }
            count = number
        case "--seed":
            guard let number = UInt64(value) else {
                throw UsageError(message: "--seed must be a whole number from 0 to \(UInt64.max)")
            }
            seed = number
        default:
            throw UsageError(message: "unknown option `\(option)`")
        }
    }
}
