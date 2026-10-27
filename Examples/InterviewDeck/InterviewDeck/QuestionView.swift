import InterviewBank
import SwiftUI

/// One question with its answer, sources and the test that checks it.
struct QuestionView: View {
    let question: Question

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                QuestionHeader(question: question)
                AnswerView(markdown: question.answer)
                ReferencesView(question: question)
            }
            .padding()
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(question.id)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct QuestionHeader: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.title)
                .font(.title2.bold())
            HStack(spacing: 8) {
                LevelBadge(level: question.level)
                Text("\(question.track.displayName) · \(question.topic)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            if question.verifiedBy != nil {
                Label("The code in this answer is checked by a test", systemImage: "checkmark.seal.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.deckBlue)
            }
        }
    }
}

/// Renders the prose, code and tables that AnswerBlock splits an answer into.
struct AnswerView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(AnswerBlock.split(markdown).enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let text):
                    InlineMarkdown(AnswerBlock.joiningSoftLineBreaks(text))
                case .code(_, let source):
                    ScrollView(.horizontal) {
                        Text(source)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                    }
                    .background(Color.deckBlue.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                case .table(let header, let rows):
                    ScrollView(.horizontal) {
                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                            GridRow {
                                ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                                    InlineMarkdown(cell).bold()
                                }
                            }
                            Divider()
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                GridRow {
                                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                        InlineMarkdown(cell).frame(maxWidth: 260, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .font(.footnote)
                        .padding(12)
                    }
                    .background(Color.deckBlue.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

/// Inline Markdown (bold, code, links) with line breaks kept, so lists stay readable.
struct InlineMarkdown: View {
    private let text: AttributedString

    init(_ markdown: String) {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        text = (try? AttributedString(markdown: markdown, options: options)) ?? AttributedString(markdown)
    }

    var body: some View {
        Text(text).fixedSize(horizontal: false, vertical: true)
    }
}

struct ReferencesView: View {
    let question: Question

    var body: some View {
        if !question.references.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("References").font(.headline)
                ForEach(question.references, id: \.self) { reference in
                    if let url = URL(string: reference) {
                        Link(reference, destination: url)
                            .font(.footnote)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
    }
}
