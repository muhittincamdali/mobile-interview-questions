# Writing Questions

Add or correct a question so that the parser reads it and the linter accepts it.

## The file format

Each topic is one Markdown file in `questions/<track>/`, where the track folder is the raw value of
a ``Track``: `ios`, `android`, `flutter`, `react-native`, `system-design` or `behavioral`.

```markdown
# Swift concurrency

## IOS-026: What is actor reentrancy, and what bug does it cause?

**Level:** senior

While an actor method is suspended at an `await`, the actor is free to run other calls...

**Reference:** [SE-0306: Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md)
```

``QuestionParser`` reads it like this:

- The `# ` heading is the topic of every question in the file. There is exactly one, before the
  first question.
- Each `## ` heading starts a question: an ID, a colon, and the question. The ID is two to four
  capital letters, a hyphen and three digits.
- The first non-empty line after the heading is the level line. ``Level`` is `junior`, `mid` or
  `senior`. It may be followed by one link to the test that checks the answer, relative to the
  question file: `**Level:** senior · **Verified by:** [ConcurrencyTests](../../Tests/AnswerTests/ConcurrencyTests.swift)`.
- Lines that start with `**Reference:**` or `**References:**` are collected as
  ``Question/references``; everything else is the ``Question/answer``.
- Inside fenced code blocks (three or more backticks or tildes) nothing is a heading or a reference
  line, so code samples can contain `##` or `**Reference:**` safely.

Problems do not stop the parser. Each becomes a ``Diagnostic`` with the file and line, and the
question is skipped, so one run of `swift run interview lint` shows every mistake.

## The content rules

``BankLinter`` adds the rules that need the whole bank or the file system:

| Rule                                                                                                                 | Why                                                                                      |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| IDs are unique across all files                                                                                      | Links and quizzes refer to questions by ID                                               |
| The ID starts with the track's ``Track/idPrefix`` (`IOS-`, `AND-`, `FLT-`, `RN-`, `SD-`, `BHV-`)                       | The ID tells the reader the platform                                                     |
| The answer is not empty                                                                                              |                                                                                          |
| Technical tracks have at least one reference                                                                         | Answers must be checkable against a primary source                                       |
| References are `https` URLs                                                                                          |                                                                                          |
| A Verified-by link is a relative path inside the repository, to a file that contains the question ID as a whole word | The test that checks the answer can be found, and the link cannot point at a random file |

## Verify an answer's code

When an answer contains code that can run without a device, add a test and link it:

- Swift: a test in `Tests/AnswerTests` with Swift Testing, named after the question:
  `@Test("IOS-026: actor state can change across an await")`.
- Dart and Flutter: a `test` or `testWidgets` in `answers/flutter/test`.
- JavaScript: a `test` in `answers/react-native/test`, run by `node --test`.

The test should check the claim the answer makes, including the edge case it warns about, so that a
wrong answer fails. Writing the tests for this bank corrected several drafts before they were
published, for example that `Int(1e300)` with a literal fails at compile time and only a value
known at run time traps.

## Check your change

```sh
swift run interview lint
swift test
```

`swift test` runs the linter on the repository's own folder as well, and checks that the topic
table in `questions/README.md` and the counts in the README match the files.
