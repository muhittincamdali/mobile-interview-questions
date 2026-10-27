import Foundation
import Testing
@testable import InterviewBank

@Suite("Answer blocks")
struct AnswerBlockTests {
    @Test func splitsProseAndCodeInOrder() {
        let blocks = AnswerBlock.split("First paragraph.\n\n```swift\nlet a = 1\n\nlet b = 2\n```\n\n- a list\n\n~~~\nplain\n~~~")
        #expect(blocks == [
            .text("First paragraph."),
            .code(language: "swift", source: "let a = 1\n\nlet b = 2"),
            .text("- a list"),
            .code(language: nil, source: "plain"),
        ])
    }

    @Test func keepsAnUnclosedBlockAsCode() {
        #expect(AnswerBlock.split("Intro\n```kotlin\nval x = 1") == [.text("Intro"), .code(language: "kotlin", source: "val x = 1")])
    }

    @Test func keepsInnerFencesInsideALongerFence() {
        #expect(AnswerBlock.split("````md\n```swift\nx\n```\n````") == [.code(language: "md", source: "```swift\nx\n```")])
    }

    @Test func readsPipeTablesWithAlignmentAndPaddingRows() {
        let blocks = AnswerBlock.split("Before.\n\n| Tool | Use |\n| :--- | ---: |\n| `a \\| b` | x |\n| c |\n\nAfter.")
        #expect(blocks == [
            .text("Before."),
            .table(header: ["Tool", "Use"], rows: [["`a | b`", "x"], ["c", ""]]),
            .text("After."),
        ])
    }

    /// Short rows are padded to the header width, so a wide header over many short rows once turned
    /// 48 KB of text into 96 million cells and 1.6 GB of memory. The table is now kept as prose,
    /// and the cells of the result stay within the size of the text.
    @Test func keepsAWideTableOfShortRowsAsProse() {
        let width = 2_000
        let header = String(repeating: "| h ", count: width) + "|"
        let separator = String(repeating: "|---", count: width) + "|"
        let markdown = ([header, separator] + Array(repeating: "| x |", count: 3_000)).joined(separator: "\n")
        var blocks: [AnswerBlock] = []
        let elapsed = ContinuousClock().measure {
            blocks = AnswerBlock.split(markdown)
        }
        let cells = blocks.reduce(0) { total, block in
            guard case .table(let header, let rows) = block else { return total }
            return total + header.count + rows.reduce(0) { $0 + $1.count }
        }
        #expect(cells <= markdown.utf8.count, "\(cells) cells from \(markdown.utf8.count) bytes")
        #expect(blocks == [.text(markdown)])
        #expect(elapsed < .seconds(2), "splitting took \(elapsed)")
    }

    /// Padding may add at most as many cells as the table writes: header, separator and rows.
    @Test func padsShortRowsUpToTheCellsTheTableWrites() {
        let table = "| a | b | c |\n|---|---|---|\n"
        let sixRows = table + Array(repeating: "| x |", count: 6).joined(separator: "\n")
        #expect(AnswerBlock.split(sixRows) == [
            .table(header: ["a", "b", "c"], rows: Array(repeating: ["x", "", ""], count: 6)),
        ], "6 written + 6 header and separator cells, 12 added")
        let sevenRows = table + Array(repeating: "| x |", count: 7).joined(separator: "\n")
        #expect(AnswerBlock.split(sevenRows) == [.text(sevenRows)], "7 + 6 written, 14 added")
    }

    @Test func keepsBackslashesThatDoNotEscapeAPipe() {
        #expect(AnswerBlock.cells("| a\\*b | c\\ |") == ["a\\*b", "c\\"])
    }

    @Test func keepsPipesWithoutASeparatorRowAsProse() {
        #expect(AnswerBlock.split("| not | a table |\nnext line") == [.text("| not | a table |\nnext line")])
        #expect(AnswerBlock.split("| a | b |\n| --- |") == [.text("| a | b |\n| --- |")], "column counts must match")
    }

    @Test func joinsWrappedLinesButKeepsParagraphsAndListItems() {
        let text = """
            A paragraph that was
            wrapped at 100 columns.


            - first item that
              continues here
            - second item
            12. numbered item
            2026 is a year, not an item.
            """
        #expect(AnswerBlock.joiningSoftLineBreaks(text) == """
            A paragraph that was wrapped at 100 columns.

            - first item that continues here
            - second item
            12. numbered item 2026 is a year, not an item.
            """)
        #expect(AnswerBlock.joiningSoftLineBreaks("") == "")
        #expect(AnswerBlock.joiningSoftLineBreaks("\n\n") == "")
    }

    @Test func keepsALeadingParagraphBreakAndDropsTrailingBlankLines() {
        #expect(AnswerBlock.joiningSoftLineBreaks("\n\nA\nB\n\n\n- c\n\n") == "\nA B\n\n- c")
    }

    /// One 1 MB paragraph of 500,000 one-word lines. Rebuilding the paragraph for every line
    /// took 8 s in a debug build; appending in place takes about half a second.
    @Test func joinsAMegabyteParagraphInLinearTime() {
        let text = String(repeating: "w\n", count: 500_000)
        let clock = ContinuousClock()
        var joined = ""
        let elapsed = clock.measure {
            joined = AnswerBlock.joiningSoftLineBreaks(text)
        }
        #expect(joined.count == 500_000 * 2 - 1)
        #expect(!joined.contains("\n"))
        #expect(elapsed < .seconds(4), "joining took \(elapsed)")
    }

    @Test func dropsBlankProse() {
        #expect(AnswerBlock.split("\n\n   \n").isEmpty)
    }
}
