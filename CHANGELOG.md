# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The version covers the
`InterviewBank` library, the `interview` command and the question format; adding or correcting
questions is a patch or minor release.

## [2.0.0] - 2026-10-27

The question collection is rewritten as a checked, tested bank with tools to study it.

### Added

- 142 questions in six tracks — iOS (58), Android (22), Flutter (22), React Native (22), system
  design (10) and behavioral (8) — each with a level and, for technical tracks, links to primary
  sources.
- Tests that run the code of 51 answers: Swift Testing in `Tests/AnswerTests`, `flutter test` in
  `answers/flutter` and `node --test` in `answers/react-native`. Each test is named after the
  question it checks.
- `InterviewBank` library: a parser that reports problems with file and line, bounded loading
  (1 MiB per file, 256 files, 500 questions and 100 reported problems per file), a linter,
  filtering and search, seeded quizzes and `AnswerBlock` for rendering prose, code and tables.
- `interview` command: `list`, `show`, `quiz`, `stats` and `lint`, with validated options.
- InterviewDeck, an example SwiftUI app for iOS and macOS that bundles the questions.
- DocC documentation with three articles, published to GitHub Pages.
- README translations in nine languages: Turkish, Simplified Chinese, Japanese, Korean, Spanish,
  German, French, Brazilian Portuguese and Russian. Each records the version of the English README
  it follows, and CI reports a translation that falls behind.
- CI through the shared workflows: Swift tests on macOS and an iPhone simulator, Flutter and
  Node.js answer tests, the example app, documentation, links and hygiene.

### Changed

- Every question follows one Markdown format, documented in `questions/README.md` and enforced by
  `swift test`.
- The README describes the current bank; its counts and sample output are checked by tests.

### Removed

- The previous Markdown files (`ios-questions/`, `docs/`, `android-questions/`,
  `flutter-questions/`, `react-native-questions/`), which duplicated topics and had no checks.
- `Documentation/` and `Templates/`, which described a question API that did not exist.
- `README_TR.md`, a Turkish copy of the old README; `README.tr.md` replaces it.
- The markdownlint workflow that ran with `continue-on-error` and could not fail.

## [1.0.0] - 2026-02-03

### Added

- First collection of iOS, Flutter, React Native, system design and behavioral questions in
  Markdown.

[2.0.0]: https://github.com/muhittincamdali/mobile-interview-questions/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/muhittincamdali/mobile-interview-questions/releases/tag/v1.0.0
