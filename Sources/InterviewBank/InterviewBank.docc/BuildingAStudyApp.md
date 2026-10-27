# Building a Study App

Bundle the question files in an app and show answers with code and tables.

## Copy the questions into the app

The InterviewDeck example in the repository's `Examples` folder adds the `questions` folder to its
target as a **folder reference**, so Xcode copies the whole folder, with its track subfolders, into
the app bundle. With XcodeGen that is:

```yaml
sources:
    - path: InterviewDeck
    - path: ../../questions
      type: folder
      buildPhase: resources
```

In Xcode, drag the folder into the project navigator and choose **Create folder references**.

## Load the bundled folder

```swift
import InterviewBank
import Observation

@MainActor
@Observable
final class DeckModel {
    private(set) var bank: QuestionBank
    private(set) var loadError: String?

    init(bundle: Bundle = .main) {
        guard let folder = bundle.url(forResource: "questions", withExtension: nil) else {
            bank = QuestionBank(questions: [])
            loadError = "The app bundle has no questions folder."
            return
        }
        do {
            bank = try QuestionBank.load(from: folder)
            loadError = bank.diagnostics.isEmpty ? nil : bank.diagnostics.map(\.description).joined(separator: "\n")
        } catch {
            bank = QuestionBank(questions: [])
            loadError = String(describing: error)
        }
    }
}
```

The bank is under 200 KB of text and loads in milliseconds, so loading on the main actor at launch
is fine. Show ``QuestionBank/diagnostics`` somewhere instead of hiding them: they mean a file in the
build is broken.

## Show an answer

``AnswerBlock/split(_:)`` turns an answer into prose, fenced code and tables, which a UI usually
renders differently:

```swift
ForEach(Array(AnswerBlock.split(question.answer).enumerated()), id: \.offset) { _, block in
    switch block {
    case .text(let markdown):
        Text(attributed(AnswerBlock.joiningSoftLineBreaks(markdown)))
    case .code(_, let source):
        ScrollView(.horizontal) {
            Text(source).font(.system(.footnote, design: .monospaced))
        }
    case .table(let header, let rows):
        TableGrid(header: header, rows: rows)
    }
}
```

Every table row has as many cells as the header, so a grid can index rows by header column. Short
rows get empty cells, but no more than the table writes itself: a table that would need more, such
as a wide header over many one-cell rows, comes back as prose, and the result of
``AnswerBlock/split(_:)`` stays proportional to the answer.

The question files wrap lines at about 100 columns. ``AnswerBlock/joiningSoftLineBreaks(_:)`` joins
them back into paragraphs while keeping list items on their own lines, which matters when you parse
the prose with `AttributedString(markdown:options:)` and `.inlineOnlyPreservingWhitespace`.

## Run a repeatable quiz

``Quiz/pick(_:from:seed:)`` picks distinct questions with a ``SeededGenerator``. Show the seed to the
user, and the same seed and pool give the same questions again on any device:

```swift
let pool = bank.filter(QuestionFilter(track: .flutter, level: .mid))
let seed = UInt64.random(in: 0...UInt64.max)
let cards = Quiz.pick(10, from: pool, seed: seed)
```

A count of zero or less gives an empty quiz, and a count larger than the pool gives the whole pool
shuffled, so the value from a stepper or a text field can be passed without extra checks.
