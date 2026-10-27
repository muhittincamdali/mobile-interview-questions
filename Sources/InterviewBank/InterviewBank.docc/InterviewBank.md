# ``InterviewBank``

Read, check, search and quiz the mobile interview questions of this repository: iOS, Android,
Flutter, React Native, system design and behavioral.

## Overview

The questions are Markdown files in the repository's `questions` folder, one file per topic. This
library reads them into ``Question`` values, reports every format problem as a ``Diagnostic`` with
a file and line, checks the content rules with ``BankLinter``, and picks repeatable quizzes with
``Quiz``. The `interview` command-line tool and the InterviewDeck example app are built on it.

```swift
import Foundation
import InterviewBank

let folder = URL(fileURLWithPath: "questions")
let bank = try QuestionBank.load(from: folder)

let seniorSwift = bank.filter(QuestionFilter(track: .ios, level: .senior))
let quiz = Quiz.pick(5, from: seniorSwift, seed: 2026)   // the same five on every machine

for question in quiz {
    print(question.id, question.title)
}
```

Reading is bounded by ``BankLimits``: a damaged or very large folder produces diagnostics, not
unbounded memory use or a crash.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:WritingQuestions>
- <doc:BuildingAStudyApp>

### Reading the bank

- ``QuestionBank``
- ``QuestionParser``
- ``ParsedFile``
- ``BankLimits``
- ``BankError``

### Questions

- ``Question``
- ``Track``
- ``Level``
- ``SourceLocation``

### Finding and quizzing

- ``QuestionFilter``
- ``Quiz``
- ``SeededGenerator``

### Checking content

- ``BankLinter``
- ``Diagnostic``

### Showing answers

- ``AnswerBlock``
