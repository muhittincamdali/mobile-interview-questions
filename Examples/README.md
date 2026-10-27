# Examples

## InterviewDeck

A small iOS and macOS app for studying the question bank: browse the tracks and topics, search
questions and answers, read an answer with its code, tables and references, and run a quiz with a
chosen track, level and number of questions. It uses the `InterviewBank` library from this
checkout (a local package reference to `../..`) and copies the [`questions`](../questions) folder
into the app, so it always shows the current files.

Run it:

1. Open `Examples/InterviewDeck/InterviewDeck.xcodeproj` in Xcode 26 or later.
2. Choose the **InterviewDeck** scheme and an iPhone simulator or **My Mac** as the run destination.
3. Press **Run** (⌘R).

From the command line:

```sh
cd Examples/InterviewDeck
xcodebuild build -scheme InterviewDeck -destination 'generic/platform=iOS Simulator'
xcodebuild build -scheme InterviewDeck -destination 'platform=macOS'
```

What to look at in the code:

| File                                                                   | Shows                                                                                           |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`DeckModel.swift`](InterviewDeck/InterviewDeck/DeckModel.swift)       | Loading the bundled folder with `QuestionBank.load(from:)`, filtering, and a seeded `Quiz.pick` |
| [`QuestionView.swift`](InterviewDeck/InterviewDeck/QuestionView.swift) | Rendering an answer with `AnswerBlock.split` (prose, code and tables)                           |
| [`BrowseView.swift`](InterviewDeck/InterviewDeck/BrowseView.swift)     | Value-based `NavigationStack` navigation and search                                             |
| [`QuizView.swift`](InterviewDeck/InterviewDeck/QuizView.swift)         | The quiz set-up form and the question cards                                                     |

The app starts on the question list. The screenshot script
[`scripts/capture-screens.sh`](../scripts/capture-screens.sh) launches it with `-screen
question:IOS-026` or `-screen quiz` to open those screens directly; the quiz then uses the fixed
seed 2026, so the screenshots can be reproduced.

The project file is made with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from
[`project.yml`](InterviewDeck/project.yml) and committed, so you only need XcodeGen after editing
`project.yml`.
