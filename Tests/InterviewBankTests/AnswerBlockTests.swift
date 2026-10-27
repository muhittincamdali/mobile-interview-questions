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

    @Test func dropsBlankProse() {
        #expect(AnswerBlock.split("\n\n   \n").isEmpty)
    }
}
