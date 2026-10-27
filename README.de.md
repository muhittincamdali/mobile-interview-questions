<!-- i18n-source: README.md@44f564ab04495f1a227681c77f2b694dcbacd7b3 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg" alt="Mobile Interview Questions: Interview questions for iOS, Android, Flutter and React Native, with sourced answers and tested code."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml/badge.svg" alt="CI-Status"></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg" alt="Aktuelle Version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg" alt="Unterstützte Plattformen: iOS 18+ · macOS 15+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg" alt="Sprachversion: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg" alt="Lizenz: MIT"></picture></a>
</p>

<p align="center">
<a href="#schnellstart"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-de-light.svg" alt="Loslegen"></picture></a>
<a href="https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-de-light.svg" alt="Dokumentation"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-de-light.svg" alt="Beispiele"></picture></a>
</p>

> Dies ist eine Übersetzung der englischen README. Bei Abweichungen gilt die englische Fassung.

<!-- brand:end -->
Interviewfragen und -antworten für Mobile-Entwickler: iOS, Android, Flutter, React Native, Mobile-Systemdesign und Verhaltensrunden. Die Fragensammlung umfasst 142 Fragen, jeweils mit dem Level junior, mid oder senior, und jede technische Antwort verlinkt auf die Primärquelle, auf die sie sich stützt: die Dokumentation von Apple, Android, Flutter, Dart, Kotlin und React Native, Swift-Evolution-Vorschläge, MDN oder ein RFC. Bei 51 Antworten gibt es Code, den ein Test in der CI ausführt. Die Aussagen, die sie treffen (ein Actor ist reentrant, `Int(Double.nan)` löst einen Trap aus, ein const-Widget wird nicht neu gebaut, `forEach` wartet nicht), werden also geprüft statt nur wiederholt.

Du kannst die Fragen direkt hier auf GitHub lesen, dich im Terminal mit dem Befehl `interview` abfragen oder mit der App InterviewDeck für iPhone, iPad und Mac lernen.

## Highlights

