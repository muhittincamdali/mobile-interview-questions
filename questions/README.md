# Question bank

Every question lives in `questions/<track>/<topic>.md`. The bank is plain Markdown, so you can
read it here on GitHub; the `interview` command and the `InterviewBank` library read the same
files, and `swift test` fails if a file breaks the format below.

## Topics

| Track         | Topic                                                          | Questions |
| ------------- | -------------------------------------------------------------- | --------- |
| iOS           | [Swift language](ios/swift-language.md)                        | 15        |
| iOS           | [Memory management](ios/memory.md)                             | 6         |
| iOS           | [Swift concurrency](ios/concurrency.md)                        | 11        |
| iOS           | [SwiftUI](ios/swiftui.md)                                      | 10        |
| iOS           | [UIKit and the app life cycle](ios/uikit-and-app-lifecycle.md) | 6         |
| iOS           | [Data and networking](ios/data-and-networking.md)              | 5         |
| iOS           | [Testing and tooling](ios/testing-and-tooling.md)              | 5         |
| Android       | [Kotlin and coroutines](android/kotlin.md)                     | 6         |
| Android       | [Android framework and Jetpack](android/android-framework.md)  | 16        |
| Flutter       | [Dart language](flutter/dart.md)                               | 9         |
| Flutter       | [Flutter framework](flutter/flutter-framework.md)              | 13        |
| React Native  | [JavaScript for React Native](react-native/javascript.md)      | 12        |
| React Native  | [React Native](react-native/react-native.md)                   | 10        |
| System design | [Mobile system design](system-design/mobile-system-design.md)  | 10        |
| Behavioral    | [Behavioral questions](behavioral/behavioral.md)               | 8         |

## Format

```markdown
# Topic title

Optional introduction.

## IOS-001: The question, as it is asked?

**Level:** junior · **Verified by:** [TestFile](../../Tests/AnswerTests/TestFile.swift)

The answer in Markdown: prose, lists, tables and fenced code.

**Reference:** [Title of the primary source](https://developer.apple.com/documentation/...)
```

| Part               | Rule                                                                                                                                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `# Topic title`    | Exactly one, before the first question, of at most 100 Unicode scalars. It becomes the topic of every question in the file.                                                                                                           |
| `## ID: Question`  | The ID is the track prefix, a hyphen and three digits, unique in the whole bank: `IOS-`, `AND-`, `FLT-`, `RN-`, `SD-`, `BHV-`. Do not renumber published IDs; links point at them.                                                    |
| `**Level:**`       | The first line after the heading: `junior`, `mid` or `senior`.                                                                                                                                                                        |
| `**Verified by:**` | Optional, after `·`. A relative link to the test file that runs the answer's code. That file must name the question ID, usually at the start of a test name.                                                                          |
| `**Reference:**`   | One or more lines (`**References:**` reads the same) with `https` links to primary sources: Apple, Android, Flutter, Dart, React Native, Kotlin or Swift Evolution documentation, MDN, RFCs. Required except in the behavioral track. |

Headings and reference lines inside fenced code blocks are treated as code. Files are read as
UTF-8, up to 1 MiB each.

## Checking your changes

```sh
swift run interview lint        # the format and content rules, with file and line
swift test                      # the linter on this folder, plus every Swift answer test
```

Flutter answers are tested in [answers/flutter](../answers/flutter) with `flutter test`, and
JavaScript answers in [answers/react-native](../answers/react-native) with `npm test`.
