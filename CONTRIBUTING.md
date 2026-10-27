# Contributing

Thanks for helping to keep these questions correct and current. Corrections are as valuable as
new questions: an outdated answer does more harm in an interview than a missing one.

## Reporting a wrong or outdated answer

Open an issue with the **Answer correction** template and include:

- the question ID (for example `IOS-026`),
- what is wrong, and a primary source that shows it: Apple, Android, Flutter, Dart, Kotlin or
  React Native documentation, a Swift Evolution proposal, MDN or an RFC,
- for version-specific behaviour, the OS, SDK or framework version it applies to.

## Adding or changing a question

1. Fork the repository and branch from `main`. Keep each pull request to one topic.
2. Edit or add the question in `questions/<track>/<topic>.md`. The format is described in
   [questions/README.md](questions/README.md) and in the
   [Writing Questions](Sources/InterviewBank/InterviewBank.docc/WritingQuestions.md) article:
    - use the next free ID of the track and never renumber published IDs,
    - give a level (`junior`, `mid` or `senior`),
    - cite at least one primary source with a `**Reference:**` line (not needed in the behavioral
      track),
    - keep answers short enough to say in an interview, and explain trade-offs, not only facts.
3. If the answer contains code that can run without a device, add a test that checks the claim,
   named after the question ID, and link it with `**Verified by:**`:

    | Code             | Test folder                 | Run                                   |
    | ---------------- | --------------------------- | ------------------------------------- |
    | Swift            | `Tests/AnswerTests`         | `swift test`                          |
    | Dart and Flutter | `answers/flutter/test`      | `cd answers/flutter && flutter test`  |
    | JavaScript       | `answers/react-native/test` | `cd answers/react-native && npm test` |

    The test should fail if the answer is wrong, including the edge case the answer warns about.

4. Update the question count of the file in [questions/README.md](questions/README.md), and the
   totals in the README if they change; `swift test` checks both.
5. Run the checks:

    ```sh
    swift run interview lint
    swift test
    ```

    For changes to the example app, also build it:

    ```sh
    cd Examples/InterviewDeck
    xcodebuild build -scheme InterviewDeck -destination 'generic/platform=iOS Simulator'
    ```

6. If the app's screens change, regenerate the screenshots with `scripts/capture-screens.sh`.
7. `README.md` will have translations (`README.<language>.md`), each recording the version of
   `README.md` it follows; CI fails while a translation is behind. If you change `README.md` and
   cannot update the translations, say so in the pull request.

## Code style

- Swift follows the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
  and builds in the Swift 6 language mode without warnings. Document public API with DocC
  comments (`///`).
- Dart passes `dart format` and `flutter analyze`; JavaScript is plain ES modules without
  dependencies.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `ci:`, `chore:`).

## Conduct and security

This project follows the [code of conduct](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)
of all `muhittincamdali` repositories; it lists a private address for reports. Report security
issues privately as described in the [security policy](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md),
not in a public issue.

## License

By contributing you agree that your contributions are licensed under the MIT License.
