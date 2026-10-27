import Foundation

/// A folder under the user's temporary directory that is removed when the test ends.
final class TemporaryFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("InterviewBankTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    @discardableResult
    func write(_ relativePath: String, _ text: String) throws -> URL {
        let file = url.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
        return file
    }

    static func question(_ id: String, level: String = "mid", meta: String = "", answer: String = "An answer.", reference: String? = "https://developer.apple.com/documentation/swift") -> String {
        var text = "## \(id): Question \(id)?\n\n**Level:** \(level)\(meta)\n\n\(answer)\n"
        if let reference { text += "\n**Reference:** [Docs](\(reference))\n" }
        return text
    }
}