- **Aktuelle Plattformen** — der Swift-6-Sprachmodus mit standardmäßiger Main-Actor-Isolation und `@concurrent`, der Scene-Lebenszyklus, den mit dem iOS-27-SDK gebaute Apps übernehmen müssen, die Änderungen in Android 16 für große Bildschirme und Predictive Back, Dart-3-Patterns und Extension Types sowie die New Architecture von React Native.
- **Antworten, die du nachprüfen kannst** — jede technische Antwort nennt eine Primärquelle, und der Linter weist eine Antwort ohne Quelle zurück.
- **Getesteter Code** — Swift-Antworten laufen mit Swift Testing auf macOS und in einem iPhone-Simulator, Dart- und Flutter-Antworten mit `flutter test` (einschließlich Widget-Tests) und JavaScript-Antworten mit `node --test`. Jeder Test trägt den Namen der Frage, die er prüft.
- **Ein Lernwerkzeug** — `swift run interview quiz` wählt zufällige Fragen nach Track und Level aus; mit demselben Seed wiederholt sich das Quiz auf jedem Rechner.
- **Ein Format, mit Linter** — die Fragen sind schlichtes Markdown mit fester Struktur, sodass dieselben Dateien GitHub, die Kommandozeile, die App und die Bibliothek [InterviewBank](#die-bibliothek-verwenden) speisen.

### Was drin ist

| Track                                   | Themen                                                                                                                       | Fragen | Mit getestetem Code |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | -----: | ------------------: |
| [iOS](questions/ios)                    | Die Sprache Swift, Speicher, Nebenläufigkeit, SwiftUI, UIKit und der App-Lebenszyklus, Daten und Netzwerk, Tests und Tooling |     58 |                  26 |
| [Android](questions/android)            | Kotlin und Coroutines, das Android-Framework und Jetpack                                                                     |     22 |                   — |
| [Flutter](questions/flutter)            | Die Sprache Dart, das Flutter-Framework                                                                                      |     22 |                  14 |
| [React Native](questions/react-native)  | JavaScript für React Native, React Native                                                                                    |     22 |                  11 |
| [Systemdesign](questions/system-design) | Offline-Synchronisierung, Feeds, Bilder, Chat, Push, OAuth, gestaffelte Rollouts, API-Weiterentwicklung, Retries             |     10 |                   — |
| [Verhalten](questions/behavioral)       | STAR, Incidents, Meinungsverschiedenheiten, technische Schulden, Mentoring                                                   |      8 |                   — |

Die Android-Snippets werden nicht kompiliert: Die CI hat dafür keine Kotlin-Toolchain, daher stützen sich diese Antworten auf die verlinkte Dokumentation. Die vollständige Liste der Themendateien steht in [questions/README.md](questions/README.md).

## Schnellstart

**1. Die Fragen holen**

```sh
git clone https://github.com/muhittincamdali/mobile-interview-questions.git
cd mobile-interview-questions
```

Du brauchst Swift 6.2 oder neuer: Xcode 26 oder neuer auf einem Mac oder eine [Swift-Toolchain](https://www.swift.org/install/) unter Linux. Zum bloßen Lesen der Markdown-Dateien brauchst du gar nichts.

**2. Ein Quiz starten**

```sh
swift run interview quiz --track ios --level senior --count 3
```

Beim ersten Start wird das Tool gebaut. Danach gibt es drei Fragen und den verwendeten Seed aus:

```console
$ swift run interview quiz --track ios --level senior --count 3 --seed 7
Quiz: 3 of 12 questions · seed 7

1. [IOS-021 · senior · Memory management] Is `autoreleasepool` still useful in Swift?
2. [IOS-029 · senior · Swift concurrency] Where does a `nonisolated async` function run, and what do `nonisolated(nonsending)` and `@concurrent` mean?
3. [IOS-047 · senior · UIKit and the app life cycle] How do you run work in the background on iOS?

Answers: interview show <ID>, or repeat with --seed 7 --answers
```

**3. Deine Antwort prüfen**

```sh
swift run interview show IOS-026
```

Das gibt die Antwort, ihre Quellen und den Test aus, der ihren Code prüft ([ConcurrencyTests.swift](Tests/AnswerTests/ConcurrencyTests.swift) für IOS-026). Hängst du `--answers` an ein Quiz mit demselben Seed, werden alle Antworten auf einmal ausgegeben.

## Befehle

| Befehl                                          | Was er macht                                                                   |
| ----------------------------------------------- | ------------------------------------------------------------------------------ |
| `interview list --track flutter --level mid`    | Listet Fragen auf; auch mit `--topic "Swift concurrency"` und `--search actor` |
| `interview show RN-012`                         | Eine Frage mit Antwort, Quellen und Test                                       |
| `interview quiz --count 10 --seed 42 --answers` | Ein wiederholbares Quiz mit 1 bis 50 Fragen                                    |
| `interview stats`                               | Fragen pro Track und Level                                                     |
| `interview lint`                                | Prüft die Fragendateien; Exit-Status 1 bei jedem Problem                       |

Mit `swift run interview --help` siehst du die vollständige Liste. Ungültige Eingaben wie `--count 0`, `--count 1e3` oder ein unbekannter Track werden mit Exit-Status 2 gemeldet, statt abzustürzen.

## Beispiel: eine geprüfte Antwort

Jede Frage ist ein Markdown-Abschnitt mit ID, Level, Antwort und Quellen. Das ist der Anfang von IOS-012 in [questions/ios/swift-language.md](questions/ios/swift-language.md):

```markdown
## IOS-012: How do you convert a `Double` to an `Int` without crashing?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`Int(someDouble)` truncates toward zero, and it **traps** (crashes) when the value is NaN,
infinite or outside `Int`'s range. ...
```

Der verlinkte Test führt jede Umwandlung aus der Antwort aus und schlägt fehl, wenn sich eine anders verhält:

```swift
@Test("IOS-012: Int(exactly:) returns nil where Int(_:) would trap")
func safeNumericConversion() throws {
    #expect(Int(exactly: 42.0) == 42)
    #expect(Int(exactly: 3.5) == nil)
    #expect(Int(exactly: Double.nan) == nil)
    let huge = try #require(Double("1e300"), "read at run time, like a value from JSON")
    #expect(Int(exactly: huge) == nil)
    #expect(Int(3.9) == 3, "Int(_:) truncates toward zero")
    // ...
}
```

Das Schreiben dieser Tests hat Entwürfe korrigiert, bevor sie veröffentlicht wurden: `Int(1e300)` mit einem Literal lässt sich zum Beispiel gar nicht kompilieren, deshalb zeigt die Antwort den Trap jetzt mit einem Wert, der erst zur Laufzeit bekannt ist.

## Die Lern-App

[InterviewDeck](Examples) ist eine SwiftUI-App für iPhone, iPad und Mac, die auf denselben Dateien aufbaut: Du kannst die Sammlung durchblättern und durchsuchen, Antworten mit Code, Tabellen und Quellen lesen und Quizze nach Track und Level starten.

<p align="center">
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-browse-dark.png"><img src="docs/images/deck-browse-light.png" alt="InterviewDeck-Fragenliste: 142 Fragen in sechs Tracks" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-question-dark.png"><img src="docs/images/deck-question-light.png" alt="InterviewDeck zeigt die Frage IOS-026 zur Reentrancy von Actors mit ihrem Codebeispiel" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-quiz-dark.png"><img src="docs/images/deck-quiz-light.png" alt="InterviewDeck-Quizkarte zu einer iOS-Frage auf Senior-Level, die Antwort wird angezeigt" width="260"></picture>
</p>

Öffne `Examples/InterviewDeck/InterviewDeck.xcodeproj` in Xcode 26 oder neuer, wähle das Scheme **InterviewDeck** und einen iPhone-Simulator oder **My Mac** und drücke **Run**. Die Screenshots werden von [`scripts/capture-screens.sh`](scripts/capture-screens.sh) aus der App in einem iOS-27-Simulator aufgenommen.

## Die Bibliothek verwenden

Die Bibliothek `InterviewBank` liest, lintet, filtert und quizzt die Fragendateien aus deinem eigenen Swift-Code. Füge sie mit dem Swift Package Manager hinzu:

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

```swift
import Foundation
import InterviewBank

let bank = try QuestionBank.load(from: URL(fileURLWithPath: "questions"))
let pool = bank.filter(QuestionFilter(track: .flutter, level: .mid))
for question in Quiz.pick(5, from: pool, seed: 2026) {
    print(question.id, question.title)
}
```

Das Lesen ist begrenzt (1 MiB pro Datei, 256 Dateien, 500 Fragen pro Datei), und jedes Formatproblem kommt als `Diagnostic` mit Datei und Zeile zurück statt als Exception.

## Dokumentation

Die [InterviewBank-Dokumentation](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/) behandelt die API und drei Artikel:

- [Getting Started](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/gettingstarted) — die Befehle und das Einbinden der Bibliothek
- [Writing Questions](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/writingquestions) — das Dateiformat, die Lint-Regeln und wie man eine Antwort verifiziert
- [Building a Study App](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/buildingastudyapp) — die Fragen ins Bundle packen und Antworten darstellen

## Voraussetzungen

| Verwendung                 | Benötigt                                                                           |
| -------------------------- | ---------------------------------------------------------------------------------- |
| Die Fragen lesen           | Einen Browser oder einen beliebigen Markdown-Viewer                                |
| Befehl `interview`         | Swift 6.2 oder neuer (Xcode 26+ unter macOS oder eine Swift-Toolchain unter Linux) |
| Bibliothek `InterviewBank` | Swift 6.2+, iOS 18+ oder macOS 15+                                                 |
| App InterviewDeck          | Xcode 26+, iOS 18+ oder macOS 15+                                                  |
| Flutter-Antworttests       | Flutter 3.41 oder neuer (`cd answers/flutter && flutter test`)                     |
| JavaScript-Antworttests    | Node.js 22 oder neuer (`cd answers/react-native && npm test`)                      |

## Mitwirken

Korrekturen und neue Fragen sind willkommen. Lies den [Leitfaden für Beiträge](CONTRIBUTING.md) zu Format, Lint-Regeln und dazu, wie man einen Test für eine Antwort ergänzt, und vor einem Pull Request den [Verhaltenskodex](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). Sicherheitsprobleme meldest du vertraulich, wie in der [Sicherheitsrichtlinie](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md) beschrieben.

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
