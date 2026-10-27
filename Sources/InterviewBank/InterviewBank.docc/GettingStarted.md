# Getting Started

Study with the command-line tool, or add the library to your own Swift code.

## Use the command-line tool

Clone the repository and run the tool from its root, where it finds the `questions` folder:

```sh
git clone https://github.com/muhittincamdali/mobile-interview-questions.git
cd mobile-interview-questions
swift run interview quiz --track ios --level senior --count 3
```

Swift 6.2 or later is needed (Xcode 26 on a Mac, or a Swift toolchain on Linux). The first run
builds the tool, which takes a few seconds. The commands:

| Command                  | What it does                                                                                           |
| ------------------------ | ------------------------------------------------------------------------------------------------------ |
| `interview list`         | Lists IDs, levels, topics and questions; filter with `--track`, `--level`, `--topic` and `--search`    |
| `interview show IOS-026` | Prints one question with its answer, references and the test that checks it                            |
| `interview quiz`         | Picks five random questions; `--count` (1 to 50), `--seed` to repeat, `--answers` to print the answers |
| `interview stats`        | Counts questions per track and level                                                                   |
| `interview lint`         | Checks the files and exits with status 1 on any problem                                                |

A quiz without `--seed` prints the seed it used. Pass it back to get the same questions, with
`--answers` once you have answered them:

```console
$ swift run interview quiz --track flutter --count 3 --seed 42
Quiz: 3 of 22 questions · seed 42

1. [FLT-017 · junior · Flutter framework] What is the difference between hot reload, hot restart and a full restart?
2. [FLT-005 · mid · Dart language] When and how do you use isolates in Flutter?
3. [FLT-008 · senior · Dart language] How do mixins work, and in which order do they run?

Answers: interview show <ID>, or repeat with --seed 42 --answers
```

The same seed picks the same questions as long as the bank does not change; adding questions to a
track changes the quizzes of that track.

Numbers are checked before use: `--count 0`, `--count 1e3` or a seed that does not fit in 64 bits
is a usage error (exit status 2) with a message, never a crash.

## Add the library

In a package, add the dependency and the ``InterviewBank`` product:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/mobile-interview-questions.git", from: "2.0.0")
],
targets: [
    .target(name: "MyStudyTool", dependencies: [
        .product(name: "InterviewBank", package: "mobile-interview-questions")
    ])
]
```

In an Xcode app project, choose **File > Add Package Dependencies…**, paste the repository URL,
and add the **InterviewBank** library to your target. The library needs iOS 18 or macOS 15 and
has no dependencies.

The library does not embed the questions. Point ``QuestionBank/load(from:limits:)`` at a copy of
the `questions` folder: a checkout of the repository, or a folder reference copied into your app as
<doc:BuildingAStudyApp> shows.

## Load and filter

```swift
let bank = try QuestionBank.load(from: questionsFolder)

if !bank.diagnostics.isEmpty {
    // Files that could not be read, or questions in the wrong format.
    bank.diagnostics.forEach { print($0) }
}

let concurrency = bank.filter(QuestionFilter(track: .ios, topic: "Swift concurrency"))
let aboutKeys = bank.filter(QuestionFilter(search: "ValueKey"))
let question = bank.question(id: "flt-012")   // IDs ignore case
```

``QuestionBank/load(from:limits:)`` throws only when the folder does not exist. Everything else, such
as a file that is not UTF-8 or a heading without an ID, becomes a ``Diagnostic`` and the rest of
the bank is still loaded.
