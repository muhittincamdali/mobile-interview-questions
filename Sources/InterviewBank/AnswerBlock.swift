/// A piece of an answer for apps that show prose and code differently.
public enum AnswerBlock: Hashable, Sendable {
    /// Markdown prose: paragraphs, lists and inline code.
    case text(String)
    /// A fenced code block, with the language from its info string (`swift`, `kotlin`, …).
    case code(language: String?, source: String)
    /// A pipe table: the header cells and the body rows, with the `---` separator row removed.
    /// Cells keep their inline Markdown.
    case table(header: [String], rows: [[String]])

    /// Splits Markdown into prose, fenced code blocks and pipe tables, in order. Blank prose is
    /// dropped and an unclosed code block runs to the end of the text.
    public static func split(_ markdown: String) -> [AnswerBlock] {
        var blocks: [AnswerBlock] = []
        var prose: [Substring] = []
        var code: [Substring] = []
        var language: String?
        var fence = FenceTracker()

        func flushProse() {
            var text: [Substring] = []
            var tableLines: [Substring] = []
            func flushText() {
                let joined = text.joined(separator: "\n").trimmingSpaces()
                if !joined.isEmpty { blocks.append(.text(joined)) }
                text.removeAll()
            }
            func flushTable() {
                guard !tableLines.isEmpty else { return }
                if let table = Self.table(from: tableLines) {
                    flushText()
                    blocks.append(table)
                } else {
                    text += tableLines
                }
                tableLines.removeAll()
            }
            for line in prose {
                if line.drop(while: { $0 == " " }).hasPrefix("|") {
                    tableLines.append(line)
                } else {
                    flushTable()
                    text.append(line)
                }
            }
            flushTable()
            flushText()
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

    /// A table needs a header row and a separator row of dashes; anything else stays prose.
    static func table(from lines: [Substring]) -> AnswerBlock? {
        guard lines.count >= 2 else { return nil }
        let rows = lines.map(cells)
        let separator = rows[1]
        let isSeparator = !separator.isEmpty && separator.allSatisfy { cell in
            let core = cell.trimmingSpaces().drop { $0 == ":" }
            return !core.isEmpty && core.allSatisfy { $0 == "-" || $0 == ":" }
        }
        guard isSeparator, rows[0].count == separator.count else { return nil }
        let width = rows[0].count
        let body = rows.dropFirst(2).map { row in
            Array((row + Array(repeating: "", count: max(0, width - row.count))).prefix(width))
        }
        return .table(header: rows[0], rows: Array(body))
    }

    /// `| a | b \| c |` → ["a", "b | c"]. A leading and trailing pipe are optional.
    static func cells(_ line: Substring) -> [String] {
        var cells: [String] = []
        var current = ""
        var escaped = false
        var inCode = false
        for character in line.trimmingSpaces() {
            if escaped {
                // Only `\|` is an escape here; other backslashes stay for the Markdown renderer.
                if character != "|" { current.append("\\") }
                current.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "`" {
                inCode.toggle()
                current.append(character)
            } else if character == "|" && !inCode {
                cells.append(current.trimmingSpaces())
                current = ""
            } else {
                current.append(character)
            }
        }
        if escaped { current.append("\\") }
        cells.append(current.trimmingSpaces())
        if cells.first == "" { cells.removeFirst() }
        if cells.last == "" { cells.removeLast() }
        return cells
    }

    /// Joins the hard-wrapped lines of Markdown prose into paragraphs, for renderers that keep
    /// line breaks (such as SwiftUI `Text` with `.inlineOnlyPreservingWhitespace`).
    ///
    /// Blank lines still separate paragraphs, and list items (`- `, `* `, `+ `, `1. `) still
    /// start on a new line; an indented continuation line is joined to its item.
    public static func joiningSoftLineBreaks(_ text: String) -> String {
        var output: [String] = []
        for line in QuestionParser.splitLines(text) {
            let trimmed = line.trimmingSpaces()
            if trimmed.isEmpty {
                output.append("")
            } else if let last = output.last, !last.isEmpty, !isListItem(trimmed) {
                output[output.count - 1] = last + " " + trimmed
            } else {
                output.append(isListItem(trimmed) ? String(line).trimmingSpaces() : trimmed)
            }
        }
        while output.last == "" { output.removeLast() }
        // Collapse runs of blank lines into one paragraph break.
        var collapsed: [String] = []
        for line in output where !(line.isEmpty && collapsed.last?.isEmpty == true) {
            collapsed.append(line)
        }
        return collapsed.joined(separator: "\n")
    }

    static func isListItem(_ line: String) -> Bool {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") { return true }
        let digits = line.prefix { $0.isASCII && $0.isNumber }
        return !digits.isEmpty && digits.count <= 3 && line.dropFirst(digits.count).hasPrefix(". ")
    }
}
