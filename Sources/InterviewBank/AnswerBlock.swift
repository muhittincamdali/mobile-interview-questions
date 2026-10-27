/// A piece of an answer for apps that show prose and code differently.
public enum AnswerBlock: Hashable, Sendable {
    /// Markdown prose: paragraphs, lists and inline code.
    case text(String)
    /// A fenced code block, with the language from its info string (`swift`, `kotlin`, …).
    case code(language: String?, source: String)

    /// Splits Markdown into prose and fenced code blocks, in order. Blank prose is dropped and
    /// an unclosed block runs to the end of the text.
    public static func split(_ markdown: String) -> [AnswerBlock] {
        var blocks: [AnswerBlock] = []
        var prose: [Substring] = []
        var code: [Substring] = []
        var language: String?
        var fence = FenceTracker()

        func flushProse() {
            let text = prose.joined(separator: "\n").trimmingSpaces()
            if !text.isEmpty { blocks.append(.text(text)) }
            prose.removeAll()
        }

        for line in QuestionParser.splitLines(markdown) {
            let wasOpen = fence.isOpen
            guard fence.consume(line) else {
                prose.append(line)
                continue
            }
            if !wasOpen {
                flushProse()
                let info = line.drop { $0 == " " || $0 == "`" || $0 == "~" }.trimmingSpaces()
                language = info.isEmpty ? nil : String(info.prefix { !$0.isWhitespace })
            } else if fence.isOpen {
                code.append(line)
            } else {
                blocks.append(.code(language: language, source: code.joined(separator: "\n")))
                code.removeAll()
            }
        }
        if fence.isOpen {
            blocks.append(.code(language: language, source: code.joined(separator: "\n")))
        }
        flushProse()
        return blocks
    }
}
